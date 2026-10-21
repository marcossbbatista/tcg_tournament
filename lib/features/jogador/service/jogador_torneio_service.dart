import 'package:cloud_firestore/cloud_firestore.dart';

import '../../torneio/models/torneio_model.dart';
import '../models/jogador_torneio_model.dart';
import '../models/torneio_jogador_model.dart';
import 'package:flutter/foundation.dart';

class JogadorTorneioService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<TorneioModel?> buscarTorneioPorCodigo(
    String codigo,
  ) async {
    final resultado = await _firestore
        .collection('tournaments')
        .where(
          'codigo',
          isEqualTo: codigo.trim().toUpperCase(),
        )
        .limit(1)
        .get();

    if (resultado.docs.isEmpty) {
      return null;
    }

    final documento = resultado.docs.first;

    return TorneioModel.fromMap(
      documento.id,
      documento.data(),
    );
  }

  Future<String> solicitarParticipacao({
    required TorneioModel torneio,
    required String uid,
    required String nome,
    required String email,
  }) async {
    if (torneio.status != 'inscricoes') {
      return 'inscricoes_encerradas';
    }

    final documento = _firestore
        .collection('tournaments')
        .doc(torneio.id)
        .collection('players')
        .doc(uid);

    final existente = await documento.get();

    if (existente.exists) {
      final dados = existente.data();

      return dados?['status'] ?? 'pendente';
    }

    final jogador = JogadorTorneioModel(
      uid: uid,
      nome: nome,
      email: email,
      status: 'pendente',
      pontos: 0,
      ativo: true,
      entrouEm: DateTime.now(),
    );

    await documento.set(
      jogador.toMap(),
    );

    return 'pendente';
  }

  Stream<List<JogadorTorneioModel>>
      listarJogadores(
    String torneioId,
  ) {
    return _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('players')
        .snapshots()
        .map(
          (snapshot) {
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
              (a, b) =>
                  a.nome.compareTo(b.nome),
            );

            return jogadores;
          },
        );
  }

  Future<void> atualizarStatusJogador({
  required String torneioId,
  required String jogadorUid,
  required String status,
}) async {
  await _firestore
      .collection('tournaments')
      .doc(torneioId)
      .collection('players')
      .doc(jogadorUid)
      .update({
        'status': status,
      });
}

Future<void> aprovarJogador({
  required String torneioId,
  required String jogadorUid,
}) async {
  await atualizarStatusJogador(
    torneioId: torneioId,
    jogadorUid: jogadorUid,
    status: 'aprovado',
  );
}

Future<void> recusarJogador({
  required String torneioId,
  required String jogadorUid,
}) async {
  await atualizarStatusJogador(
    torneioId: torneioId,
    jogadorUid: jogadorUid,
    status: 'recusado',
  );
}


Stream<List<TorneioJogadorModel>> listarTorneiosDoJogador(
  String uid,
) async* {
  await for (final snapshot in _firestore
      .collection('tournaments')
      .snapshots()) {
    final List<TorneioJogadorModel> resultado = [];

    for (final torneioDoc in snapshot.docs) {
      try {
        final jogadorDoc = await torneioDoc.reference
            .collection('players')
            .doc(uid)
            .get();

        if (!jogadorDoc.exists) {
          continue;
        }

        final dadosJogador = jogadorDoc.data();

        if (dadosJogador == null) {
          continue;
        }

        final torneio = TorneioModel.fromMap(
          torneioDoc.id,
          torneioDoc.data(),
        );

        resultado.add(
          TorneioJogadorModel(
            torneio: torneio,
            status: dadosJogador['status'] ?? 'pendente',
            pontos: (dadosJogador['pontos'] as num?)?.toInt() ?? 0,
            ativo: dadosJogador['ativo'] ?? true,
          ),
        );
      } catch (e, stackTrace) {
        debugPrint(
          'Erro ao carregar participação no torneio '
          '${torneioDoc.id}: $e',
        );
        debugPrint('$stackTrace');
        rethrow;
      }
    }

    resultado.sort(
      (a, b) => a.torneio.dataHora.compareTo(
        b.torneio.dataHora,
      ),
    );

    yield resultado;
  }
}
}