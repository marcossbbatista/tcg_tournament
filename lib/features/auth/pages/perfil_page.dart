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
    _primeiroNomeController.addListener(_atualizar);
    _sobrenomeController.addListener(_atualizar);
    _playerIdController.addListener(_atualizar);
    _carregarPerfil();
  }

  @override
  void dispose() {
    _primeiroNomeController.dispose();
    _sobrenomeController.dispose();
    _playerIdController.dispose();
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
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

  // ===== Detecta se houve alteração =====

  bool _mesmaData(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool get _alterado {
    final u = _usuario;
    if (u == null) return false;

    return _primeiroNomeController.text.trim() != u.primeiroNome.trim() ||
        _sobrenomeController.text.trim() != u.sobrenome.trim() ||
        _playerIdController.text.trim() != (u.pokemonPlayerId ?? '').trim() ||
        !_mesmaData(_dataNascimento, u.dataNascimento);
  }

  String get _iniciais {
    final u = _usuario;
    if (u == null) return '?';

    final a = u.primeiroNome.trim();
    final b = u.sobrenome.trim();

    final texto = '${a.isNotEmpty ? a[0] : ''}${b.isNotEmpty ? b[0] : ''}';

    return texto.isEmpty ? '?' : texto.toUpperCase();
  }

  // ===== Dados =====

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

  // ===== Widgets =====

  Widget _avatar() {
    return Container(
      width: 116,
      height: 116,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x1F3DDC84),
      ),
      child: Container(
        width: 92,
        height: 92,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: TcgTheme.gradient,
          boxShadow: [
            BoxShadow(
              color: Color(0x663DDC84),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          _iniciais,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _etiqueta({
    required IconData icone,
    required String texto,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cor.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 15, color: cor),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho(UsuarioModel usuario) {
    final ehAdm = usuario.tipo == 'adm';

    return Column(
      children: [
        _avatar(),
        const SizedBox(height: 16),
        Text(
          usuario.nome,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          usuario.email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: TcgTheme.muted),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _etiqueta(
              icone: ehAdm
                  ? Icons.admin_panel_settings_outlined
                  : Icons.style_rounded,
              texto: ehAdm ? 'Organizador' : 'Jogador',
              cor: TcgTheme.verde,
            ),
            if (!usuario.possuiDadosOficiais)
              _etiqueta(
                icone: Icons.info_outline,
                texto: 'Perfil incompleto',
                cor: const Color(0xFFFFB74D),
              ),
          ],
        ),
      ],
    );
  }

  Widget _cartaoDados() {
    return TcgGlassCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DADOS OFICIAIS',
              style: TextStyle(
                color: TcgTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Usados na inscrição e na exportação TOM (.tdf).',
              style: TextStyle(color: TcgTheme.muted, height: 1.4),
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _primeiroNomeController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Primeiro nome',
                    ),
                    validator: (valor) =>
                        valor == null || valor.trim().isEmpty
                            ? 'Obrigatório.'
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sobrenomeController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Sobrenome',
                    ),
                    validator: (valor) =>
                        valor == null || valor.trim().isEmpty
                            ? 'Obrigatório.'
                            : null,
                  ),
                ),
              ],
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
            const SizedBox(height: 20),

            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 16, color: TcgTheme.muted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O e-mail e o nível de acesso são gerenciados pela '
                    'conta e não podem ser alterados aqui.',
                    style: TextStyle(
                      color: TcgTheme.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final usuario = _usuario;

    if (usuario == null) {
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    _cabecalho(usuario),
                    const SizedBox(height: 28),
                    _cartaoDados(),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Botão fixo embaixo
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: TcgGradientButton(
              texto: 'Salvar alterações',
              icone: Icons.save_outlined,
              carregando: _salvando,
              onPressed: _alterado && !_salvando ? _salvar : null,
            ),
          ),
        ),
      ],
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
                // Barra fixa no topo
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Voltar',
                        onPressed: _voltar,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Meu perfil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(child: _conteudo()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}