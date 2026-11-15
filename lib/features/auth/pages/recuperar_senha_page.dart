import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';

import '../services/auth_service.dart';

class RecuperarSenhaPage extends StatefulWidget {
  /// E-mail já digitado na tela de login (opcional).
  final String? emailInicial;

  const RecuperarSenhaPage({super.key, this.emailInicial});

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  static const int _intervaloReenvio = 30;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _authService = AuthService();

  Timer? _timer;

  bool _carregando = false;
  bool _enviado = false;
  String _emailEnviado = '';
  int _segundos = 0;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.emailInicial ?? '');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // Envio
  // ============================================================

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  String _mensagemErro(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'O endereço de e-mail é inválido.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
      case 'network-request-failed':
        return 'Verifique sua conexão com a internet.';
      default:
        return 'Não foi possível enviar o e-mail. Tente novamente.';
    }
  }

  void _iniciarContador() {
    _timer?.cancel();

    setState(() => _segundos = _intervaloReenvio);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (_segundos <= 1) {
        t.cancel();
        setState(() => _segundos = 0);
      } else {
        setState(() => _segundos--);
      }
    });
  }

  Future<void> _enviarEmail({bool reenvio = false}) async {
    if (_carregando) return;
    if (reenvio && _segundos > 0) return;

    if (!reenvio && !_formKey.currentState!.validate()) return;

    final email = reenvio ? _emailEnviado : _emailController.text.trim();

    FocusScope.of(context).unfocus();
    setState(() => _carregando = true);

    try {
      await _authService.recuperarSenha(email);

      if (!mounted) return;

      setState(() {
        _enviado = true;
        _emailEnviado = email;
      });

      _iniciarContador();

      if (reenvio) _mostrarMensagem('E-mail reenviado.');
    } on FirebaseAuthException catch (e) {
      _mostrarMensagem(_mensagemErro(e));
    } catch (_) {
      _mostrarMensagem('Ocorreu um erro inesperado.');
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  void _usarOutroEmail() {
    _timer?.cancel();

    setState(() {
      _enviado = false;
      _segundos = 0;
      _emailController.clear();
    });
  }

  void _voltar() {
    FocusScope.of(context).unfocus();
    Navigator.pop(context);
  }

  // ============================================================
  // Estado 1: formulário
  // ============================================================

  Widget _estadoFormulario() {
    return Column(
      key: const ValueKey('formulario'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ===== CARD DE VIDRO (só o topo) =====
        TcgGlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: TcgTheme.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x553DDC84),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: Colors.white,
                  size: 28,
                ),
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
                'Sem problema. Informe o e-mail da sua conta e enviaremos '
                'um link para você criar uma nova senha.',
                style: TextStyle(color: TcgTheme.muted, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ===== FORMULÁRIO (fora do card) =====
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) => _enviarEmail(),
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe seu e-mail.';
                    }

                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(valor.trim())) {
                      return 'Informe um e-mail válido.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TcgGradientButton(
                  texto: 'Enviar link',
                  icone: Icons.send_rounded,
                  carregando: _carregando,
                  onPressed: _enviarEmail,
                ),
                const SizedBox(height: 8),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Lembrou da senha?',
                        style: TextStyle(color: TcgTheme.muted),
                      ),
                      TextButton(
                        onPressed: _carregando ? null : _voltar,
                        child: const Text(
                          'Entrar',
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
      ],
    );
  }

  // ============================================================
  // Estado 2: sucesso
  // ============================================================

  Widget _passo(int numero, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x263DDC84),
            ),
            child: Text(
              '$numero',
              style: const TextStyle(
                color: TcgTheme.verde,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: Colors.white, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoSucesso() {
    final podeReenviar = _segundos == 0 && !_carregando;

    return Column(
      key: const ValueKey('sucesso'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TcgGlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1F3DDC84),
                ),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: TcgTheme.gradient,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x663DDC84),
                        blurRadius: 22,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Confira seu e-mail',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Se houver uma conta com este e-mail, enviamos as instruções '
                'para',
                textAlign: TextAlign.center,
                style: TextStyle(color: TcgTheme.muted, height: 1.4),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x26FFFFFF)),
                ),
                child: Text(
                  _emailEnviado,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TcgTheme.verde,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'PRÓXIMOS PASSOS',
          style: TextStyle(
            color: TcgTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _passo(1, 'Abra o e-mail que enviamos.'),
        _passo(2, 'Toque no link para redefinir a senha.'),
        _passo(3, 'Crie uma nova senha e entre no app.'),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x1FFFB74D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x55FFB74D)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFFFFB74D)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Não chegou? Olhe também a caixa de spam ou lixo '
                  'eletrônico.',
                  style: TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        TcgGradientButton(
          texto: 'Voltar para o login',
          icone: Icons.login_rounded,
          onPressed: _voltar,
        ),
        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: podeReenviar ? () => _enviarEmail(reenvio: true) : null,
          icon: _carregando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
          label: Text(
            _segundos > 0 ? 'Reenviar em ${_segundos}s' : 'Reenviar e-mail',
          ),
        ),

        const SizedBox(height: 4),

        Center(
          child: TextButton(
            onPressed: _carregando ? null : _usarOutroEmail,
            child: const Text('Usar outro e-mail'),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return TcgTheme.wrap(
      Scaffold(
        backgroundColor: TcgTheme.fundo,
        resizeToAvoidBottomInset: true,
        body: TcgBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Seta fixa no topo
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: IconButton(
                      tooltip: 'Voltar',
                      onPressed: _voltar,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Só esta área rola
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _enviado
                              ? _estadoSucesso()
                              : _estadoFormulario(),
                        ),
                      ),
                    ),
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