import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../jogador/models/jogador_torneio_model.dart';
import '../../partida/models/partida_model.dart';
import '../models/torneio_model.dart';
import '../rules/classificacao_engine.dart';
import '../rules/pokemon_rulebook.dart';
import '../tdf/tom_tdf_codec.dart';

class TomTdfExportacao {
  final String xml;
  final String nomeArquivo;
  final List<String> avisos;
  const TomTdfExportacao(this.xml, this.nomeArquivo, this.avisos);
}

/// Importa novos torneios sem sobrescrever os existentes, preservando os IDs TOM.
/// V1 usa um único batch atômico (máximo de 450 gravações).
class TomTdfService {
  final FirebaseFirestore _db;
  final TomTdfCodec _codec;

  TomTdfService({FirebaseFirestore? firestore, TomTdfCodec? codec})
      : _db = firestore ?? FirebaseFirestore.instance,
        _codec = codec ?? const TomTdfCodec();

  TomTdfDocumento lerArquivo(String xml) => _codec.importar(xml);

  Future<TorneioModel> importar({
    required TomTdfDocumento documento,
    required String administradorUid,
  }) async {
    if (administradorUid.isEmpty) throw StateError('Administrador não identificado.');
    // Garante que todos os dados foram validados inclusive se o objeto foi criado por código.
    _codec.importar(_codec.exportar(documento));
    final inicio = TomTdfCodec.lerData(documento.dados['startdate'] ?? '');
    final temporada = PokemonRulebook.temporadaPorData(inicio) ?? PokemonRulebook.temporadaAtual;
    final tipo = _tipoEvento(documento.atributos['mode']);
    final idsToUid = <String, String>{
      for (final p in documento.jogadores) p.id: 'pop_${p.id}',
    };
    final jogadoresPorId = {for (final p in documento.jogadores) p.id: p};
    final atribuicoes = <String, String>{};
    for (final pod in documento.pods) {
      for (final grupo in pod.subgrupos) {
        for (final id in grupo.jogadores) {
          atribuicoes[id] = pod.idInterno;
        }
      }
    }
    final rodadasPorNumero = <int, List<(TomTdfPod, TomTdfRodada)>>{};
    for (final pod in documento.pods) {
      for (final rodada in pod.rodadas) {
        rodadasPorNumero.putIfAbsent(rodada.numero, () => []).add((pod, rodada));
      }
    }
    final totalGravacoes = 1 + documento.jogadores.length +
        rodadasPorNumero.length + documento.totalPartidas;
    if (totalGravacoes > 450) {
      throw StateError('O torneio exige $totalGravacoes gravações. Esta versão importa '
          'até 450 documentos por operação para garantir atomicidade.');
    }
    final completas = documento.pods.every((pod) => pod.rodadas.every(
      (round) => round.partidas.every((m) =>
          {'1', '2', '3', '10'}.contains(m.outcome))));
    final concluidoTom = documento.dados['status'] == '5' && completas &&
        rodadasPorNumero.isNotEmpty;
    final qtdSwiss = rodadasPorNumero.entries.where((entry) =>
        entry.value.every((par) => par.$2.tipo == '2')).length;
    final maiorRodada = rodadasPorNumero.keys.fold<int>(0, max);
    final referencia = _db.collection('tournaments').doc();
    final codigo = await _gerarCodigo();
    final torneio = TorneioModel(
      id: referencia.id,
      nome: documento.dados['name'] ?? '',
      codigo: codigo,
      dataHora: inicio,
      formato: 'md3', // TDF fornece resultado de match, não placar por jogo.
      quantidadeRodadas: max(1, qtdSwiss),
      rodadaAtual: maiorRodada,
      status: concluidoTom ? 'finalizado' :
          (rodadasPorNumero.isEmpty ? 'inscricoes' : 'em_andamento'),
      criadoPor: administradorUid,
      criadoEm: DateTime.now(),
      sanctionId: documento.dados['id'],
      organizadorNome: documento.dados['organizerName'] ?? '',
      organizadorPlayerId: documento.dados['organizerPopid'],
      tipoEvento: tipo,
      formatoJogo: 'standard', // Não presente no XML de referência.
      sistemaPareamento: 'swiss',
      temporada: temporada,
      agrupamentoEtario: documento.pods.length > 1 ? 'separado' : 'combinado',
      versaoRegras: 'importado-tom-${documento.atributos['version'] ?? 'desconhecida'}',
      topcutConcluido: false,
    );
    final batch = _db.batch();
    batch.set(referencia, {
      ...torneio.toMap(),
      'tomRoot': documento.atributos,
      'tomData': documento.dados,
      'tomTimeElapsed': documento.timeElapsed,
      'tomFinalsOptions': documento.finalsOptions,
      'tomPods': [
        for (final p in documento.pods)
          {
            'id': p.idInterno,
            'category': p.categoria,
            'stage': p.stage,
            'startingTable': p.startingTable,
            'playoffType': p.playoffType,
            'standingsType': p.standingsType,
            'standings': p.classificacao,
            'subgroups': [
              for (final g in p.subgrupos)
                {'number': g.numero, 'players': g.jogadores},
            ],
          },
      ],
      'tomImportSignature': _assinatura(documento),
      'tomImportRosterSignature': _assinaturaIds(documento.jogadores.map((j) => j.id)),
      'tomImportWarnings': documento.avisos,
      'tomImportedAt': Timestamp.now(),
      'tomRoundtripExperimental': true,
    });
    for (var posicaoJogador = 0; posicaoJogador < documento.jogadores.length; posicaoJogador++) {
      final p = documento.jogadores[posicaoJogador];
      String? divisao;
      if (p.nascimento != null) {
        try {
          divisao = PokemonRulebook.divisaoEtaria(p.nascimento!, temporada);
        } on StateError {
          // Não inventar uma divisão para uma temporada não configurada.
        }
      }
      final drop = p.dropStatus != null;
      final jogador = JogadorTorneioModel(
        uid: idsToUid[p.id]!,
        nome: '${p.primeiroNome} ${p.sobrenome}'.trim(),
        email: '',
        status: 'aprovado',
        pontos: 0,
        ativo: !drop,
        entrouEm: DateTime.now(),
        pokemonPlayerId: p.id,
        primeiroNome: p.primeiroNome,
        sobrenome: p.sobrenome,
        dataNascimento: p.nascimento,
        divisaoEtaria: divisao,
        podId: atribuicoes[p.id] ?? 'geral',
        rodadaDesistencia: p.dropRodada,
      );
      batch.set(referencia.collection('players').doc(idsToUid[p.id]), {
        ...jogador.toMap(),
        'tomPosition': posicaoJogador,
        'tomPlayer': {
          'starter': p.starter,
          if (p.criadoEm != null) 'creationdate': p.criadoEm,
          if (p.alteradoEm != null) 'lastmodifieddate': p.alteradoEm,
          if (p.dropStatus != null) 'dropStatus': p.dropStatus,
          if (p.dropTimestamp != null) 'dropTimestamp': p.dropTimestamp,
          'extra': p.outrosCampos,
        },
      });
    }
    for (final numero in rodadasPorNumero.keys.toList()..sort()) {
      final dados = rodadasPorNumero[numero]!;
      final rodadaRef = referencia.collection('rounds').doc('$numero');
      final partidas = dados.expand((item) => item.$2.partidas).toList();
      final finalizada = partidas.every((p) => {'1', '2', '3', '10'}.contains(p.outcome));
      final fase = dados.every((item) => item.$2.tipo == '2') ? 'swiss' : 'topcut';
      batch.set(rodadaRef, {
        'numero': numero,
        'fase': fase,
        'status': finalizada ? 'finalizada' : 'configuracao',
        'criadaEm': Timestamp.now(),
        'tomRoundConfig': {
          for (final item in dados)
            item.$1.idInterno: {'type': item.$2.tipo, 'stage': item.$2.stage},
        },
      });
      for (final item in dados) {
        for (var posicaoPartida = 0; posicaoPartida < item.$2.partidas.length; posicaoPartida++) {
          final partida = item.$2.partidas[posicaoPartida];
          final uid1 = idsToUid[partida.jogador1]!;
          final uid2 = partida.jogador2 == null ? null : idsToUid[partida.jogador2];
          final bye = uid2 == null;
          final resultado = _resultado(partida.outcome, bye);
          final finalizadaPartida = {'1', '2', '3', '10'}.contains(partida.outcome);
          final registro = PartidaModel(
            id: '',
            mesa: partida.mesa,
            jogador1Uid: uid1,
            jogador1Nome: '${jogadoresPorId[partida.jogador1]!.primeiroNome} '
                '${jogadoresPorId[partida.jogador1]!.sobrenome}'.trim(),
            jogador2Uid: uid2,
            jogador2Nome: partida.jogador2 == null ? null :
                '${jogadoresPorId[partida.jogador2]!.primeiroNome} '
                '${jogadoresPorId[partida.jogador2]!.sobrenome}'.trim(),
            status: finalizadaPartida ? 'finalizada' : 'aguardando',
            placarJogador1: resultado == ResultadoPartida.vitoriaJogador1 ? 1 : 0,
            placarJogador2: resultado == ResultadoPartida.vitoriaJogador2 ? 1 : 0,
            bye: bye,
            resultado: resultado,
            fase: fase,
            podId: item.$1.idInterno,
          );
          batch.set(rodadaRef.collection('matches').doc(), {
            ...registro.toMap(),
            'tomOutcomeCode': partida.outcome,
            'tomOriginalResultado': resultado.name,
            'tomPosition': posicaoPartida,
            if (partida.timestamp != null) 'tomTimestamp': partida.timestamp,
            'tomExtra': partida.outrosCampos,
          });
        }
      }
    }
    await batch.commit();
    return torneio;
  }

