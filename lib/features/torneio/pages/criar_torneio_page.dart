import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';

import '../../../core/session/usuario_session.dart';
import '../services/torneio_service.dart';
import '../rules/pokemon_rulebook.dart';

class CriarTorneioPage extends StatefulWidget {
  const CriarTorneioPage({super.key});

  @override
  State<CriarTorneioPage> createState() => _CriarTorneioPageState();
}

class _CriarTorneioPageState extends State<CriarTorneioPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _quantidadeRodadasController =
      TextEditingController();

  final _sanctionController = TextEditingController();
  final _organizadorController = TextEditingController();
  final _organizadorPlayerIdController = TextEditingController();
  String _tipoEvento = 'custom';
  String _formatoJogo = 'standard';
  String _agrupamento = 'combinado';
  int _temporada = PokemonRulebook.temporadaAtual;
  int _tamanhoTopCut = 0;

  final TorneioService _torneioService = TorneioService();

  DateTime? _dataSelecionada;
  TimeOfDay? _horarioSelecionado;

  String _formatoSelecionado = 'md3';

  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeRodadasController.dispose();
    _sanctionController.dispose();
    _organizadorController.dispose();
    _organizadorPlayerIdController.dispose();

    super.dispose();
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
      });
    }
  }

  Future<void> _selecionarHorario() async {
    final TimeOfDay? horario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (horario == null) return;

    setState(() {
      _horarioSelecionado = horario;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dataSelecionada == null) {
      _mostrarMensagem('Selecione a data do torneio.');

      return;
    }

    if (_horarioSelecionado == null) {
      _mostrarMensagem('Selecione o horário do torneio.');

      return;
    }

    final usuario = UsuarioSession.usuario;

    if (usuario == null) {
      _mostrarMensagem('Usuário não identificado.');

      return;
    }

    final DateTime dataHora = DateTime(
      _dataSelecionada!.year,
      _dataSelecionada!.month,
      _dataSelecionada!.day,
      _horarioSelecionado!.hour,
      _horarioSelecionado!.minute,
    );

    setState(() {
      _salvando = true;
    });

    try {
      final torneio = await _torneioService.criarTorneio(
        nome: _nomeController.text.trim(),
        dataHora: dataHora,
        formato: _formatoSelecionado,
        quantidadeRodadas: int.parse(
          _quantidadeRodadasController.text,
        ),
        criadoPor: usuario.uid,
        sanctionId: _sanctionController.text.trim().isEmpty ? null : _sanctionController.text.trim(),
        organizadorNome: _organizadorController.text.trim().isEmpty
            ? usuario.nome : _organizadorController.text.trim(),
        organizadorPlayerId: _organizadorPlayerIdController.text.trim().isEmpty
            ? null : _organizadorPlayerIdController.text.trim(),
        tipoEvento: _tipoEvento,
        formatoJogo: _formatoJogo,
        temporada: _temporada,
        agrupamentoEtario: _agrupamento,
        tamanhoTopCut: _tamanhoTopCut,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Torneio criado com sucesso. Código: ${torneio.codigo}',
          ),
        ),
      );

      Navigator.pop(
        context,
        torneio,
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem('Não foi possível criar o torneio: $e');
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
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
    return TcgTheme.wrap(Scaffold(
      appBar: AppBar(
        title: const Text('Criar torneio'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TcgHero(title: 'Novo torneio', subtitle: 'Escolha o formato, a data e as rodadas da competição.', icon: Icons.add_circle_outline_rounded),
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do torneio',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe o nome do torneio.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _tipoEvento,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de evento', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'custom', child: Text('Torneio casual / Custom')),
                    DropdownMenuItem(value: 'league_challenge', child: Text('Desafio de Liga (League Challenge)')),
                    DropdownMenuItem(value: 'league_cup', child: Text('Copa de Liga (League Cup)')),
                    DropdownMenuItem(value: 'prerelease', child: Text('Pré-lançamento (Prerelease)')),
                  ],
                  onChanged: (v) => setState(() => _tipoEvento = v ?? 'custom'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _formatoJogo,
                  decoration: const InputDecoration(
                    labelText: 'Formato do Pokémon TCG', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'standard', child: Text('TCG Standard')),
                    DropdownMenuItem(value: 'expanded', child: Text('TCG Expanded')),
                    DropdownMenuItem(value: 'limited', child: Text('TCG Limited / Selado')),
                  ],
                  onChanged: (v) => setState(() => _formatoJogo = v ?? 'standard'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _temporada,
                  decoration: const InputDecoration(
                    labelText: 'Temporada oficial', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 2026, child: Text('2026')),
                    DropdownMenuItem(value: 2027, child: Text('2027')),
                  ],
                  onChanged: (v) => setState(() => _temporada = v ?? 2027),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _agrupamento,
                  decoration: const InputDecoration(
                    labelText: 'Divisões etárias / Pods', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'combinado', child: Text('Swiss combinado (divisões modificadas)')),
                    DropdownMenuItem(value: 'separado', child: Text('Swiss separado por divisão')),
                  ],
                  onChanged: (v) => setState(() => _agrupamento = v ?? 'combinado'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _tamanhoTopCut,
                  decoration: const InputDecoration(
                    labelText: 'Top Cut após Swiss', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Sem Top Cut')),
                    DropdownMenuItem(value: 2, child: Text('Top 2')),
                    DropdownMenuItem(value: 4, child: Text('Top 4')),
                    DropdownMenuItem(value: 8, child: Text('Top 8')),
                  ],
                  onChanged: (v) => setState(() => _tamanhoTopCut = v ?? 0),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _organizadorController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do organizador', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _organizadorPlayerIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Player ID do organizador', border: OutlineInputBorder()),
                  validator: (v) => PokemonRulebook.eventoSancionado(_tipoEvento)
                      ? PokemonRulebook.validarIdentificador(v) : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sanctionController,
                  decoration: const InputDecoration(
                    labelText: 'Sanction ID do Play! Tools', border: OutlineInputBorder()),
                  validator: (v) => PokemonRulebook.eventoSancionado(_tipoEvento) &&
                      (v == null || v.trim().isEmpty)
                      ? 'Obrigatório para evento sancionado' : null,
                ),
                const SizedBox(height: 16),
                const Text('Sanction ID não é o código interno de convite. '
                    'Para eventos oficiais, use o código emitido pelo Play! Tools.'),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                value: _formatoSelecionado,
                isExpanded: true,
                // menuWidth: 150,
                alignment: AlignmentDirectional.centerStart,
                decoration: const InputDecoration(
                  labelText: 'Formato',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'md1',
                    child: Text('MD1'),
                  ),
                  DropdownMenuItem(
                    value: 'md3',
                    child: Text('MD3'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor == null) return;

                  setState(() {
                    _formatoSelecionado = valor;
                  });
                },
              ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _quantidadeRodadasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de rodadas',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe a quantidade de rodadas.';
                    }

                    final quantidade = int.tryParse(valor);

                    if (quantidade == null || quantidade <= 0) {
                      return 'Informe uma quantidade válida.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _selecionarData,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    _dataSelecionada == null
                        ? 'Selecionar data'
                        : '${_dataSelecionada!.day.toString().padLeft(2, '0')}/'
                            '${_dataSelecionada!.month.toString().padLeft(2, '0')}/'
                            '${_dataSelecionada!.year}',
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _selecionarHorario,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    _horarioSelecionado == null
                        ? 'Selecionar horário'
                        : _horarioSelecionado!.format(context),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  child: _salvando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Criar torneio',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}