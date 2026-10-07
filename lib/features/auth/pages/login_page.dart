import 'package:flutter/material.dart';

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
      final resultado = await _authService.login(
        email: _emailController.text.trim(),
        senha: _senhaController.text,
      );

      final usuarioFirebase = resultado.user;

      if (usuarioFirebase == null) {
        throw Exception('Não foi possível identificar o usuário.');
      }

      final usuario = await _usuarioService.buscarUsuario(
        usuarioFirebase.uid,
      );

      if (usuario == null) {
        throw Exception(
          'Os dados do usuário não foram encontrados.',
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
    } on Exception catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } catch (_) {
      if (!mounted) return;

      _mostrarMensagem(
        'Ocorreu um erro ao realizar o login.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
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
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _senhaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
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
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Entrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}