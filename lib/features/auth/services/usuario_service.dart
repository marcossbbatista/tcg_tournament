
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<UsuarioModel> buscarOuCriarUsuarioGoogle(
    User usuarioFirebase,
  ) async {
    final usuarioRef = _firestore
        .collection('users')
        .doc(usuarioFirebase.uid);

    return await _firestore.runTransaction<UsuarioModel>(
      (transaction) async {
        final documento = await transaction.get(usuarioRef);

        // Se já existir, mantém os dados atuais.
        // Isso preserva inclusive usuários administradores.
        if (documento.exists && documento.data() != null) {
          return UsuarioModel.fromMap(
            documento.id,
            documento.data()!,
          );
        }

        // Primeiro acesso: cria como jogador.
        final novoUsuario = UsuarioModel(
          uid: usuarioFirebase.uid,
          nome: usuarioFirebase.displayName?.trim().isNotEmpty == true
              ? usuarioFirebase.displayName!.trim()
              : 'Jogador',
          email: usuarioFirebase.email ?? '',
          tipo: 'jogador',
        );

        transaction.set(usuarioRef, novoUsuario.toMap());

        return novoUsuario;
      },
    );
  }

  
Future<void> criarUsuario(UsuarioModel usuario) async {
  await _firestore
      .collection('users')
      .doc(usuario.uid)
      .set(usuario.toMap());
}

}
