import 'package:cloud_firestore/cloud_firestore.dart';
import '../../torneio/models/torneio_model.dart';
import '../../torneio/models/classificacao_jogador_model.dart';
import '../models/partida_model.dart';
import 'rodada_service.dart';

/// Organiza chave eliminatória após a fase suíça.
/// Top cut por divisão etária, usando a classificação suíça congelada.
class TopCutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<int> _posicoesChave(int tamanho) {
    var sementes = <int>[1, 2];
    while (sementes.length < tamanho) {
      final espelho = sementes.length * 2 + 1;
      sementes = [for (final indice in sementes) ...[indice, espelho - indice]];
    }
    return sementes;
  }

  Future<String> iniciarTopCut({required String torneioId}) async {
    final ref = _db.collection('tournaments').doc(torneioId);
    final doc = await ref.get();
    if (!doc.exists) return 'torneio_nao_encontrado';
    final torneio = TorneioModel.fromMap(torneioId, doc.data()!);
    if (torneio.tamanhoTopCut == 0) return 'topcut_desabilitado';
    if (torneio.status != 'em_andamento' ||
        torneio.rodadaAtual != torneio.quantidadeRodadas) return 'status_invalido';
    if ((await ref.collection('rounds').doc('${torneio.rodadaAtual}').get())
        .data()?['status'] != 'finalizada') return 'rodada_nao_finalizada';
    final proximo = torneio.rodadaAtual + 1;
    final proximaRef = ref.collection('rounds').doc('$proximo');
    if ((await proximaRef.get()).exists) return 'rodada_ja_existe';
    final classificacao = await RodadaService().buscarClassificacao(torneioId: torneioId);
    final grupos = <String, List<ClassificacaoJogadorModel>>{};
    for (final jogador in classificacao.where((j) => j.ativo)) {
      grupos.putIfAbsent(jogador.divisaoEtaria, () => []).add(jogador);
    }
    // A pontuação final de cada divisão é determinada separadamente,
    // mesmo quando as divisões jogaram Swiss combinado.
    final partidas = <PartidaModel>[];
    var mesa = 1;
    for (final entry in grupos.entries) {
      final jogadores = entry.value;
      if (jogadores.length < torneio.tamanhoTopCut) continue;
      final sementes = _posicoesChave(torneio.tamanhoTopCut);
      for (var i = 0; i < sementes.length; i += 2) {
        final a = jogadores[sementes[i] - 1];
        final b = jogadores[sementes[i + 1] - 1];
        partidas.add(PartidaModel(
          id: '', mesa: mesa++,
          jogador1Uid: a.uid, jogador1Nome: a.nome,
          jogador2Uid: b.uid, jogador2Nome: b.nome,
          status: 'aguardando', placarJogador1: 0, placarJogador2: 0,
          bye: false, fase: 'topcut', podId: entry.key,
        ));
      }
    }
    if (partidas.isEmpty) return 'topcut_sem_divisao_elegivel';
    final batch = _db.batch();
    batch.set(proximaRef, {
      'numero': proximo, 'fase': 'topcut', 'status': 'configuracao',
      'criadaEm': Timestamp.now(),
    });
    for (final partida in partidas) {
      final partidaRef = proximaRef.collection('matches').doc();
      batch.set(partidaRef, partida.toMap());
    }
    batch.update(ref, {'rodadaAtual': proximo, 'faseAtual': 'topcut'});
    await batch.commit();
    return 'ok';
  }

  /// Avança apenas partidas concluídas com vencedor; nunca permite empate no Top Cut.
  Future<String> gerarProximaRodada({required String torneioId}) async {
    final ref = _db.collection('tournaments').doc(torneioId);
    final doc = await ref.get();
    if (!doc.exists) return 'torneio_nao_encontrado';
    final torneio = TorneioModel.fromMap(torneioId, doc.data()!);
    if (torneio.status != 'em_andamento' ||
        torneio.rodadaAtual <= torneio.quantidadeRodadas) return 'status_invalido';
    final atualRef = ref.collection('rounds').doc('${torneio.rodadaAtual}');
    if ((await atualRef.get()).data()?['status'] != 'finalizada') {
      return 'rodada_nao_finalizada';
    }
    final atuais = (await atualRef.collection('matches').get()).docs
        .map((d) => PartidaModel.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => a.mesa.compareTo(b.mesa));
    if (atuais.isEmpty) return 'nenhuma_partida';
    final grupos = <String, List<PartidaModel>>{};
    for (final p in atuais) {
      grupos.putIfAbsent(p.podId, () => []).add(p);
    }
    if (grupos.values.every((g) => g.length == 1)) return 'topcut_concluido';
    final proximo = torneio.rodadaAtual + 1;
    final proximoRef = ref.collection('rounds').doc('$proximo');
    if ((await proximoRef.get()).exists) return 'rodada_ja_existe';
    final partidas = <PartidaModel>[];
    var mesa = 1;
    for (final entry in grupos.entries) {
      final anteriores = entry.value;
      if (anteriores.length.isOdd) return 'chave_invalida';
      for (var i = 0; i < anteriores.length; i += 2) {
        final a = _vencedor(anteriores[i]);
        final b = _vencedor(anteriores[i + 1]);
        if (a == null || b == null) return 'resultado_invalido';
        partidas.add(PartidaModel(
          id: '', mesa: mesa++,
          jogador1Uid: a.$1, jogador1Nome: a.$2,
          jogador2Uid: b.$1, jogador2Nome: b.$2,
          status: 'aguardando', placarJogador1: 0, placarJogador2: 0,
          bye: false, fase: 'topcut', podId: entry.key,
        ));
      }
    }
    final batch = _db.batch();
    batch.set(proximoRef, {
      'numero': proximo, 'fase': 'topcut', 'status': 'configuracao',
      'criadaEm': Timestamp.now(),
    });
    for (final partida in partidas) {
      batch.set(proximoRef.collection('matches').doc(), partida.toMap());
    }
    batch.update(ref, {'rodadaAtual': proximo});
    await batch.commit();
    return 'ok';
  }

  (String, String)? _vencedor(PartidaModel partida) {
    switch (partida.resultado) {
      case ResultadoPartida.vitoriaJogador1:
      case ResultadoPartida.woJogador2:
        return (partida.jogador1Uid, partida.jogador1Nome);
      case ResultadoPartida.vitoriaJogador2:
      case ResultadoPartida.woJogador1:
        final id = partida.jogador2Uid;
        if (id == null) return null;
        return (id, partida.jogador2Nome ?? '');
      default:
        return null;
    }
  }
}
