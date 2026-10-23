
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();

    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _senhaController.text.isEmpty) {
      _mostrarMensagem('Informe o e-mail e a senha.');
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      debugPrint('ETAPA 1: Iniciando autenticação');

      final resultado = await _authService.login(
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );

      debugPrint('ETAPA 2: Login autenticado');

      final usuarioFirebase = resultado.user;

      if (usuarioFirebase == null) {
        throw Exception(
          'Não foi possível identificar o usuário autenticado.',
        );
      }

      debugPrint('ETAPA 3: UID = ${usuarioFirebase.uid}');
      debugPrint('ETAPA 4: Buscando usuário no Firestore');

      final usuario = await _usuarioService.buscarUsuario(
        usuarioFirebase.uid,
      );

      debugPrint('ETAPA 5: Consulta ao Firestore concluída');

      if (usuario == null) {
        throw Exception(
          'Os dados do usuário não foram encontrados. '
          'Verifique se existe um documento na coleção users '
          'com o ID igual ao UID do usuário autenticado.',
        );
      }

      debugPrint('ETAPA 6: Usuário encontrado');
      debugPrint('Tipo de usuário: ${usuario.tipo}');

      UsuarioSession.iniciar(usuario);

      if (!mounted) return;

      if (usuario.tipo == 'adm') {
        debugPrint('ETAPA 7: Abrindo tela do administrador');

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeAdmPage(),
          ),
        );
      } else if (usuario.tipo == 'jogador') {
        debugPrint('ETAPA 7: Abrindo tela do jogador');

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeJogadorPage(),
          ),
        );
      } else {
        throw Exception(
          'Tipo de usuário inválido: ${usuario.tipo}',
        );
      }
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('ERRO FIREBASE AUTHENTICATION');
      debugPrint('Código: ${e.code}');
      debugPrint('Mensagem: ${e.message}');
      debugPrint('$stackTrace');

      if (!mounted) return;

      _mostrarMensagem(_mensagemErroAutenticacao(e));
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('ERRO FIREBASE');
      debugPrint('Código: ${e.code}');
      debugPrint('Mensagem: ${e.message}');
      debugPrint('$stackTrace');

      if (!mounted) return;

      _mostrarMensagem(
        'Erro ao consultar os dados: ${e.code}',
      );
    } catch (e, stackTrace) {
      debugPrint('ERRO NO LOGIN');
      debugPrint('$e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      _mostrarMensagem(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'TCG Tournament',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

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
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_carregando) {
                      _fazerLogin();
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 24),

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
