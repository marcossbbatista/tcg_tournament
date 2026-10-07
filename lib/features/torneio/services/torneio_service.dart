import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/torneio_model.dart';

class TorneioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<TorneioModel> criarTorneio({
    required String nome,
    required DateTime dataHora,
    required String formato,
    required int quantidadeRodadas,
    required String criadoPor,
  }) async {
    final String codigo = await _gerarCodigoUnico();

    final DocumentReference<Map<String, dynamic>> documento =
        _firestore.collection('tournaments').doc();

    final torneio = TorneioModel(
      id: documento.id,
      nome: nome,
      codigo: codigo,
      dataHora: dataHora,
      formato: formato,
      quantidadeRodadas: quantidadeRodadas,
      rodadaAtual: 0,
      status: 'inscricoes',
      criadoPor: criadoPor,
      criadoEm: DateTime.now(),
    );

    await documento.set(torneio.toMap());

    return torneio;
  }

  Stream<List<TorneioModel>> listarTorneiosDoAdm(
    String uid,
  ) {
    return _firestore
        .collection('tournaments')
        .where('criadoPor', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) {
            final torneios = snapshot.docs
                .map(
                  (doc) => TorneioModel.fromMap(
                    doc.id,
                    doc.data(),
                  ),
                )
                .toList();

            torneios.sort(
              (a, b) => a.dataHora.compareTo(b.dataHora),
            );

            return torneios;
          },
        );
  }

  Future<String> _gerarCodigoUnico() async {
    final Random random = Random();

    while (true) {
      final int numero = 1000 + random.nextInt(9000);

      final String codigo = 'TCG$numero';

      final QuerySnapshot<Map<String, dynamic>> resultado =
          await _firestore
              .collection('tournaments')
              .where('codigo', isEqualTo: codigo)
              .limit(1)
              .get();

      if (resultado.docs.isEmpty) {
        return codigo;
      }
    }
  }

  Stream<TorneioModel?> observarTorneio(
  String torneioId,
) {
  return _firestore
      .collection('tournaments')
      .doc(torneioId)
      .snapshots()
      .map(
        (doc) {
          if (!doc.exists) {
            return null;
          }

          final dados = doc.data();

          if (dados == null) {
            return null;
          }

          return TorneioModel.fromMap(
            doc.id,
            dados,
          );
        },
      );
}
}