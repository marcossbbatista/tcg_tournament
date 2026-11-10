
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Instância única do Google Sign-In
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Inicialização do Google Sign-In
  static final Future<void> _googleSignInInicializado =
      _googleSignIn.initialize();

  User? get usuarioAtual => _auth.currentUser;

  // CADASTRO COM E-MAIL E SENHA
  Future<UserCredential> cadastrar({
    required String email,
    required String senha,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  // LOGIN COM E-MAIL E SENHA
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

  // LOGIN COM GOOGLE
  Future<UserCredential> loginComGoogle() async {
    try {
      // Aguarda a inicialização do Google
      await _googleSignInInicializado;

      // Abre a seleção de contas Google
      final GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate();

      // Obtém o token de autenticação
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Verifica se o token foi obtido
      if (googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Não foi possível obter o token do Google.',
        );
      }

      // Cria a credencial para o Firebase
      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Autentica o usuário no Firebase
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('Erro Firebase Google: ${e.code} - ${e.message}');
      rethrow;
    } on GoogleSignInException catch (e) {
      print('Erro Google Sign-In: ${e.code} - ${e.description}');
      rethrow;
    } catch (e) {
      print('Erro inesperado no login Google: $e');
      rethrow;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> recuperarSenha(String email) async {
  await _auth.sendPasswordResetEmail(
    email: email.trim(),
  );
}
}
