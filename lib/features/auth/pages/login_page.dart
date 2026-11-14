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
    return TcgTheme.wrap(Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: ResponsiveBody(maxWidth: 720, child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TcgHero(title: 'PokéDuelix', subtitle: 'Organize e acompanhe seus torneios',   imageAsset: 'assets/images/trasgo_logo.jpg'),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _senhaController,
                  obscureText: !_senhaVisivel,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_carregando) {
                      _fazerLogin();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    suffixIcon: IconButton(tooltip: 'Mostrar ou ocultar senha', icon: Icon(_senhaVisivel ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel)),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 24),

                // Botão entrar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _fazerLogin,
                    child: _carregando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Entrar'),
                  ),
                ),

                const SizedBox(height: 20),

                // Separador OU
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OU',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                // Botão Google
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _carregando ? null : _fazerLoginComGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: const BorderSide(
                        color: Color(0xFFDADCE0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                          'Continuar com Google',
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

                // Criar conta
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed:  _carregando
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegistrarPage(),
                            ),
                          );
                        },
                    child: TextButton(
                  onPressed: _carregando
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegistrarPage(),
                            ),
                          );
                        },
                  child: const Text('Criar conta'),
                )
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecuperarSenhaPage(),
                      ),
                    );
                  },
                  child: const Text('Esqueci minha senha'),
                ),
              ],
            ),
          ),
        ),
      )),
    ));
  }
}
