import 'package:cloud_firestore/cloud_firestore.dart';

import '../../jogador/models/jogador_torneio_model.dart';
import '../../torneio/models/classificacao_jogador_model.dart';

import '../models/partida_model.dart';
import '../../torneio/models/torneio_model.dart';
import '../../torneio/rules/pokemon_rulebook.dart';
import '../../torneio/rules/classificacao_engine.dart';
import '../../torneio/rules/pareamento_swiss_engine.dart';

class RodadaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> iniciarTorneio({required String torneioId}) async {
    final torneioRef = _firestore.collection('tournaments').doc(torneioId);

    final jogadoresSnapshot = await torneioRef
        .collection('players')
        .where('status', isEqualTo: 'aprovado')
        .where('ativo', isEqualTo: true)
        .get();

    final torneioSnapshot = await torneioRef.get();
    if (!torneioSnapshot.exists) return 'torneio_nao_encontrado';
    final torneio = TorneioModel.fromMap(torneioId, torneioSnapshot.data()!);
    if (torneio.status != 'inscricoes') return 'status_invalido';
    if (torneio.sistemaPareamento != 'swiss') return 'formato_nao_implementado';
    final oficial = PokemonRulebook.eventoSancionado(torneio.tipoEvento);
    if (jogadoresSnapshot.docs.length < (oficial ? 4 : 2)) {
      return 'jogadores_insuficientes';
    }
    if (oficial && torneio.quantidadeRodadas < 2) return 'rodadas_insuficientes';
    if (oficial && (torneio.sanctionId == null || torneio.sanctionId!.isEmpty ||
        PokemonRulebook.validarIdentificador(torneio.organizadorPlayerId) != null)) {
      return 'metadados_pendentes';
    }
    if (oficial && jogadoresSnapshot.docs.any((doc) =>
        !JogadorTorneioModel.fromMap(doc.id, doc.data()).possuiDadosOficiais)) {
      return 'jogadores_sem_dados_oficiais';
    }
    if (oficial) {
      final playerIds = <String>{};
      for (final doc in jogadoresSnapshot.docs) {
        final jogador = JogadorTorneioModel.fromMap(doc.id, doc.data());
        if (!playerIds.add(jogador.pokemonPlayerId!.trim())) {
          return 'player_id_duplicado';
        }
        if (PokemonRulebook.divisaoEtaria(
              jogador.dataNascimento!, torneio.temporada) != jogador.divisaoEtaria) {
          return 'divisao_etaria_inconsistente';
        }
      }
    }

