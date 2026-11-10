import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_tournament/core/session/usuario_session.dart';
import 'package:tcg_tournament/features/home/pages/home_jogador_page.dart';

import '../services/auth_service.dart';
import '../services/usuario_service.dart';
import '../models/usuario_model.dart';

class RegistrarPage extends StatefulWidget {
  const RegistrarPage({super.key});

  @override
  State<RegistrarPage> createState() => _RegistrarPageState();
}

class _RegistrarPageState extends State<RegistrarPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  final _authService = AuthService();
  final _usuarioService = UsuarioService();

  bool _carregando = false;
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_carregando) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _carregando = true);

    try {
      final nome = _nomeController.text.trim();
      final email = _emailController.text.trim();
      final senha = _senhaController.text;

      // Cria a conta no Firebase Authentication.
      final resultado = await _authService.cadastrar(
        email: email,
        senha: senha,
      );

      final usuarioFirebase = resultado.user;

      if (usuarioFirebase == null) {
        throw Exception('Não foi possível criar a conta.');
      }

      // Atualiza o nome no perfil do Firebase.
      await usuarioFirebase.updateDisplayName(nome);

      // Cria o usuário no Firestore.
      final usuario = UsuarioModel(
        uid: usuarioFirebase.uid,
        nome: nome,
        email: email,
        tipo: 'jogador',
      );

      await _usuarioService.criarUsuario(usuario);

      // Inicia a sessão do usuário.
      UsuarioSession.iniciar(usuario);

      if (!mounted) return;

      // Encaminha para a página inicial do jogador.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeJogadorPage(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(_mensagemErro(e));
    } catch (e) {
      _mostrarMensagem('Não foi possível realizar o cadastro: $e');
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  String _mensagemErro(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'Informe um e-mail válido.';
      case 'weak-password':
        return 'A senha é muito fraca. Utilize pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Verifique sua conexão com a internet.';
      default:
        return e.message ?? 'Não foi possível criar a conta.';
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Criar conta'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1,
                      size: 64,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Crie sua conta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Preencha seus dados para começar a participar dos torneios.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nome
                    TextFormField(
                      controller: _nomeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe seu nome.';
                        }

                        if (value.trim().length < 2) {
                          return 'Informe um nome válido.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // E-mail
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe seu e-mail.';
                        }

                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(value.trim())) {
                          return 'Informe um e-mail válido.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Senha
                    TextFormField(
                      controller: _senhaController,
                      obscureText: !_senhaVisivel,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _senhaVisivel = !_senhaVisivel;
                            });
                          },
                          icon: Icon(
                            _senhaVisivel
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe uma senha.';
                        }

                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Botão cadastrar
                    ElevatedButton(
                      onPressed: _carregando ? null : _registrar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _carregando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Criar conta'),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _carregando
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Já tenho uma conta. Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