  Future<TomTdfExportacao> exportar(String torneioId) async {
    final ref = _db.collection('tournaments').doc(torneioId);
    final torneioDoc = await ref.get();
    if (!torneioDoc.exists) throw StateError('Torneio não encontrado.');
    final origem = torneioDoc.data()!;
    final torneio = TorneioModel.fromMap(torneioId, origem);
    final avisos = <String>[];
    final jogadoresDocs = await ref.collection('players')
        .where('status', isEqualTo: 'aprovado').get();
    if (jogadoresDocs.docs.isEmpty) throw StateError('Nenhum jogador aprovado.');
    final jogadoresOrdenados = jogadoresDocs.docs.toList()
      ..sort((a, b) => ((a.data()['tomPosition'] as num?)?.toInt() ?? 999999)
          .compareTo((b.data()['tomPosition'] as num?)?.toInt() ?? 999999));
    final jogadores = <TomTdfJogador>[];
    final uidToPop = <String, String>{};
    final modelos = <JogadorTorneioModel>[];
    for (final doc in jogadoresOrdenados) {
      final j = JogadorTorneioModel.fromMap(doc.id, doc.data());
      final id = j.pokemonPlayerId?.trim() ?? '';
      if (!RegExp(r'^\d{5,12}$').hasMatch(id)) {
        throw StateError('Jogador ${j.nome} sem Player ID oficial válido.');
      }
      if (uidToPop.containsValue(id)) throw StateError('Player ID duplicado: $id.');
      uidToPop[doc.id] = id;
      modelos.add(j);
      final tom = Map<String, dynamic>.from(doc.data()['tomPlayer'] as Map? ?? {});
      if (j.rodadaEntradaTardia != null && tom['starter'] == null) {
        throw StateError('Entrada tardia de ${j.nome} sem representação TOM confirmada.');
      }
      final partes = j.nome.trim().split(RegExp(r'\s+'));
      final primeiro = j.primeiroNome.isEmpty ? partes.first : j.primeiroNome;
      final sobrenome = j.sobrenome.isEmpty ? partes.skip(1).join(' ') : j.sobrenome;
      if (primeiro.isEmpty || sobrenome.isEmpty || j.dataNascimento == null) {
        throw StateError('Dados oficiais incompletos para ${j.nome}.');
      }
      jogadores.add(TomTdfJogador(
        id: id,
        primeiroNome: primeiro,
        sobrenome: sobrenome,
        nascimento: j.dataNascimento,
        starter: (tom['starter'] ?? 'true').toString(),
        criadoEm: tom['creationdate']?.toString() ?? TomTdfCodec.formatarDataHora(j.entrouEm),
        alteradoEm: tom['lastmodifieddate']?.toString() ?? TomTdfCodec.formatarDataHora(j.entrouEm),
        dropStatus: j.ativo ? null : (tom['dropStatus'] ?? '1').toString(),
        dropRodada: j.rodadaDesistencia,
        dropTimestamp: j.ativo ? null : (tom['dropTimestamp']?.toString() ??
            (doc.data()['desistiuEm'] is Timestamp
                ? TomTdfCodec.formatarDataHora((doc.data()['desistiuEm'] as Timestamp).toDate())
                : null)),
        outrosCampos: Map<String, String>.from(tom['extra'] as Map? ?? {}),
      ));
    }
    final temTom = origem['tomRoot'] is Map;
    final attrs = temTom
        ? Map<String, String>.from(origem['tomRoot'] as Map)
        : <String, String>{
            'type': '2', 'stage': '5', 'version': '1.70',
            'gametype': 'TRADING_CARD_GAME', 'mode': _mode(torneio.tipoEvento),
          };
    attrs['gametype'] = 'TRADING_CARD_GAME';
    attrs['mode'] = _mode(torneio.tipoEvento, original: attrs['mode']);
    if (!temTom) {
      avisos.add('Cabeçalho baseado na amostra TOM 1.70; versão e códigos exigem validação no TOM oficial.');
    }
    if (PokemonRulebook.eventoSancionado(torneio.tipoEvento) &&
        ((torneio.sanctionId ?? '').isEmpty ||
         PokemonRulebook.validarIdentificador(torneio.organizadorPlayerId) != null)) {
      throw StateError('Sanction ID e Player ID do organizador são obrigatórios.');
    }
    final dados = origem['tomData'] is Map
        ? Map<String, String>.from(origem['tomData'] as Map)
        : <String, String>{};
    dados.addAll({
      'name': torneio.nome,
      'id': torneio.sanctionId ?? '',
      'organizerName': torneio.organizadorNome,
      'organizerPopid': torneio.organizadorPlayerId ?? '',
      'startdate': TomTdfCodec.formatarData(torneio.dataHora),
      'status': torneio.status == 'finalizado' ? '5' : (dados['status'] == '5' ? '0' : dados['status'] ?? '0'),
    });
    dados.putIfAbsent('city', () => '');
    dados.putIfAbsent('state', () => '');
    dados.putIfAbsent('country', () => 'Brazil');
    dados.putIfAbsent('roundtime', () => '50');
    dados.putIfAbsent('finalsroundtime', () => '60');
    dados.putIfAbsent('lessswiss', () => 'false');
    dados.putIfAbsent('autotimestamp', () => 'true');
    if (torneio.status != 'finalizado') {
      avisos.add('Torneio não finalizado. Este arquivo não deve ser enviado ao Play! Tools.');
    }
    if (dados['city']!.isEmpty || dados['state']!.isEmpty) {
      avisos.add('Cidade e estado não informados. Complete os metadados para uso oficial.');
    }

    final avisosImportacao = origem['tomImportWarnings'];
    if (avisosImportacao is List && avisosImportacao.isNotEmpty) {
      avisos.add('O arquivo importado possuía campos não mapeados: confira avisos anteriores.');
    }
    final metadadosPods = origem['tomPods'] is List
        ? (origem['tomPods'] as List).map((p) => Map<String, dynamic>.from(p as Map)).toList()
        : <Map<String, dynamic>>[];
    final pods = <String, List<JogadorTorneioModel>>{};
    for (final j in modelos) {
      final id = j.podId != 'geral' ? j.podId :
          (torneio.agrupamentoEtario == 'separado'
              ? (j.divisaoEtaria ?? 'geral') : 'geral');
      pods.putIfAbsent(id, () => []).add(j);
    }
    final rodadasDocs = await ref.collection('rounds').get();
    final rodadasInfo = <int, Map<String, dynamic>>{};
    final partidasPorPod = <String, Map<int, List<(PartidaModel, Map<String, dynamic>)>>>{};
    final classificacaoPartidas = <PartidaModel>[];
    final assinaturaList = <String>[];
    for (final rd in rodadasDocs.docs) {
      final numero = (rd.data()['numero'] as num?)?.toInt() ?? int.tryParse(rd.id) ?? 0;
      if (numero < 1) continue;
      rodadasInfo[numero] = rd.data();
      final partidasSnap = await rd.reference.collection('matches').get();
      for (final partidaDoc in partidasSnap.docs) {
        final raw = partidaDoc.data();
        final partida = PartidaModel.fromMap(partidaDoc.id, raw);
        final pop1 = uidToPop[partida.jogador1Uid];
        final pop2 = partida.jogador2Uid == null ? null : uidToPop[partida.jogador2Uid];
        if (pop1 == null || (partida.jogador2Uid != null && pop2 == null)) {
          throw StateError('Rodada $numero: partida com jogador sem inscrição aprovada.');
        }
        final grupo = partida.podId != 'geral' ? partida.podId :
            (pods.keys.length == 1 ? pods.keys.first : 'geral');
        if (!pods.containsKey(grupo)) {
          throw StateError('Pod da partida não corresponde aos jogadores: $grupo.');
        }
        // Preserve o código de TOM original enquanto o resultado não foi alterado.
        final resultadoAtual = partida.resultado.name;
        final original = raw['tomOutcomeCode']?.toString();
        final originalResultado = raw['tomOriginalResultado']?.toString();
        final codigo = (original != null && originalResultado == resultadoAtual)
            ? original : _outcomeExportavel(partida);
        assinaturaList.add('$grupo|$numero|$pop1|${pop2 ?? ''}|$codigo|${partida.mesa}');
        partidasPorPod.putIfAbsent(grupo, () => {}).putIfAbsent(numero, () => [])
            .add((partida, {...raw, '_codigoExportacao': codigo}));
        classificacaoPartidas.add(partida);
      }
    }
    final assinatura = (assinaturaList..sort()).join(';');
    final importAssinatura = origem['tomImportSignature'] as String?;
    final inalterado = importAssinatura != null && importAssinatura == assinatura &&
        origem['tomImportRosterSignature'] == _assinaturaIds(uidToPop.values);
    if (importAssinatura != null && !inalterado) {
      avisos.add('Confrontos alterados após importação: classificação recalculada.');
    }
    final rankingGeral = const ClassificacaoEngine().calcular(
      jogadores: modelos, partidas: classificacaoPartidas, torneioId: torneioId,
    );
    final tdfPods = <TomTdfPod>[];
    final ordenados = pods.entries.toList()
      ..sort((a, b) {
        final ixA = metadadosPods.indexWhere((p) => p['id'] == a.key);
        final ixB = metadadosPods.indexWhere((p) => p['id'] == b.key);
        return (ixA < 0 ? 999999 : ixA).compareTo(ixB < 0 ? 999999 : ixB);
      });
    for (final entry in ordenados) {
      final id = entry.key;
      final meta = metadadosPods.where((p) => p['id'] == id).firstOrNull;
      final cat = meta?['category']?.toString() ?? _categoria(entry.value.first.divisaoEtaria);
      final subgrupos = <TomTdfSubgrupo>[];
      final grupoMeta = meta?['subgroups'];
      if (grupoMeta is List && inalterado) {
        for (final raw in grupoMeta) {
          final d = Map<String, dynamic>.from(raw as Map);
          final original = (d['players'] as List?)?.map((e) => e.toString()).toList() ?? [];
          if (original.every((pop) => uidToPop.containsValue(pop))) {
            subgrupos.add(TomTdfSubgrupo(d['number']?.toString() ?? '1', original));
          }
        }
      }
      if (subgrupos.isEmpty || subgrupos.expand((g) => g.jogadores).toSet().length != entry.value.length) {
        subgrupos.clear();
        subgrupos.add(TomTdfSubgrupo('1', [for (final j in entry.value) uidToPop[j.uid]!]));
      }
      final rodadaPod = <TomTdfRodada>[];
      final porRodada = partidasPorPod[id] ?? {};
      for (final num in porRodada.keys.toList()..sort()) {
        final info = rodadasInfo[num] ?? {};
        final roundConfig = info['tomRoundConfig'] as Map?;
        final config = roundConfig?[id] as Map?;
        final fase = info['fase']?.toString() ?? (num > torneio.quantidadeRodadas ? 'topcut' : 'swiss');
        if (fase == 'topcut' && config == null) {
          throw StateError('Fase Top Cut sem código TOM confirmado para exportação. '
              'Importe uma referência TOM contendo Top Cut primeiro.');
        }
        final pares = porRodada[num]!..sort((a, b) {
          final ordemA = (a.$2['tomPosition'] as num?)?.toInt();
          final ordemB = (b.$2['tomPosition'] as num?)?.toInt();
          if (ordemA != null && ordemB != null) return ordemA.compareTo(ordemB);
          return a.$1.mesa.compareTo(b.$1.mesa);
        });
        rodadaPod.add(TomTdfRodada(
          numero: num,
          tipo: config?['type']?.toString() ?? '2',
          stage: config?['stage']?.toString() ?? (meta?['stage']?.toString() ?? '5'),
          partidas: [for (final par in pares)
            TomTdfPartida(
              outcome: par.$2['_codigoExportacao'] as String,
              jogador1: uidToPop[par.$1.jogador1Uid]!,
              jogador2: par.$1.jogador2Uid == null ? null : uidToPop[par.$1.jogador2Uid],
              mesa: par.$1.mesa,
              timestamp: par.$2['tomTimestamp']?.toString() ??
                  (par.$2['concluidaEm'] is Timestamp
                      ? TomTdfCodec.formatarDataHora((par.$2['concluidaEm'] as Timestamp).toDate())
                      : null),
              outrosCampos: Map<String, String>.from(par.$2['tomExtra'] as Map? ?? {}),
            ),
          ],
        ));
      }
      final classificacao = <String, int>{};
      if (inalterado && meta?['standings'] is Map) {
        for (final e in (meta!['standings'] as Map).entries) {
          classificacao[e.key.toString()] = (e.value as num).toInt();
        }
      } else {
        var lugar = 1;
        for (final linha in rankingGeral.where((r) =>
            entry.value.any((j) => j.uid == r.uid))) {
          classificacao[uidToPop[linha.uid]!] = lugar++;
        }
      }
      tdfPods.add(TomTdfPod(
        idInterno: id,
        categoria: cat,
        stage: meta?['stage']?.toString() ?? '5',
        startingTable: meta?['startingTable']?.toString() ?? '1',
        playoffType: meta?['playoffType']?.toString() ?? '0',
        subgrupos: subgrupos,
        rodadas: rodadaPod,
        classificacao: classificacao,
        standingsType: meta?['standingsType']?.toString() ??
            (torneio.status == 'finalizado' ? 'finished' : 'ongoing'),
      ));
    }
    if (tdfPods.every((p) => p.rodadas.isEmpty)) {
      throw StateError('Torneio sem partidas para exportar.');
    }
    if (torneio.status == 'finalizado' && tdfPods.any((p) => p.rodadas.any(
        (r) => r.partidas.any((m) => m.outcome == '0')))) {
      throw StateError('Torneio marcado como finalizado possui resultados pendentes.');
    }
    if (jogadores.any((p) => p.dropStatus != null && p.dropTimestamp == null)) {
      avisos.add('Há desistências sem horário registrado; o TDF omitirá o timestamp correspondente.');
    }
    if (tdfPods.any((pod) => pod.rodadas.any((r) =>
        r.partidas.any((m) => m.timestamp == null && m.outcome != '0')))) {
      avisos.add('Existem partidas sem horário de conclusão; timestamp não foi inventado.');
    }
    final doc = TomTdfDocumento(
      atributos: attrs,
      dados: dados,
      jogadores: jogadores,
      pods: tdfPods,
      timeElapsed: origem['tomTimeElapsed']?.toString() ?? '0',
      finalsOptions: Map<String, String>.from(origem['tomFinalsOptions'] as Map? ?? {}),
    );
    final xml = _codec.exportar(doc);
    // Autovalidação: parse e checagem de referências do arquivo produzido.
    _codec.importar(xml);
    final nome = torneio.nome.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    avisos.add('XML compatível estruturalmente com a amostra TOM 1.70. '
        'Abertura no TOM e aceitação pelo Play! Tools não estão homologadas.');
    return TomTdfExportacao(xml, '${nome.isEmpty ? 'torneio' : nome}.tdf', avisos);
  }

