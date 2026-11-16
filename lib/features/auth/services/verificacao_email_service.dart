import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificacaoEmailService {
  final _functions = FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  Future<void> enviarCodigo() async {
    await _functions.httpsCallable('enviarCodigoEmail').call();
  }

  Future<void> confirmarCodigo(String codigo) async {
    await _functions.httpsCallable('confirmarCodigoEmail').call({'codigo': codigo.trim()});
    await FirebaseAuth.instance.currentUser?.reload();
    if (FirebaseAuth.instance.currentUser?.emailVerified != true) {
      throw StateError('A verificação ainda não foi reconhecida. Tente novamente.');
    }
  }
}
