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
}