  static ResultadoPartida _resultado(String outcome, bool bye) {
    if (bye) return ResultadoPartida.bye;
    switch (outcome) {
      case '1': return ResultadoPartida.vitoriaJogador1;
      case '2': return ResultadoPartida.vitoriaJogador2;
      case '3': return ResultadoPartida.empate;
      case '10': return ResultadoPartida.derrotaDupla;
      default: return ResultadoPartida.pendente;
    }
  }

  static String _outcomeExportavel(PartidaModel p) {
    switch (p.resultado) {
      case ResultadoPartida.pendente: return '0';
      case ResultadoPartida.vitoriaJogador1: return '1';
      case ResultadoPartida.vitoriaJogador2: return '2';
      case ResultadoPartida.empate: return '3';
      case ResultadoPartida.derrotaDupla: return '10';
      case ResultadoPartida.bye:
      case ResultadoPartida.woJogador1:
      case ResultadoPartida.woJogador2:
      case ResultadoPartida.derrotaAutomatica:
        throw StateError('Resultado ${p.resultado.name} da mesa ${p.mesa}: '
            'código TOM não confirmado na amostra. Não é seguro inventá-lo.');
    }
  }

  static String _assinaturaIds(Iterable<String> ids) {
    final ordenados = ids.toList()..sort();
    return ordenados.join(';');
  }