    final rodadaRef = torneioRef.collection('rounds').doc('1');
    return _firestore.runTransaction<String>((tx) async {
      final t = await tx.get(torneioRef);
      final r = await tx.get(rodadaRef);
      if (t.data()?['status'] != 'inscricoes' || r.exists) return 'status_invalido';
      tx.update(torneioRef, {'status': 'em_andamento', 'rodadaAtual': 1});
      tx.set(rodadaRef, {
        'numero': 1, 'fase': 'swiss', 'status': 'configuracao',
        'criadaEm': Timestamp.now(),
      });
      return 'ok';
    });
  }

  Future<List<JogadorTorneioModel>> listarJogadoresAprovados(
    String torneioId,
  ) async {
    final snapshot = await _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('players')
        .where('status', isEqualTo: 'aprovado')
        .where('ativo', isEqualTo: true)
        .get();

    final jogadores = snapshot.docs
        .map((doc) => JogadorTorneioModel.fromMap(doc.id, doc.data()))
        .toList();

    jogadores.sort((a, b) => a.nome.compareTo(b.nome));

    return jogadores;
  }

  Future<void> salvarPrimeiraRodada({
    required String torneioId,
    required List<PartidaModel> partidas,
  }) async {
    final rodadaRef = _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('rounds')
        .doc('1');

    if ((await rodadaRef.get()).data()?['status'] != 'configuracao') {
      throw StateError('A rodada já foi iniciada ou encerrada.');
    }
    final jogadores = await listarJogadoresAprovados(torneioId);
    final ids = jogadores.map((j) => j.uid).toSet();
    final usados = <String>{};
    var byes = 0;
    for (final partida in partidas) {
      if (!ids.contains(partida.jogador1Uid) || !usados.add(partida.jogador1Uid)) {
        throw StateError('Jogador duplicado ou inválido na primeira rodada.');
      }
      if (partida.bye) {
        byes++;
      } else {
        if (partida.jogador2Uid == null ||
            !ids.contains(partida.jogador2Uid) ||
            !usados.add(partida.jogador2Uid!)) {
          throw StateError('Confronto inválido na primeira rodada.');
        }
      }
    }
    final torneioDoc = await _firestore.collection('tournaments').doc(torneioId).get();
    if (!torneioDoc.exists) throw StateError('Torneio não encontrado.');
    final torneio = TorneioModel.fromMap(torneioId, torneioDoc.data()!);
    final grupos = <String, List<String>>{};
    for (final jogador in jogadores) {
      final pod = jogador.podId != 'geral' ? jogador.podId :
          (torneio.agrupamentoEtario == 'separado' ?
              (jogador.divisaoEtaria ?? 'nao_informada') : 'geral');
      grupos.putIfAbsent(pod, () => []).add(jogador.uid);
    }
    final porId = {for (final jogador in jogadores) jogador.uid: jogador};
    final byesPorGrupo = <String, int>{};
    for (final partida in partidas) {
      final a = porId[partida.jogador1Uid]!;
      final grupoA = a.podId != 'geral' ? a.podId :
          (torneio.agrupamentoEtario == 'separado' ?
              (a.divisaoEtaria ?? 'nao_informada') : 'geral');
      if (partida.bye) {
        byesPorGrupo[grupoA] = (byesPorGrupo[grupoA] ?? 0) + 1;
      } else {
        final b = porId[partida.jogador2Uid!]!;
        final grupoB = b.podId != 'geral' ? b.podId :
            (torneio.agrupamentoEtario == 'separado' ?
                (b.divisaoEtaria ?? 'nao_informada') : 'geral');
        if (grupoA != grupoB) {
          throw StateError('Jogadores de pods diferentes no mesmo confronto.');
        }
      }
    }
    final byesEsperados = grupos.entries.where((g) => g.value.length.isOdd).length;
    if (usados.length != ids.length || byes != byesEsperados ||
        grupos.entries.any((g) =>
            (byesPorGrupo[g.key] ?? 0) != (g.value.length.isOdd ? 1 : 0))) {
      throw StateError('Distribuição de confrontos/bye inválida por pod.');
    }
    final partidasAtuais = await rodadaRef.collection('matches').get();

    final batch = _firestore.batch();

    for (final doc in partidasAtuais.docs) {
      batch.delete(doc.reference);
    }

    for (final partida in partidas) {
      final partidaRef = rodadaRef.collection('matches').doc();

      batch.set(
        partidaRef,
        PartidaModel(
          id: partidaRef.id,
          mesa: partida.mesa,
          jogador1Uid: partida.jogador1Uid,
          jogador1Nome: partida.jogador1Nome,
          jogador2Uid: partida.jogador2Uid,
          jogador2Nome: partida.jogador2Nome,
          status: 'aguardando',
          placarJogador1: 0,
          placarJogador2: 0,
          resultadoInformadoPor: null,
          bye: partida.bye,
          fase: partida.fase,
          podId: partida.podId,
        ).toMap(),
      );
    }

    batch.update(rodadaRef, {'status': 'configuracao'});

    await batch.commit();
  }

  Stream<String?> observarStatusRodada({
    required String torneioId,
    required int rodada,
  }) {
    return _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('rounds')
        .doc(rodada.toString())
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return null;
          }

          return doc.data()?['status'];
        });
  }

  Future<String> iniciarRodada({
    required String torneioId,
    required int rodada,
  }) async {
    final rodadaRef = _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('rounds')
        .doc(rodada.toString());

    final rodadaSnapshot = await rodadaRef.get();

    if (!rodadaSnapshot.exists) {
      return 'rodada_nao_encontrada';
    }

    final dadosRodada = rodadaSnapshot.data();

    final status = dadosRodada?['status'];

    if (status == 'em_andamento') {
      return 'rodada_ja_iniciada';
    }

    if (status == 'finalizada') {
      return 'rodada_finalizada';
    }

    if (status != 'configuracao') {
      return 'status_invalido';
    }

    final partidasSnapshot = await rodadaRef.collection('matches').get();

    if (partidasSnapshot.docs.isEmpty) {
      return 'nenhuma_partida';
    }

    final batch = _firestore.batch();

    for (final doc in partidasSnapshot.docs) {
      final dados = doc.data();

      final bool bye = dados['bye'] ?? false;
      final bool derrotaAutomatica = dados['resultado'] == 'derrotaAutomatica';

      batch.update(doc.reference, {
        'status': bye || derrotaAutomatica ? 'finalizada' : 'em_andamento',
        'placarJogador1': 0,
        'placarJogador2': 0,
        'resultadoInformadoPor': null,
      });
    }

    batch.update(rodadaRef, {
      'status': 'em_andamento',
      'iniciadaEm': Timestamp.now(),
    });

    await batch.commit();

    return 'ok';
  }

  Future<String> encerrarRodada({
    required String torneioId,
    required int rodada,
  }) async {
    final torneioRef = _firestore.collection('tournaments').doc(torneioId);

    final rodadaRef = torneioRef.collection('rounds').doc(rodada.toString());

    final partidasSnapshot = await rodadaRef.collection('matches').get();

    if (partidasSnapshot.docs.isEmpty) {
      return 'nenhuma_partida';
    }

    final partidasRefs = partidasSnapshot.docs
        .map((doc) => doc.reference)
        .toList();

    return _firestore.runTransaction<String>((transaction) async {
      // 1. Ler a rodada
      final rodadaSnapshot = await transaction.get(rodadaRef);

      if (!rodadaSnapshot.exists) {
        return 'rodada_nao_encontrada';
      }

      final dadosRodada = rodadaSnapshot.data();

      if (dadosRodada?['status'] == 'finalizada') {
        return 'rodada_finalizada';
      }
      if (dadosRodada?['status'] != 'em_andamento') {
        return 'rodada_nao_iniciada';
      }

      // 2. Ler todas as partidas
      final List<PartidaModel> partidas = [];

      for (final partidaRef in partidasRefs) {
        final partidaSnapshot = await transaction.get(partidaRef);

        if (!partidaSnapshot.exists) {
          continue;
        }

        final dados = partidaSnapshot.data();

        if (dados == null) {
          continue;
        }

        partidas.add(PartidaModel.fromMap(partidaSnapshot.id, dados));
      }

      if (partidas.isEmpty) {
        return 'nenhuma_partida';
      }

      // 3. Validar se todas as partidas foram finalizadas
      final possuiPartidaPendente = partidas.any(
        (partida) => partida.status != 'finalizada',
      );

      if (possuiPartidaPendente) {
        return 'partida_pendente';
      }

      final faseTopCut = dadosRodada?['fase'] == 'topcut';
      // Em Top Cut, todas as partidas devem produzir exatamente um vencedor.
      if (faseTopCut && partidas.any((p) =>
          p.resultado != ResultadoPartida.vitoriaJogador1 &&
          p.resultado != ResultadoPartida.vitoriaJogador2 &&
          p.resultado != ResultadoPartida.woJogador1 &&
          p.resultado != ResultadoPartida.woJogador2)) {
        return 'resultado_topcut_invalido';
      }
      // 4. Pontos da rodada. Resultado explícito diferencia W.O. e derrota dupla.
      final Map<String, int> pontosPorJogador = {};
      final Set<String> jogadoresComBye = {};
      for (final partida in partidas) {
        if (!partida.resultadoConcluido) return 'resultado_invalido';
        final uid1 = partida.jogador1Uid;
        final uid2 = partida.jogador2Uid;
        pontosPorJogador.putIfAbsent(uid1, () => 0);
        if (uid2 != null) pontosPorJogador.putIfAbsent(uid2, () => 0);
        switch (partida.resultado) {
          case ResultadoPartida.bye:
            pontosPorJogador[uid1] = pontosPorJogador[uid1]! + 3;
            jogadoresComBye.add(uid1);
            break;
          case ResultadoPartida.vitoriaJogador1:
          case ResultadoPartida.woJogador2:
            pontosPorJogador[uid1] = pontosPorJogador[uid1]! + 3;
            break;
          case ResultadoPartida.vitoriaJogador2:
          case ResultadoPartida.woJogador1:
            if (uid2 == null) return 'resultado_invalido';
            pontosPorJogador[uid2] = pontosPorJogador[uid2]! + 3;
            break;
          case ResultadoPartida.empate:
            if (uid2 == null) return 'resultado_invalido';
            pontosPorJogador[uid1] = pontosPorJogador[uid1]! + 1;
            pontosPorJogador[uid2] = pontosPorJogador[uid2]! + 1;
            break;
          case ResultadoPartida.derrotaDupla:
          case ResultadoPartida.derrotaAutomatica:
            break;
          case ResultadoPartida.pendente:
            return 'resultado_invalido';
        }
      }

      // 5. Preparar as referências dos jogadores
      final jogadoresRefs = <String, DocumentReference<Map<String, dynamic>>>{};

      for (final uid in pontosPorJogador.keys) {
        jogadoresRefs[uid] = torneioRef.collection('players').doc(uid);
      }

      // 6. Ler todos os jogadores ANTES de iniciar as escritas
      final jogadoresSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};

      for (final entry in jogadoresRefs.entries) {
        jogadoresSnapshots[entry.key] = await transaction.get(entry.value);
      }

      // 7. Atualizar os pontos e a quantidade de BYEs
      // Neste ponto, todas as leituras já foram realizadas.
      for (final entry in pontosPorJogador.entries) {
        if (faseTopCut) break; // Swiss congela os pontos após o Top Cut.
        final jogadorRef = jogadoresRefs[entry.key]!;
        final jogadorSnapshot = jogadoresSnapshots[entry.key]!;

        if (!jogadorSnapshot.exists) {
          continue;
        }

        final dadosJogador = jogadorSnapshot.data()!;

        final pontosAtuais = dadosJogador['pontos'] ?? 0;
        final quantidadeByesAtual = dadosJogador['quantidadeByes'] ?? 0;

        transaction.update(jogadorRef, {
          'pontos': pontosAtuais + entry.value,
          if (jogadoresComBye.contains(entry.key))
            'quantidadeByes': quantidadeByesAtual + 1,
        });
      }

      // Marcar Top Cut concluído quando restar uma final por pod.
      if (faseTopCut) {
        final porPod = <String, int>{};
        for (final partida in partidas) {
          porPod[partida.podId] = (porPod[partida.podId] ?? 0) + 1;
        }
        if (porPod.isNotEmpty && porPod.values.every((q) => q == 1)) {
          transaction.update(torneioRef, {'topcutConcluido': true});
        }
      }
      // 8. Finalizar a rodada
      transaction.update(rodadaRef, {
        'status': 'finalizada',
        'finalizadaEm': Timestamp.now(),
      });

      return 'ok';
    });
  }

  Future<List<ClassificacaoJogadorModel>> buscarClassificacao({
    required String torneioId,
  }) async {
    final torneioRef = _firestore.collection('tournaments').doc(torneioId);
    final torneioSnapshot = await torneioRef.get();
    if (!torneioSnapshot.exists) return [];
    final rodadaAtual = (torneioSnapshot.data()?['rodadaAtual'] as num?)?.toInt() ?? 0;
    final jogadoresSnapshot = await torneioRef.collection('players')
        .where('status', isEqualTo: 'aprovado').get();
    final jogadores = jogadoresSnapshot.docs
        .map((doc) => JogadorTorneioModel.fromMap(doc.id, doc.data())).toList();
    final partidas = <PartidaModel>[];
    for (var numero = 1; numero <= rodadaAtual; numero++) {
      final rodadaRef = torneioRef.collection('rounds').doc('$numero');
      final rodada = await rodadaRef.get();
      if (rodada.data()?['status'] != 'finalizada') continue;
      final snapshot = await rodadaRef.collection('matches').get();
      partidas.addAll(snapshot.docs.map((doc) => PartidaModel.fromMap(doc.id, doc.data())));
    }
    return const ClassificacaoEngine().calcular(
      jogadores: jogadores, partidas: partidas, torneioId: torneioId);
  }

  Future<Map<String, Set<String>>> _buscarHistoricoConfrontos({
    required String torneioId,
    required int rodadaAtual,
  }) async {
    final Map<String, Set<String>> historico = {};

    final torneioRef = _firestore.collection('tournaments').doc(torneioId);

    for (int numeroRodada = 1; numeroRodada <= rodadaAtual; numeroRodada++) {
      final partidasSnapshot = await torneioRef
          .collection('rounds')
          .doc(numeroRodada.toString())
          .collection('matches')
          .get();

      for (final doc in partidasSnapshot.docs) {
        final partida = PartidaModel.fromMap(doc.id, doc.data());

        if (partida.bye || partida.jogador2Uid == null) {
          continue;
        }

        historico
            .putIfAbsent(partida.jogador1Uid, () => <String>{})
            .add(partida.jogador2Uid!);

        historico
            .putIfAbsent(partida.jogador2Uid!, () => <String>{})
            .add(partida.jogador1Uid);
      }
    }

    return historico;
  }

  Future<String> gerarProximaRodada({
    required String torneioId,
    required int rodadaAtual,
  }) async {
    final torneioRef = _firestore.collection('tournaments').doc(torneioId);
    final torneioSnapshot = await torneioRef.get();
    if (!torneioSnapshot.exists) return 'torneio_nao_encontrado';
    final torneio = TorneioModel.fromMap(torneioId, torneioSnapshot.data()!);
    if (torneio.status != 'em_andamento' || torneio.rodadaAtual != rodadaAtual) {
      return 'status_invalido';
    }
    if (rodadaAtual >= torneio.quantidadeRodadas) return 'ultima_rodada';
    final atualRef = torneioRef.collection('rounds').doc('$rodadaAtual');
    if ((await atualRef.get()).data()?['status'] != 'finalizada') {
      return 'rodada_nao_finalizada';
    }
    final proxima = rodadaAtual + 1;
    final proximaRef = torneioRef.collection('rounds').doc('$proxima');
    if ((await proximaRef.get()).exists) return 'rodada_ja_existe';
    final classificacao = await buscarClassificacao(torneioId: torneioId);
    final ativos = classificacao.where((j) => j.ativo).toList();
    if (ativos.length < 2) return 'jogadores_insuficientes';
    final snapshotInscritos = await torneioRef.collection('players')
        .where('status', isEqualTo: 'aprovado').get();
    final inscritos = snapshotInscritos.docs.map((doc) =>
        JogadorTorneioModel.fromMap(doc.id, doc.data())).toList();
    final entradasTardias = inscritos.where((j) =>
        j.ativo && j.rodadaEntradaTardia == proxima).toList();
    final idsAtrasados = entradasTardias.map((j) => j.uid).toSet();
    final elegiveis = ativos.where((j) => !idsAtrasados.contains(j.uid)).toList();
    final historico = await _buscarHistoricoConfrontos(
      torneioId: torneioId, rodadaAtual: rodadaAtual);
    List<ConfrontoSwiss> confrontos;
    try {
      confrontos = const PareamentoSwissEngine().gerar(
        classificacao: elegiveis,
        historico: historico,
        rodada: proxima,
        torneioId: torneioId,
        separarDivisoes: torneio.agrupamentoEtario == 'separado',
      );
    } on StateError {
      return 'sem_pareamento_valido';
    }
    final porUid = {for (final j in ativos) j.uid: j};
    final batch = _firestore.batch();
    batch.set(proximaRef, {
      'numero': proxima, 'fase': 'swiss', 'status': 'configuracao',
      'criadaEm': Timestamp.now(),
    });
    for (var i = 0; i < confrontos.length; i++) {
      final confronto = confrontos[i];
      final jogador1 = porUid[confronto.jogador1Uid]!;
      final jogador2 = confronto.jogador2Uid == null ? null : porUid[confronto.jogador2Uid];
      final partidaRef = proximaRef.collection('matches').doc();
      batch.set(partidaRef, PartidaModel(
        id: partidaRef.id,
        mesa: confronto.bye ? 0 : i + 1,
        jogador1Uid: jogador1.uid,
        jogador1Nome: jogador1.nome,
        jogador2Uid: jogador2?.uid,
        jogador2Nome: jogador2?.nome,
        status: 'aguardando',
        placarJogador1: 0,
        placarJogador2: 0,
        bye: confronto.bye,
        podId: confronto.podId,
      ).toMap());
    }
    for (final jogador in entradasTardias) {
      final partidaRef = proximaRef.collection('matches').doc();
      batch.set(partidaRef, PartidaModel(
        id: partidaRef.id, mesa: 0,
        jogador1Uid: jogador.uid, jogador1Nome: jogador.nome,
        status: 'finalizada', placarJogador1: 0, placarJogador2: 0,
        bye: false, resultado: ResultadoPartida.derrotaAutomatica,
      ).toMap());
    }
    batch.update(torneioRef, {'rodadaAtual': proxima});
    await batch.commit();
    return 'ok';
  }

  /// Geração opcional da primeira rodada com o mesmo motor Swiss.
  Future<String> gerarPrimeiraRodadaAutomatica({required String torneioId}) async {
    final torneioRef = _firestore.collection('tournaments').doc(torneioId);
    final torneioSnapshot = await torneioRef.get();
    if (!torneioSnapshot.exists) return 'torneio_nao_encontrado';
    final torneio = TorneioModel.fromMap(torneioId, torneioSnapshot.data()!);
    if (torneio.status != 'em_andamento' || torneio.rodadaAtual != 1) {
      return 'status_invalido';
    }
    final rodadaRef = torneioRef.collection('rounds').doc('1');
    if ((await rodadaRef.get()).data()?['status'] != 'configuracao') {
      return 'status_invalido';
    }
    final existentes = await rodadaRef.collection('matches').limit(1).get();
    if (existentes.docs.isNotEmpty) return 'rodada_ja_configurada';
    final jogadores = await listarJogadoresAprovados(torneioId);
    if (jogadores.length < 2) return 'jogadores_insuficientes';
    final classificados = jogadores.map((j) => ClassificacaoJogadorModel(
      uid: j.uid, nome: j.nome, pontos: 0,
      vitorias: 0, derrotas: 0, empates: 0,
      winPercentage: 0, opponentWinPercentage: 0,
      opponentOpponentWinPercentage: 0,
      ativo: j.ativo, quantidadeByes: 0,
      divisaoEtaria: j.divisaoEtaria ?? 'nao_informada', podId: j.podId,
    )).toList();
    List<ConfrontoSwiss> confrontos;
    try {
      confrontos = const PareamentoSwissEngine().gerar(
        classificacao: classificados, historico: {},
        rodada: 1, torneioId: torneioId,
        separarDivisoes: torneio.agrupamentoEtario == 'separado',
      );
    } on StateError {
      return 'sem_pareamento_valido';
    }
    final porUid = {for (final j in jogadores) j.uid: j};
    final partidas = <PartidaModel>[];
    for (var i = 0; i < confrontos.length; i++) {
      final c = confrontos[i];
      final a = porUid[c.jogador1Uid]!;
      final b = c.jogador2Uid == null ? null : porUid[c.jogador2Uid];
      partidas.add(PartidaModel(
        id: '', mesa: c.bye ? 0 : i + 1,
        jogador1Uid: a.uid, jogador1Nome: a.nome,
        jogador2Uid: b?.uid, jogador2Nome: b?.nome,
        status: 'aguardando', placarJogador1: 0,
        placarJogador2: 0, bye: c.bye, podId: c.podId,
      ));
    }
    await salvarPrimeiraRodada(torneioId: torneioId, partidas: partidas);
    return 'ok';
  }

  Future<String> editarRodada({
    required String torneioId,
    required int rodada,
    required List<PartidaModel> novasPartidas,
  }) async {
    final torneioRef = _firestore.collection('tournaments').doc(torneioId);

    final rodadaRef = torneioRef.collection('rounds').doc(rodada.toString());

    final rodadaSnapshot = await rodadaRef.get();

    if (!rodadaSnapshot.exists) {
      return 'rodada_nao_encontrada';
    }

    final statusRodada = rodadaSnapshot.data()?['status'];
    if (rodadaSnapshot.data()?['fase'] == 'topcut') return 'edicao_topcut_nao_disponivel';

    if (statusRodada == 'finalizada') {
      return 'rodada_finalizada';
    }

    final jogadoresSnapshot = await torneioRef
        .collection('players')
        .where('status', isEqualTo: 'aprovado')
        .where('ativo', isEqualTo: true)
        .get();

    final jogadoresValidos = jogadoresSnapshot.docs
        .map((doc) => doc.id)
        .toSet();
    final torneioSnapshot = await torneioRef.get();
    if (!torneioSnapshot.exists) return 'torneio_nao_encontrado';
    final torneio = TorneioModel.fromMap(torneioId, torneioSnapshot.data()!);
    final gruposPorJogador = <String, String>{};
    final participantesPorGrupo = <String, int>{};
    for (final doc in jogadoresSnapshot.docs) {
      final jogador = JogadorTorneioModel.fromMap(doc.id, doc.data());
      final grupo = jogador.podId != 'geral' ? jogador.podId :
          (torneio.agrupamentoEtario == 'separado'
              ? (jogador.divisaoEtaria ?? 'nao_informada') : 'geral');
      gruposPorJogador[doc.id] = grupo;
      participantesPorGrupo[grupo] = (participantesPorGrupo[grupo] ?? 0) + 1;
    }

    final jogadoresUtilizados = <String>{};
    final byesPorGrupo = <String, int>{};

    int quantidadeByes = 0;

    for (final partida in novasPartidas) {
      if (!jogadoresValidos.contains(partida.jogador1Uid)) {
        return 'jogador_invalido';
      }

      if (!jogadoresUtilizados.add(partida.jogador1Uid)) {
        return 'jogador_duplicado';
      }

      if (partida.bye) {
        quantidadeByes++;
        final grupo = gruposPorJogador[partida.jogador1Uid]!;
        byesPorGrupo[grupo] = (byesPorGrupo[grupo] ?? 0) + 1;
        continue;
      }

      final jogador2Uid = partida.jogador2Uid;

      if (jogador2Uid == null || jogador2Uid.isEmpty) {
        return 'jogador_invalido';
      }

      if (jogador2Uid == partida.jogador1Uid) {
        return 'mesmo_jogador';
      }

      if (!jogadoresValidos.contains(jogador2Uid)) {
        return 'jogador_invalido';
      }
      if (gruposPorJogador[partida.jogador1Uid] != gruposPorJogador[jogador2Uid]) {
        return 'pod_invalido';
      }

      if (!jogadoresUtilizados.add(jogador2Uid)) {
        return 'jogador_duplicado';
      }
    }

    if (jogadoresUtilizados.length != jogadoresValidos.length) {
      return 'jogadores_sem_partida';
    }

    final totalByesEsperados = participantesPorGrupo.values
        .where((total) => total.isOdd).length;
    if (quantidadeByes != totalByesEsperados ||
        participantesPorGrupo.entries.any((e) =>
            (byesPorGrupo[e.key] ?? 0) != (e.value.isOdd ? 1 : 0))) {
      return 'bye_invalido';
    }

    final historico = await _buscarHistoricoConfrontos(
      torneioId: torneioId, rodadaAtual: rodada - 1);
    for (final partida in novasPartidas) {
      if (!partida.bye &&
          (historico[partida.jogador1Uid]?.contains(partida.jogador2Uid) ?? false)) {
        return 'confronto_repetido';
      }
    }
    final partidasAtuaisSnapshot = await rodadaRef.collection('matches').get();

    final partidasAtuais = partidasAtuaisSnapshot.docs
        .map((doc) => PartidaModel.fromMap(doc.id, doc.data()))
        .toList();
    if (partidasAtuais.any((p) => p.resultado == ResultadoPartida.derrotaAutomatica)) {
      return 'rodada_com_derrota_automatica';
    }

    final batch = _firestore.batch();

    for (final documento in partidasAtuaisSnapshot.docs) {
      batch.delete(documento.reference);
    }

    for (int i = 0; i < novasPartidas.length; i++) {
      final novaPartida = novasPartidas[i];

      final partidaAnterior = _buscarPartidaIgual(partidasAtuais, novaPartida);

      final partidaRef = rodadaRef.collection('matches').doc();

      if (partidaAnterior != null) {
        batch.set(
          partidaRef,
          PartidaModel(
            id: partidaRef.id,
            mesa: i + 1,
            jogador1Uid: partidaAnterior.jogador1Uid,
            jogador1Nome: partidaAnterior.jogador1Nome,
            jogador2Uid: partidaAnterior.jogador2Uid,
            jogador2Nome: partidaAnterior.jogador2Nome,
            status: partidaAnterior.status,
            placarJogador1: partidaAnterior.placarJogador1,
            placarJogador2: partidaAnterior.placarJogador2,
            resultadoInformadoPor: partidaAnterior.resultadoInformadoPor,
            bye: partidaAnterior.bye,
            resultado: partidaAnterior.resultado,
            fase: partidaAnterior.fase,
            podId: partidaAnterior.podId,
          ).toMap(),
        );
      } else {
        batch.set(
          partidaRef,
          PartidaModel(
            id: partidaRef.id,
            mesa: i + 1,
            jogador1Uid: novaPartida.jogador1Uid,
            jogador1Nome: novaPartida.jogador1Nome,
            jogador2Uid: novaPartida.jogador2Uid,
            jogador2Nome: novaPartida.jogador2Nome,
            status: statusRodada == 'configuracao'
                ? 'aguardando'
                : novaPartida.bye
                ? 'finalizada'
                : 'em_andamento',
            placarJogador1: 0,
            placarJogador2: 0,
            resultadoInformadoPor: null,
            bye: novaPartida.bye,
            fase: novaPartida.fase,
            podId: novaPartida.podId,
          ).toMap(),
        );
      }
    }

    await batch.commit();

    return 'ok';
  }

  PartidaModel? _buscarPartidaIgual(
    List<PartidaModel> partidas,
    PartidaModel novaPartida,
  ) {
    for (final partida in partidas) {
      final mesmaOrdem =
          partida.jogador1Uid == novaPartida.jogador1Uid &&
          partida.jogador2Uid == novaPartida.jogador2Uid;

      final ordemInvertida =
          !partida.bye &&
          !novaPartida.bye &&
          partida.jogador1Uid == novaPartida.jogador2Uid &&
          partida.jogador2Uid == novaPartida.jogador1Uid;

      if ((mesmaOrdem || ordemInvertida) && partida.bye == novaPartida.bye) {
        return partida;
      }
    }

    return null;
  }
}
