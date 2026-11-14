import 'package:tcg_tournament/core/responsive/responsive_body.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';

import '../services/auth_service.dart';

class RecuperarSenhaPage extends StatefulWidget {
  const RecuperarSenhaPage({super.key});

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _enviarEmail() async {
    if (_carregando) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      await _authService.recuperarSenha(_emailController.text.trim());

      if (!mounted) return;

      _mostrarMensagem(
        'Se houver uma conta compatível, você receberá um e-mail com as instruções.',
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Não foi possível enviar o e-mail. Tente novamente.';

      if (e.code == 'invalid-email') {
        mensagem = 'O endereço de e-mail é inválido.';
      } else if (e.code == 'too-many-requests') {
        mensagem = 'Muitas tentativas. Aguarde um pouco e tente novamente.';
      } else if (e.code == 'network-request-failed') {
        mensagem = 'Verifique sua conexão com a internet.';
      }

      _mostrarMensagem(mensagem);
    } catch (_) {
      _mostrarMensagem('Ocorreu um erro inesperado.');
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TcgTheme.wrap(
      Scaffold(
        backgroundColor: TcgTheme.fundo,
        resizeToAvoidBottomInset: true,
        body: TcgBackground(
          child: SafeArea(
            child: ResponsiveBody(
              maxWidth: 720,
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: TcgGlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: AutofillGroup(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Logo
                                  Image.asset(
                                    'assets/images/pokeduelix_logo.png',
                                    width: 56,
                                    height: 56,
                                  ),
                                  const SizedBox(height: 20),

                                  const Text(
                                    'Esqueceu sua senha?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Informe seu e-mail cadastrado. '
                                    'Enviaremos instruções para você '
                                    'redefinir sua senha.',
                                    style: TextStyle(
                                      color: TcgTheme.muted,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.done,
                                    autocorrect: false,
                                    autofillHints: const [AutofillHints.email],
                                    onFieldSubmitted: (_) => _enviarEmail(),
                                    decoration: const InputDecoration(
                                      labelText: 'E-mail',
                                    ),
                                    validator: (valor) {
                                      if (valor == null ||
                                          valor.trim().isEmpty) {
                                        return 'Informe seu e-mail.';
                                      }

                                      if (!RegExp(
                                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                      ).hasMatch(valor.trim())) {
                                        return 'Informe um e-mail válido.';
                                      }

                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  TcgGradientButton(
                                    texto: 'Enviar instruções',
                                    icone: Icons.send_rounded,
                                    carregando: _carregando,
                                    onPressed: _enviarEmail,
                                  ),
                                  const SizedBox(height: 8),

                                  Center(
                                    child: TextButton(
                                      onPressed: _carregando
                                          ? null
                                          : () => Navigator.pop(context),
                                      child: const Text(
                                        'Voltar para o login',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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

                  // Botão voltar
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}