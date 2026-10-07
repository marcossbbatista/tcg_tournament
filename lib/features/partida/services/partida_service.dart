import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/partida_model.dart';

class PartidaService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<PartidaModel?> buscarPartidaDoJogador({
    required String torneioId,
    required int rodada,
    required String jogadorUid,
  }) async {
    final matchesRef = _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('rounds')
        .doc(rodada.toString())
        .collection('matches');

    final jogador1 = await matchesRef
        .where(
          'jogador1Uid',
          isEqualTo: jogadorUid,
        )
        .limit(1)
        .get();

    if (jogador1.docs.isNotEmpty) {
      final doc = jogador1.docs.first;

      return PartidaModel.fromMap(
        doc.id,
        doc.data(),
      );
    }

    final jogador2 = await matchesRef
        .where(
          'jogador2Uid',
          isEqualTo: jogadorUid,
        )
        .limit(1)
        .get();

    if (jogador2.docs.isNotEmpty) {
      final doc = jogador2.docs.first;

      return PartidaModel.fromMap(
        doc.id,
        doc.data(),
      );
    }

    return null;
  }
}