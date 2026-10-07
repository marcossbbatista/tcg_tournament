import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

class UsuarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UsuarioModel?> buscarUsuario(String uid) async {
    final documento = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!documento.exists || documento.data() == null) {
      return null;
    }

    return UsuarioModel.fromMap(
      documento.id,
      documento.data()!,
    );
  }
}