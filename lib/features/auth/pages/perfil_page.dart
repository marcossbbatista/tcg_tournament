import 'package:flutter/material.dart';

import '../../../core/session/usuario_session.dart';
import '../../../core/theme/tcg_theme.dart';
import '../../torneio/rules/pokemon_rulebook.dart';
import '../models/usuario_model.dart';
import '../services/usuario_service.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _primeiroNomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _playerIdController = TextEditingController();
  final _usuarioService = UsuarioService();

  UsuarioModel? _usuario;
  DateTime? _dataNascimento;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _primeiroNomeController.dispose();
    _sobrenomeController.dispose();
    _playerIdController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  void _voltar() {
    FocusScope.of(context).unfocus();
    Navigator.pop(context);
  }

  Future<void> _carregarPerfil() async {
    final sessao = UsuarioSession.usuario;
    if (sessao == null) {
      setState(() {
        _erro = 'Usuário não identificado.';
        _carregando = false;
      });
      return;
    }

    try {
      final usuario = await _usuarioService.buscarUsuario(sessao.uid);
      if (!mounted) return;
      if (usuario == null) {
        setState(() {
          _erro = 'Perfil não encontrado.';
          _carregando = false;
        });
        return;
      }
      _primeiroNomeController.text = usuario.primeiroNome;
      _sobrenomeController.text = usuario.sobrenome;
      _playerIdController.text = usuario.pokemonPlayerId ?? '';
      _dataNascimento = usuario.dataNascimento;
      UsuarioSession.iniciar(usuario);
      setState(() {
        _usuario = usuario;
        _carregando = false;
        _erro = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível carregar seu perfil: $e';
          _carregando = false;
        });
      }
    }
  }

  Future<void> _selecionarNascimento() async {
    FocusScope.of(context).unfocus();

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

  String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/${data.year}';

  Future<void> _salvar() async {
    final usuario = _usuario;
    if (usuario == null || _salvando) return;
    if (!_formKey.currentState!.validate()) return;
    if (_dataNascimento == null) {
      _mostrarMensagem('Informe a data de nascimento.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);

    try {
      final atualizado = await _usuarioService.atualizarPerfil(
        usuarioAtual: usuario,
        primeiroNome: _primeiroNomeController.text,
        sobrenome: _sobrenomeController.text,
        pokemonPlayerId: _playerIdController.text,
        dataNascimento: _dataNascimento!,
      );
      if (!mounted) return;
      UsuarioSession.iniciar(atualizado);
      setState(() => _usuario = atualizado);

      String mensagem = 'Perfil atualizado com sucesso.';
      try {
        await _usuarioService.sincronizarInscricoes(atualizado);
      } catch (e) {
        // Perfil já foi salvo; não informar falha da gravação principal.
        mensagem = 'Perfil salvo, mas não foi possível atualizar todas as '
            'inscrições existentes. Confira as permissões do Firestore: $e';
      }
      _mostrarMensagem(mensagem);
    } catch (e) {
      _mostrarMensagem('Não foi possível salvar o perfil: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usuario == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _erro ?? 'Perfil indisponível.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Center(
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: TcgTheme.gradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Dados do jogador',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mantenha seus dados oficiais atualizados. '
                      'Eles serão usados na inscrição e na '
                      'exportação TOM (.tdf).',
                      style: TextStyle(color: TcgTheme.muted, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ===== FORMULÁRIO (fora do card) =====
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: _usuario!.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'E-mail da conta',
                        suffixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _primeiroNomeController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Primeiro nome',
                      ),
                      validator: (valor) =>
                          valor == null || valor.trim().isEmpty
                              ? 'Informe seu primeiro nome.'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _sobrenomeController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Sobrenome',
                      ),
                      validator: (valor) =>
                          valor == null || valor.trim().isEmpty
                              ? 'Informe seu sobrenome.'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _playerIdController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Pokémon Player ID (POP ID)',
                        helperText: 'Identificador de 5 a 12 dígitos.',
                      ),
                      validator: PokemonRulebook.validarIdentificador,
                    ),
                    const SizedBox(height: 16),

                    // Data de nascimento
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _salvando ? null : _selecionarNascimento,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de nascimento',
                          suffixIcon: Icon(Icons.cake_outlined),
                        ),
                        child: Text(
                          _dataNascimento == null
                              ? 'Selecionar'
                              : _formatarData(_dataNascimento!),
                          style: TextStyle(
                            color: _dataNascimento == null
                                ? Colors.white38
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    TcgGradientButton(
                      texto: 'Salvar perfil',
                      icone: Icons.save_outlined,
                      carregando: _salvando,
                      onPressed: _salvar,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'O e-mail e o nível de acesso são gerenciados pela '
                      'conta e não podem ser alterados aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TcgTheme.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      onPressed: _voltar,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Só esta área rola
                Expanded(child: _conteudo()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}