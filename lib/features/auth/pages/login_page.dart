import 'package:flutter/services.dart';
import 'package:tcg_tournament/core/responsive/responsive_body.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_tournament/features/auth/pages/recuperar_senha_page.dart';
import 'package:tcg_tournament/features/auth/pages/registrar_page.dart';

import '../services/auth_service.dart';
import '../services/usuario_service.dart';

import '../../../core/session/usuario_session.dart';

import '../../home/pages/home_adm_page.dart';
import '../../home/pages/home_jogador_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  final _authService = AuthService();
  final _usuarioService = UsuarioService();

  bool _carregando = false;
  bool _senhaVisivel = false;

  Future<void> _abrir(Widget pagina) async {
  FocusScope.of(context).unfocus();

  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => pagina),
  );

  if (!mounted) return;
  FocusManager.instance.primaryFocus?.unfocus();
}

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();

    super.dispose();
  }

  

Future<void> _fazerLogin() async {
  if (_carregando) return;

  setState(() => _carregando = true);

  try {
    final resultado = await _authService.login(
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );

    await _processarLogin(resultado);
  } on FirebaseAuthException catch (e) {
    _mostrarMensagem(_mensagemErroAutenticacao(e));
  } on FirebaseException catch (e) {
    _mostrarMensagem('Erro ao acessar o banco de dados: ${e.message}');
  } catch (e) {
    _mostrarMensagem('Não foi possível fazer login: $e');
  } finally {
    if (mounted) {
      setState(() => _carregando = false);
    }
  }
}

Future<void> _fazerLoginComGoogle() async {
  if (_carregando) return;

  setState(() => _carregando = true);

  try {
    final resultado = await _authService.loginComGoogle();

    await _processarLogin(
      resultado,
      criarUsuarioGoogle: true,
    );
  } on FirebaseAuthException catch (e) {
    _mostrarMensagem(_mensagemErroAutenticacao(e));
  } on FirebaseException catch (e) {
    _mostrarMensagem('Erro ao acessar o banco de dados: ${e.message}');
  } catch (e) {
    _mostrarMensagem('Não foi possível entrar com o Google: $e');
  } finally {
    if (mounted) {
      setState(() => _carregando = false);
    }
  }
}

Future<void> _processarLogin(
  UserCredential resultado, {
  bool criarUsuarioGoogle = false,
}) async {
  final usuarioFirebase = resultado.user;

  if (usuarioFirebase == null) {
    throw Exception('Não foi possível identificar o usuário.');
  }

  final usuario = criarUsuarioGoogle
      ? await _usuarioService.buscarOuCriarUsuarioGoogle(
          usuarioFirebase,
        )
      : await _usuarioService.buscarUsuario(
          usuarioFirebase.uid,
        );

  if (usuario == null) {
    throw Exception(
      'Os dados do usuário não foram encontrados. '
      'O cadastro precisa ser concluído no sistema.',
    );
  }

  UsuarioSession.iniciar(usuario);

  if (!mounted) return;

  if (usuario.tipo == 'adm') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeAdmPage(),
      ),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeJogadorPage(),
      ),
    );
  }
}

  String _mensagemErroAutenticacao(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';

      case 'user-not-found':
        return 'Nenhum usuário foi encontrado com esse e-mail.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';

      case 'user-disabled':
        return 'Esta conta foi desativada.';

      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';

      case 'network-request-failed':
        return 'Falha de conexão. Verifique sua internet.';

      default:
        return 'Erro na autenticação: ${e.code}';
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
    Widget build(BuildContext context) {
      return TcgTheme.wrap(
        Scaffold(
          resizeToAvoidBottomInset: true,
          body: TcgBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: TcgGlassCard(
                      padding: const EdgeInsets.all(24),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ícone
                            Image.asset(
                              'assets/images/pokeduelix_logo.png',
                              width: 64,
                              height: 64,
                            ),
                            const SizedBox(height: 20),

                            const Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                                children: [
                                  TextSpan(text: 'Poké', style: TextStyle(color: Colors.white)),
                                  TextSpan(text: 'Duelix', style: TextStyle(color: TcgTheme.verde)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Entre para acompanhar seus torneios',
                              style: TextStyle(color: TcgTheme.muted),
                            ),
                            const SizedBox(height: 28),

                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextField(
                              controller: _senhaController,
                              obscureText: !_senhaVisivel,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => _fazerLogin(),
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                suffixIcon: IconButton(
                                  tooltip: 'Mostrar ou ocultar senha',
                                  icon: Icon(
                                    _senhaVisivel
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                    () => _senhaVisivel = !_senhaVisivel,
                                  ),
                                ),
                              ),
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _abrir(const RecuperarSenhaPage()),
                                child: const Text(
                                  'Esqueci minha senha',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            TcgGradientButton(
                              texto: 'Entrar',
                              carregando: _carregando,
                              onPressed: _fazerLogin,
                            ),

                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'OU CONTINUE COM',
                                    style: TextStyle(
                                      color: TcgTheme.muted,
                                      fontSize: 12,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed:
                                    _carregando ? null : _fazerLoginComGoogle,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  side: const BorderSide(
                                    color: Color(0xFFDADCE0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/google_logo.png',
                                      height: 22,
                                      width: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Google',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            Center(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    'Não tem uma conta?',
                                    style: TextStyle(color: TcgTheme.muted),
                                  ),
                                  TextButton(
                                    onPressed: _carregando ? null : () => _abrir(const RegistrarPage()),
                                    child: const Text(
                                      'Criar conta',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
