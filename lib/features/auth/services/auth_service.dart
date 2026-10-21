import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get usuarioAtual => _auth.currentUser;

  Future<UserCredential> cadastrar({
    required String email,
    required String senha,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
  }

  Future<UserCredential> login({
    required String email,
    required String senha,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
    } on FirebaseAuthException catch (e) {
      print('Erro ao fazer login: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}