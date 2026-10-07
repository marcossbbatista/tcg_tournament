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

Future<String> editarRodada({
  required String torneioId,
  required int rodada,
  required List<PartidaModel> novasPartidas,
}) async {
  final torneioRef = _firestore
      .collection('tournaments')
      .doc(torneioId);

  final rodadaRef = torneioRef
      .collection('rounds')
      .doc(rodada.toString());

  final rodadaSnapshot =
      await rodadaRef.get();

  if (!rodadaSnapshot.exists) {
    return 'rodada_nao_encontrada';
  }

  final statusRodada =
      rodadaSnapshot.data()?['status'];

  if (statusRodada == 'finalizada') {
    return 'rodada_finalizada';
  }

  final jogadoresSnapshot = await torneioRef
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

  final jogadoresValidos = jogadoresSnapshot.docs
      .map(
        (doc) => doc.id,
      )
      .toSet();

  final jogadoresUtilizados =
      <String>{};

  int quantidadeByes = 0;

  for (final partida in novasPartidas) {
    if (!jogadoresValidos.contains(
      partida.jogador1Uid,
    )) {
      return 'jogador_invalido';
    }

    if (!jogadoresUtilizados.add(
      partida.jogador1Uid,
    )) {
      return 'jogador_duplicado';
    }

    if (partida.bye) {
      quantidadeByes++;

      continue;
    }

    final jogador2Uid =
        partida.jogador2Uid;

    if (jogador2Uid == null ||
        jogador2Uid.isEmpty) {
      return 'jogador_invalido';
    }

    if (jogador2Uid ==
        partida.jogador1Uid) {
      return 'mesmo_jogador';
    }

    if (!jogadoresValidos.contains(
      jogador2Uid,
    )) {
      return 'jogador_invalido';
    }

    if (!jogadoresUtilizados.add(
      jogador2Uid,
    )) {
      return 'jogador_duplicado';
    }
  }

  if (jogadoresUtilizados.length !=
      jogadoresValidos.length) {
    return 'jogadores_sem_partida';
  }

  if (jogadoresValidos.length.isEven &&
      quantidadeByes > 0) {
    return 'bye_invalido';
  }

  if (jogadoresValidos.length.isOdd &&
      quantidadeByes != 1) {
    return 'bye_obrigatorio';
  }

  final partidasAtuaisSnapshot =
      await rodadaRef
          .collection('matches')
          .get();

  final partidasAtuais =
      partidasAtuaisSnapshot.docs
          .map(
            (doc) =>
                PartidaModel.fromMap(
              doc.id,
              doc.data(),
            ),
          )
          .toList();

  final batch =
      _firestore.batch();

  for (final documento
      in partidasAtuaisSnapshot.docs) {
    batch.delete(
      documento.reference,
    );
  }

  for (int i = 0;
      i < novasPartidas.length;
      i++) {
    final novaPartida =
        novasPartidas[i];

    final partidaAnterior =
        _buscarPartidaIgual(
      partidasAtuais,
      novaPartida,
    );

    final partidaRef = rodadaRef
        .collection('matches')
        .doc();

    if (partidaAnterior != null) {
      batch.set(
        partidaRef,
        PartidaModel(
          id: partidaRef.id,
          mesa: i + 1,
          jogador1Uid:
              partidaAnterior.jogador1Uid,
          jogador1Nome:
              partidaAnterior.jogador1Nome,
          jogador2Uid:
              partidaAnterior.jogador2Uid,
          jogador2Nome:
              partidaAnterior.jogador2Nome,
          status:
              partidaAnterior.status,
          placarJogador1:
              partidaAnterior
                  .placarJogador1,
          placarJogador2:
              partidaAnterior
                  .placarJogador2,
          resultadoInformadoPor:
              partidaAnterior
                  .resultadoInformadoPor,
          bye:
              partidaAnterior.bye,
        ).toMap(),
      );
    } else {
      batch.set(
        partidaRef,
        PartidaModel(
          id: partidaRef.id,
          mesa: i + 1,
          jogador1Uid:
              novaPartida.jogador1Uid,
          jogador1Nome:
              novaPartida.jogador1Nome,
          jogador2Uid:
              novaPartida.jogador2Uid,
          jogador2Nome:
              novaPartida.jogador2Nome,
          status: novaPartida.bye
              ? 'finalizada'
              : statusRodada ==
                      'configuracao'
                  ? 'aguardando'
                  : 'em_andamento',
          placarJogador1: 0,
          placarJogador2: 0,
          resultadoInformadoPor:
              null,
          bye:
              novaPartida.bye,
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
    if (partida.jogador1Uid ==
            novaPartida.jogador1Uid &&
        partida.jogador2Uid ==
            novaPartida.jogador2Uid &&
        partida.bye ==
            novaPartida.bye) {
      return partida;
    }
  }

  return null;
}

}