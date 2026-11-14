import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_tournament/core/session/usuario_session.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:tcg_tournament/features/home/pages/home_jogador_page.dart';

import '../services/auth_service.dart';
import '../services/usuario_service.dart';
import '../models/usuario_model.dart';
import '../../torneio/rules/pokemon_rulebook.dart';

class RegistrarPage extends StatefulWidget {
  const RegistrarPage({super.key});

  @override
  State<RegistrarPage> createState() => _RegistrarPageState();
}

class _RegistrarPageState extends State<RegistrarPage> {
  final _formKey = GlobalKey<FormState>();

  final _primeiroNomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _playerIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  DateTime? _dataNascimento;

  final _authService = AuthService();
  final _usuarioService = UsuarioService();

  bool _carregando = false;
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _primeiroNomeController.dispose();
    _sobrenomeController.dispose();
    _playerIdController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_carregando) return;

    if (!_formKey.currentState!.validate()) return;

    if (_dataNascimento == null) {
      _mostrarMensagem('Informe a data de nascimento.');
      return;
    }

    setState(() => _carregando = true);

    try {
      final primeiroNome = _primeiroNomeController.text.trim();
      final sobrenome = _sobrenomeController.text.trim();
      final nome = '$primeiroNome $sobrenome';
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
        primeiroNome: primeiroNome,
        sobrenome: sobrenome,
        pokemonPlayerId: _playerIdController.text.trim(),
        dataNascimento: _dataNascimento,
      );

      await _usuarioService.criarUsuario(usuario);

      // Inicia a sessão do usuário.
      UsuarioSession.iniciar(usuario);

      if (!mounted) return;

      // Encaminha para a página inicial do jogador.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeJogadorPage()),
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

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(2008),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (data != null && mounted) {
      setState(() => _dataNascimento = data);
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
            child: Column(
              children: [
                // Seta fixa no topo
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.pop(context),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ===== CARD DE VIDRO (só o topo) =====
                            TcgGlassCard(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/pokeduelix_logo.png',
                                    width: 56,
                                    height: 56,
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Crie sua conta',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Preencha seus dados para começar a '
                                    'participar dos torneios.',
                                    style: TextStyle(
                                      color: TcgTheme.muted,
                                      height: 1.4,
                                    ),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Nome oficial para o TOM.
                                    TextFormField(
                                      controller: _primeiroNomeController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.givenName,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Primeiro nome',
                                      ),
                                      validator: (valor) =>
                                          valor == null ||
                                                  valor.trim().isEmpty
                                              ? 'Informe seu primeiro nome.'
                                              : null,
                                    ),
                                    const SizedBox(height: 16),

                                    TextFormField(
                                      controller: _sobrenomeController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.familyName,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Sobrenome',
                                      ),
                                      validator: (valor) =>
                                          valor == null ||
                                                  valor.trim().isEmpty
                                              ? 'Informe seu sobrenome.'
                                              : null,
                                    ),
                                    const SizedBox(height: 16),

                                    TextFormField(
                                      controller: _playerIdController,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Pokémon Player ID (POP ID)',
                                        helperText: 'De 5 a 12 dígitos.',
                                      ),
                                      validator:
                                          PokemonRulebook.validarIdentificador,
                                    ),
                                    const SizedBox(height: 16),

                                    // Data de nascimento
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: _selecionarData,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          suffixIcon:
                                              Icon(Icons.cake_outlined),
                                        ),
                                        child: Text(
                                          _dataNascimento == null
                                              ? 'SData de nascimento'
                                              : _formatarData(
                                                  _dataNascimento!),
                                          style: TextStyle(
                                            color: _dataNascimento == null
                                                ? Colors.white38
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autocorrect: false,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'E-mail',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
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

                                    TextFormField(
                                      controller: _senhaController,
                                      obscureText: !_senhaVisivel,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      onFieldSubmitted: (_) => _registrar(),
                                      decoration: InputDecoration(
                                        labelText: 'Senha',
                                        suffixIcon: IconButton(
                                          tooltip: 'Mostrar ou ocultar senha',
                                          onPressed: () => setState(
                                            () => _senhaVisivel =
                                                !_senhaVisivel,
                                          ),
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
                                          return 'A senha deve ter pelo '
                                              'menos 6 caracteres.';
                                        }

                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 28),

                                    TcgGradientButton(
                                      texto: 'Criar conta',
                                      carregando: _carregando,
                                      onPressed: _registrar,
                                    ),
                                    const SizedBox(height: 8),

                                    Center(
                                      child: Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          const Text(
                                            'Já tem uma conta?',
                                            style: TextStyle(
                                              color: TcgTheme.muted,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _carregando
                                                ? null
                                                : () =>
                                                    Navigator.pop(context),
                                            child: const Text(
                                              'Entrar',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
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