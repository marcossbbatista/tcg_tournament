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
  static const int _totalPassos = 3;

  final _formNomeKey = GlobalKey<FormState>();
  final _formOficialKey = GlobalKey<FormState>();
  final _formAcessoKey = GlobalKey<FormState>();

  final _primeiroNomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _playerIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  DateTime? _dataNascimento;
  bool _erroData = false;

  final _authService = AuthService();
  final _usuarioService = UsuarioService();

  int _passo = 0;
  bool _carregando = false;
  bool _senhaVisivel = false;

  @override
  void initState() {
    super.initState();
    // Atualiza o medidor de força enquanto digita.
    _senhaController.addListener(_atualizar);
  }

  @override
  void dispose() {
    _primeiroNomeController.dispose();
    _sobrenomeController.dispose();
    _playerIdController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  // ============================================================
  // Navegação entre passos
  // ============================================================

  void _continuar() {
    FocusScope.of(context).unfocus();

    if (_passo == 0) {
      if (!_formNomeKey.currentState!.validate()) return;
      setState(() => _passo = 1);
    } else if (_passo == 1) {
      final formOk = _formOficialKey.currentState!.validate();
      final dataOk = _dataNascimento != null;

      setState(() => _erroData = !dataOk);

      if (!formOk || !dataOk) return;

      setState(() => _passo = 2);
    } else {
      _registrar();
    }
  }

  void _voltarPasso() {
    FocusScope.of(context).unfocus();

    if (_passo == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _passo--);
    }
  }

  // ============================================================
  // Cadastro
  // ============================================================

  Future<void> _registrar() async {
    if (_carregando) return;

    if (!_formAcessoKey.currentState!.validate()) return;

    if (_dataNascimento == null) {
      _mostrarMensagem('Informe a data de nascimento.');
      setState(() {
        _erroData = true;
        _passo = 1;
      });
      return;
    }

    FocusScope.of(context).unfocus();
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

      // Se o problema for no e-mail ou na senha, o passo atual já é o certo.
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
    FocusScope.of(context).unfocus();

    final data = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(2008),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (data != null && mounted) {
      setState(() {
        _dataNascimento = data;
        _erroData = false;
      });
    }
  }

  // ============================================================
  // Força da senha
  // ============================================================

  int get _forcaSenha {
    final s = _senhaController.text;

    if (s.isEmpty) return 0;

    var pontos = 0;

    if (s.length >= 6) pontos++;
    if (s.length >= 10) pontos++;
    if (RegExp(r'[a-z]').hasMatch(s) && RegExp(r'[A-Z]').hasMatch(s)) {
      pontos++;
    }
    if (RegExp(r'[0-9]').hasMatch(s) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(s)) {
      pontos++;
    }

    return pontos.clamp(1, 4);
  }

  String get _rotuloForca {
    switch (_forcaSenha) {
      case 1:
        return 'Fraca';
      case 2:
        return 'Razoável';
      case 3:
        return 'Boa';
      case 4:
        return 'Forte';
      default:
        return '';
    }
  }

  Color get _corForca {
    switch (_forcaSenha) {
      case 1:
        return const Color(0xFFFF6B6B);
      case 2:
        return const Color(0xFFFFB74D);
      case 3:
        return const Color(0xFF9CE37D);
      default:
        return TcgTheme.verde;
    }
  }

  // ============================================================
  // Peças de layout
  // ============================================================

  Widget _barraProgresso() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: List.generate(_totalPassos, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == _totalPassos - 1 ? 0 : 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _passo ? TcgTheme.verde : Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _cabecalhoPasso(String titulo, String subtitulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PASSO ${_passo + 1} DE $_totalPassos',
            style: const TextStyle(
              color: TcgTheme.verde,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            style: const TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ===== Passo 1: nome =====

  Widget _passoNome() {
    return Form(
      key: _formNomeKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalhoPasso(
            'Quem é você?',
            'Use o nome que aparece no seu documento. Ele será usado nas '
                'listas oficiais do torneio.',
          ),
          TextFormField(
            controller: _primeiroNomeController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            decoration: const InputDecoration(labelText: 'Primeiro nome'),
            validator: (valor) => valor == null || valor.trim().isEmpty
                ? 'Informe seu primeiro nome.'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sobrenomeController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.familyName],
            onFieldSubmitted: (_) => _continuar(),
            decoration: const InputDecoration(labelText: 'Sobrenome'),
            validator: (valor) => valor == null || valor.trim().isEmpty
                ? 'Informe seu sobrenome.'
                : null,
          ),
          const SizedBox(height: 24),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Já tem uma conta?',
                  style: TextStyle(color: TcgTheme.muted),
                ),
                TextButton(
                  onPressed: _carregando
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          Navigator.pop(context);
                        },
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
    );
  }

  // ===== Passo 2: dados oficiais =====

  Widget _passoOficial() {
    return Form(
      key: _formOficialKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalhoPasso(
            'Dados oficiais',
            'Esses dados identificam você nos torneios e na exportação para '
                'o TOM.',
          ),
          TextFormField(
            controller: _playerIdController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Pokémon Player ID (POP ID)',
              helperText: 'De 5 a 12 dígitos.',
            ),
            validator: PokemonRulebook.validarIdentificador,
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _selecionarData,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Data de nascimento',
                suffixIcon: const Icon(Icons.cake_outlined),
                errorText: _erroData ? 'Informe a data de nascimento.' : null,
              ),
              child: Text(
                _dataNascimento == null
                    ? 'Selecionar'
                    : _formatarData(_dataNascimento!),
                style: TextStyle(
                  color:
                      _dataNascimento == null ? Colors.white38 : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 18, color: TcgTheme.verde),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Você pode alterar esses dados depois, em Meu perfil.',
                    style: TextStyle(
                      color: TcgTheme.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Passo 3: acesso =====

  Widget _medidorSenha() {
    final forca = _forcaSenha;

    if (forca == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 3 ? 0 : 5),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 5,
                      decoration: BoxDecoration(
                        color: i < forca ? _corForca : Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _rotuloForca,
            style: TextStyle(
              color: _corForca,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _passoAcesso() {
    return Form(
      key: _formAcessoKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cabecalhoPasso(
              'Acesso à conta',
              'Com o e-mail e a senha você entra no app e acompanha seus '
                  'torneios.',
            ),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe seu e-mail.';
                }

                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(value.trim())) {
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
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _continuar(),
              decoration: InputDecoration(
                labelText: 'Senha',
                helperText: 'Mínimo de 6 caracteres.',
                suffixIcon: IconButton(
                  tooltip: 'Mostrar ou ocultar senha',
                  onPressed: () =>
                      setState(() => _senhaVisivel = !_senhaVisivel),
                  icon: Icon(
                    _senhaVisivel ? Icons.visibility_off : Icons.visibility,
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
            _medidorSenha(),
          ],
        ),
      ),
    );
  }

  Widget _conteudoPasso() {
    switch (_passo) {
      case 0:
        return _passoNome();
      case 1:
        return _passoOficial();
      default:
        return _passoAcesso();
    }
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final ultimoPasso = _passo == _totalPassos - 1;

    return PopScope(
      canPop: _passo == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltarPasso();
      },
      child: TcgTheme.wrap(
        Scaffold(
          backgroundColor: TcgTheme.fundo,
          resizeToAvoidBottomInset: true,
          body: TcgBackground(
            child: SafeArea(
              child: Column(
                children: [
                  // Barra fixa no topo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Voltar',
                          onPressed: _carregando ? null : _voltarPasso,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Image.asset(
                          'assets/images/pokeduelix_logo.png',
                          width: 28,
                          height: 28,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Criar conta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _barraProgresso(),

                  // Conteúdo do passo
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: SingleChildScrollView(
                            key: ValueKey(_passo),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            child: _conteudoPasso(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Botões fixos embaixo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Row(
                        children: [
                          if (_passo > 0) ...[
                            SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _carregando ? null : _voltarPasso,
                                child: const Text('Voltar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: TcgGradientButton(
                              texto: ultimoPasso ? 'Criar conta' : 'Continuar',
                              icone: ultimoPasso
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              carregando: _carregando,
                              onPressed: _continuar,
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
    );
  }
}