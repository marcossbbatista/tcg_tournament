import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/partida_model.dart';
import '../../../core/session/usuario_session.dart';

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
    ResultadoPartida? resultado,
  }) async {
    final resolvido = resultado ?? (placarJogador1 > placarJogador2
        ? ResultadoPartida.vitoriaJogador1
        : placarJogador2 > placarJogador1
            ? ResultadoPartida.vitoriaJogador2
            : ResultadoPartida.empate);
    final especial = resolvido == ResultadoPartida.woJogador1 ||
        resolvido == ResultadoPartida.woJogador2 ||
        resolvido == ResultadoPartida.derrotaDupla;
    if (especial && !UsuarioSession.ehAdm) {
      throw StateError('Somente o administrador pode registrar W.O. ou derrota dupla.');
    }
    final ref = _partidaRef(torneioId: torneioId, rodada: rodada, partidaId: partidaId);
    await _firestore.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) throw StateError('Partida não encontrada.');
      final dados = PartidaModel.fromMap(doc.id, doc.data()!);
      if (dados.bye || dados.status == 'finalizada') {
        throw StateError('Esta partida não aceita novos resultados.');
      }
      if (dados.fase == 'topcut' &&
          (resolvido == ResultadoPartida.empate || resolvido == ResultadoPartida.derrotaDupla)) {
        throw StateError('Top Cut requer um vencedor.');
      }
      tx.update(ref, {
        'placarJogador1': placarJogador1,
        'placarJogador2': placarJogador2,
        'resultado': resolvido.name,
        'resultadoInformadoPor': informadoPor,
        'status': especial ? 'finalizada' : 'aguardando_confirmacao',
      });
    });
  }

  Future<void> confirmarResultado({
    required String torneioId,
    required int rodada,
    required String partidaId,
  }) async {
    final ref = _partidaRef(torneioId: torneioId, rodada: rodada, partidaId: partidaId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists || snapshot.data()?['status'] != 'aguardando_confirmacao') {
        throw StateError('Partida não está aguardando confirmação.');
      }
      tx.update(ref, {'status': 'finalizada'});
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

  Stream<List<PartidaModel>> observarPartidasDaRodada({
  required String torneioId,
  required int rodada,
}) {
  return _firestore
      .collection('tournaments')
      .doc(torneioId)
      .collection('rounds')
      .doc(rodada.toString())
      .collection('matches')
      .snapshots()
      .map(
        (snapshot) {
          final partidas = snapshot.docs
              .map(
                (doc) => PartidaModel.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList();

          partidas.sort(
            (a, b) => a.mesa.compareTo(b.mesa),
          );

          return partidas;
        },
      );
}

Future<void> resolverPartidaContestada({
  required String torneioId,
  required int rodada,
  required String partidaId,
  required int placarJogador1,
  required int placarJogador2,
  ResultadoPartida? resultado,
}) async {
  final definido = resultado ?? (placarJogador1 > placarJogador2
      ? ResultadoPartida.vitoriaJogador1
      : placarJogador2 > placarJogador1
          ? ResultadoPartida.vitoriaJogador2 : ResultadoPartida.empate);
  if (!UsuarioSession.ehAdm) throw StateError('Operação restrita ao administrador.');
  await _partidaRef(
    torneioId: torneioId,
    rodada: rodada,
    partidaId: partidaId,
  ).update({
    'placarJogador1': placarJogador1,
    'placarJogador2': placarJogador2,
    'resultado': definido.name,
    'status': 'finalizada',
  });
}

Future<List<PartidaModel>> buscarPartidasDaRodada({
  required String torneioId,
  required int rodada,
}) async {
  final snapshot = await _firestore
      .collection('tournaments')
      .doc(torneioId)
      .collection('rounds')
      .doc(rodada.toString())
      .collection('matches')
      .get();

  final partidas = snapshot.docs
      .map(
        (doc) => PartidaModel.fromMap(
          doc.id,
          doc.data(),
        ),
      )
      .toList();

  partidas.sort(
    (a, b) => a.mesa.compareTo(b.mesa),
  );

  return partidas;
}
}