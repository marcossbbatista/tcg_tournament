import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/partida_model.dart';

class PartidaService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Stream<PartidaModel?> observarPartidaDoJogador({
    required String torneioId,
    required int rodada,
    required String jogadorUid,
  }) {
    final matchesRef = _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('rounds')
        .doc(rodada.toString())
        .collection('matches');

    return matchesRef.snapshots().map(
      (snapshot) {
        for (final doc in snapshot.docs) {
          final dados = doc.data();

          if (dados['jogador1Uid'] == jogadorUid ||
              dados['jogador2Uid'] == jogadorUid) {
            return PartidaModel.fromMap(
              doc.id,
              dados,
            );
          }
        }

        return null;
      },
    );
  }

  Future<void> informarResultado({
    required String torneioId,
    required int rodada,
    required String partidaId,
    required int placarJogador1,
    required int placarJogador2,
    required String informadoPor,
  }) async {
    await _partidaRef(
      torneioId: torneioId,
      rodada: rodada,
      partidaId: partidaId,
    ).update({
      'placarJogador1': placarJogador1,
      'placarJogador2': placarJogador2,
      'resultadoInformadoPor': informadoPor,
      'status': 'aguardando_confirmacao',
    });
  }

  Future<void> confirmarResultado({
    required String torneioId,
    required int rodada,
    required String partidaId,
  }) async {
    await _partidaRef(
      torneioId: torneioId,
      rodada: rodada,
      partidaId: partidaId,
    ).update({
      'status': 'finalizada',
    });
  }

  Future<void> contestarResultado({
    required String torneioId,
    required int rodada,
    required String partidaId,
  }) async {
    await _partidaRef(
      torneioId: torneioId,
      rodada: rodada,
      partidaId: partidaId,
    ).update({
      'status': 'contestada',
    });
  }

  DocumentReference<Map<String, dynamic>> _partidaRef({
    required String torneioId,
    required int rodada,
    required String partidaId,
  }) {
    return _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('rounds')
        .doc(rodada.toString())
        .collection('matches')
        .doc(partidaId);
  }
}