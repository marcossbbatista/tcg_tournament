import 'package:cloud_firestore/cloud_firestore.dart';

import '../../jogador/models/jogador_torneio_model.dart';
import '../models/partida_model.dart';

class RodadaService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<String> iniciarTorneio({
    required String torneioId,
  }) async {
    final torneioRef =
        _firestore.collection('tournaments').doc(torneioId);

    final jogadoresSnapshot = await torneioRef
        .collection('players')
        .where('status', isEqualTo: 'aprovado')
        .where('ativo', isEqualTo: true)
        .get();

    if (jogadoresSnapshot.docs.length < 2) {
      return 'jogadores_insuficientes';
    }

    await torneioRef.update({
      'status': 'em_andamento',
      'rodadaAtual': 1,
    });

    final rodadaRef =
        torneioRef.collection('rounds').doc('1');

    await rodadaRef.set({
      'numero': 1,
      'status': 'configuracao',
      'criadaEm': Timestamp.now(),
    });

    return 'ok';
  }

  Future<List<JogadorTorneioModel>>
      listarJogadoresAprovados(
    String torneioId,
  ) async {
    final snapshot = await _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('players')
        .where(
          'status',
          isEqualTo: 'aprovado',
        )
        .where(
          'ativo',
          isEqualTo: true,
        )
        .get();

    final jogadores = snapshot.docs
        .map(
          (doc) =>
              JogadorTorneioModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    jogadores.sort(
      (a, b) => a.nome.compareTo(b.nome),
    );

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

    final batch = _firestore.batch();

    for (final partida in partidas) {
      final partidaRef =
          rodadaRef.collection('matches').doc();

      batch.set(
        partidaRef,
        partida.toMap(),
      );
    }

    batch.update(
      rodadaRef,
      {
        'status': 'em_andamento',
      },
    );

    await batch.commit();
  }

  Future<String> encerrarRodada({
  required String torneioId,
  required int rodada,
}) async {
  final torneioRef = _firestore
      .collection('tournaments')
      .doc(torneioId);

  final rodadaRef = torneioRef
      .collection('rounds')
      .doc(rodada.toString());

  final partidasSnapshot = await rodadaRef
      .collection('matches')
      .get();

  if (partidasSnapshot.docs.isEmpty) {
    return 'nenhuma_partida';
  }

  final partidasRefs = partidasSnapshot.docs
      .map((doc) => doc.reference)
      .toList();

  return _firestore.runTransaction<String>(
    (transaction) async {
      final rodadaSnapshot =
          await transaction.get(rodadaRef);

      if (!rodadaSnapshot.exists) {
        return 'rodada_nao_encontrada';
      }

      final dadosRodada =
          rodadaSnapshot.data();

      if (dadosRodada?['status'] ==
          'finalizada') {
        return 'rodada_finalizada';
      }

      final List<PartidaModel> partidas = [];

      for (final partidaRef in partidasRefs) {
        final partidaSnapshot =
            await transaction.get(
          partidaRef,
        );

        if (!partidaSnapshot.exists) {
          continue;
        }

        final dados =
            partidaSnapshot.data();

        if (dados == null) {
          continue;
        }

        partidas.add(
          PartidaModel.fromMap(
            partidaSnapshot.id,
            dados,
          ),
        );
      }

      if (partidas.isEmpty) {
        return 'nenhuma_partida';
      }

      final possuiPartidaPendente =
          partidas.any(
        (partida) =>
            partida.status != 'finalizada',
      );

      if (possuiPartidaPendente) {
        return 'partida_pendente';
      }

      final Map<String, int> pontosPorJogador =
          {};

      for (final partida in partidas) {
        if (partida.bye) {
          pontosPorJogador[
                  partida.jogador1Uid] =
              (pontosPorJogador[
                          partida.jogador1Uid] ??
                      0) +
                  3;

          continue;
        }

        final jogador2Uid =
            partida.jogador2Uid;

        if (jogador2Uid == null) {
          continue;
        }

        if (partida.placarJogador1 >
            partida.placarJogador2) {
          pontosPorJogador[
                  partida.jogador1Uid] =
              (pontosPorJogador[
                          partida.jogador1Uid] ??
                      0) +
                  3;

          pontosPorJogador.putIfAbsent(
            jogador2Uid,
            () => 0,
          );
        } else if (partida.placarJogador2 >
            partida.placarJogador1) {
          pontosPorJogador[
                  jogador2Uid] =
              (pontosPorJogador[
                          jogador2Uid] ??
                      0) +
                  3;

          pontosPorJogador.putIfAbsent(
            partida.jogador1Uid,
            () => 0,
          );
        } else {
          pontosPorJogador[
                  partida.jogador1Uid] =
              (pontosPorJogador[
                          partida.jogador1Uid] ??
                      0) +
                  1;

          pontosPorJogador[
                  jogador2Uid] =
              (pontosPorJogador[
                          jogador2Uid] ??
                      0) +
                  1;
        }
      }

      for (final entry
          in pontosPorJogador.entries) {
        final jogadorRef = torneioRef
            .collection('players')
            .doc(entry.key);

        final jogadorSnapshot =
            await transaction.get(
          jogadorRef,
        );

        if (!jogadorSnapshot.exists) {
          continue;
        }

        final dadosJogador =
            jogadorSnapshot.data();

        final pontosAtuais =
            dadosJogador?['pontos'] ?? 0;

        transaction.update(
          jogadorRef,
          {
            'pontos':
                pontosAtuais + entry.value,
          },
        );
      }

      transaction.update(
        rodadaRef,
        {
          'status': 'finalizada',
          'finalizadaEm':
              Timestamp.now(),
        },
      );

      return 'ok';
    },
  );
}
}