  static String _assinatura(TomTdfDocumento documento) {
    final linhas = <String>[];
    for (final pod in documento.pods) {
      for (final rodada in pod.rodadas) {
        for (final partida in rodada.partidas) {
          linhas.add('${pod.idInterno}|${rodada.numero}|${partida.jogador1}|'
              '${partida.jogador2 ?? ''}|${partida.outcome}|${partida.mesa}');
        }
      }
    }
    linhas.sort();
    return linhas.join(';');
  }

  static String _tipoEvento(String? mode) {
    switch (mode) {
      case 'LEAGUECHALLENGE': return 'league_challenge';
      case 'LEAGUECUP': return 'league_cup';
      default: return 'custom';
    }
  }

  static String _mode(String tipo, {String? original}) {
    if (original != null && original.isNotEmpty) return original;
    switch (tipo) {
      case 'league_challenge': return 'LEAGUECHALLENGE';
      case 'league_cup': return 'LEAGUECUP';
      default: return 'CUSTOM';
    }
  }

  static String _categoria(String? divisao) {
    switch (divisao) {
      case 'junior': return '0';
      case 'senior': return '1';
      default: return '2';
    }
  }

  Future<String> _gerarCodigo() async {
    final random = Random.secure();
    for (var i = 0; i < 100; i++) {
      final codigo = 'TCG${random.nextInt(9000) + 1000}';
      final existente = await _db.collection('tournaments')
          .where('codigo', isEqualTo: codigo).limit(1).get();
      if (existente.docs.isEmpty) return codigo;
    }
    throw StateError('Não foi possível gerar código de convite para o torneio.');
  }
}
