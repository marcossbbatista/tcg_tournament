import 'package:tcg_tournament/core/responsive/responsive_body.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a data de nascimento.')),
      );
      return;
    }

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TcgTheme.wrap(Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: ResponsiveBody(maxWidth: 720, child: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _usuario == null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_erro ?? 'Perfil indisponível.'),
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const TcgHero(
                            title: 'Dados do jogador',
                            subtitle: 'Mantenha seus dados oficiais atualizados. '
                                'Eles serão usados na inscrição e na exportação TOM (.tdf).',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            initialValue: _usuario!.email,
                            enabled: false,
                            decoration: const InputDecoration(
                              labelText: 'E-mail da conta',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _primeiroNomeController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Primeiro nome',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (valor) => valor == null || valor.trim().isEmpty
                                ? 'Informe seu primeiro nome.' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _sobrenomeController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Sobrenome',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (valor) => valor == null || valor.trim().isEmpty
                                ? 'Informe seu sobrenome.' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _playerIdController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pokémon Player ID (POP ID)',
                              prefixIcon: Icon(Icons.confirmation_number_outlined),
                              helperText: 'Identificador de 5 a 12 dígitos.',
                            ),
                            validator: PokemonRulebook.validarIdentificador,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _salvando ? null : _selecionarNascimento,
                            icon: const Icon(Icons.cake_outlined),
                            label: Text(_dataNascimento == null
                                ? 'Selecionar data de nascimento'
                                : 'Nascimento: ${_formatarData(_dataNascimento!)}'),
                          ),
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed: _salvando ? null : _salvar,
                            icon: _salvando
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.save_outlined),
                            label: const Text('Salvar perfil'),
                          ),
                          const SizedBox(height: 14),
                          const Text('O e-mail e o nível de acesso são '
                              'gerenciados pela conta e não podem ser alterados aqui.'),
                        ],
                      ),
                    ),
                  )),
                )),
    ));
  }
}
