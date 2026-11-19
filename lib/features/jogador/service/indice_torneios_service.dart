import 'package:cloud_firestore/cloud_firestore.dart';

/// Índice de inscrições. A inscrição em tournaments/.../players continua
/// sendo a fonte oficial para status, pontos e regras do campeonato.
class IndiceTorneiosService {
  static DocumentReference<Map<String, dynamic>> referencia(
    FirebaseFirestore db, String uid, String torneioId,
  ) => db.collection('users').doc(uid).collection('tournaments').doc(torneioId);

  static Map<String, dynamic> dados({
    required String torneioId,
    required Map<String, dynamic> torneio,
    required Map<String, dynamic> jogador,
  }) => {
    'torneioId': torneioId,
    'nomeTorneio': torneio['nome'] ?? '',
    'statusTorneio': torneio['status'] ?? '',
    'dataTorneio': torneio['dataHora'],
    'statusInscricao': jogador['status'] ?? 'pendente',
    'pontos': jogador['pontos'] ?? 0,
    'ativo': jogador['ativo'] ?? true,
    'atualizadoEm': FieldValue.serverTimestamp(),
  };

  static void atualizarParticipacao(
    WriteBatch batch, FirebaseFirestore db, String uid, String torneioId,
    Map<String, dynamic> alteracoes,
  ) {
    // Atualizações legadas podem completar o índice após a migração.
    batch.set(referencia(db, uid, torneioId), {
      ...alteracoes,
      'atualizadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
