import 'package:flutter/material.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';

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

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _selecionarData() async {
    FocusScope.of(context).unfocus();

    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );

    if (data != null && mounted) {
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _selecionarHorario() async {
    FocusScope.of(context).unfocus();

    final TimeOfDay? horario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (horario == null || !mounted) return;

    setState(() => _horarioSelecionado = horario);
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    if (!_formKey.currentState!.validate()) return;

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

    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);

    try {
      final torneio = await _torneioService.criarTorneio(
        nome: _nomeController.text.trim(),
        dataHora: dataHora,
        formato: _formatoSelecionado,
        quantidadeRodadas: int.parse(_quantidadeRodadasController.text),
        criadoPor: usuario.uid,
        sanctionId: _sanctionController.text.trim().isEmpty
            ? null
            : _sanctionController.text.trim(),
        organizadorNome: _organizadorController.text.trim().isEmpty
            ? usuario.nome
            : _organizadorController.text.trim(),
        organizadorPlayerId: _organizadorPlayerIdController.text.trim().isEmpty
            ? null
            : _organizadorPlayerIdController.text.trim(),
        tipoEvento: _tipoEvento,
        formatoJogo: _formatoJogo,
        temporada: _temporada,
        agrupamentoEtario: _agrupamento,
        tamanhoTopCut: _tamanhoTopCut,
      );

      if (!mounted) return;

      _mostrarMensagem('Torneio criado com sucesso. Código: ${torneio.codigo}');

      Navigator.pop(context, torneio);
    } catch (e) {
      _mostrarMensagem('Não foi possível criar o torneio: $e');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  // ===== Widgets auxiliares =====

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: TcgTheme.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      dropdownColor: TcgTheme.card,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _campoSelecao({
    required String label,
    required String? valor,
    required String vazio,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icone),
        ),
        child: Text(
          valor ?? vazio,
          style: TextStyle(
            color: valor == null ? Colors.white38 : Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sancionado = PokemonRulebook.eventoSancionado(_tipoEvento);

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
                                      Icons.add_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Novo torneio',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Escolha o formato, a data e as rodadas '
                                    'da competição.',
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _titulo('Evento'),

                                  TextFormField(
                                    controller: _nomeController,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome do torneio',
                                    ),
                                    validator: (valor) {
                                      if (valor == null ||
                                          valor.trim().isEmpty) {
                                        return 'Informe o nome do torneio.';
                                      }

                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  _dropdown<String>(
                                    label: 'Tipo de evento',
                                    value: _tipoEvento,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'custom',
                                        child: Text('Torneio casual / Custom'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'league_challenge',
                                        child: Text(
                                          'Desafio de Liga (League Challenge)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'league_cup',
                                        child: Text(
                                          'Copa de Liga (League Cup)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'prerelease',
                                        child: Text(
                                          'Pré-lançamento (Prerelease)',
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) => setState(
                                      () => _tipoEvento = v ?? 'custom',
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  _dropdown<String>(
                                    label: 'Formato do Pokémon TCG',
                                    value: _formatoJogo,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'standard',
                                        child: Text('TCG Standard'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'expanded',
                                        child: Text('TCG Expanded'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'limited',
                                        child: Text('TCG Limited / Selado'),
                                      ),
                                    ],
                                    onChanged: (v) => setState(
                                      () => _formatoJogo = v ?? 'standard',
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  _dropdown<int>(
                                    label: 'Temporada oficial',
                                    value: _temporada,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 2026,
                                        child: Text('2026'),
                                      ),
                                      DropdownMenuItem(
                                        value: 2027,
                                        child: Text('2027'),
                                      ),
                                    ],
                                    onChanged: (v) => setState(
                                      () => _temporada = v ?? 2027,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  _dropdown<String>(
                                    label: 'Divisões etárias / Pods',
                                    value: _agrupamento,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'combinado',
                                        child: Text(
                                          'Swiss combinado (divisões modificadas)',
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'separado',
                                        child: Text(
                                          'Swiss separado por divisão',
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) => setState(
                                      () => _agrupamento = v ?? 'combinado',
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  _dropdown<int>(
                                    label: 'Top Cut após Swiss',
                                    value: _tamanhoTopCut,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 0,
                                        child: Text('Sem Top Cut'),
                                      ),
                                      DropdownMenuItem(
                                        value: 2,
                                        child: Text('Top 2'),
                                      ),
                                      DropdownMenuItem(
                                        value: 4,
                                        child: Text('Top 4'),
                                      ),
                                      DropdownMenuItem(
                                        value: 8,
                                        child: Text('Top 8'),
                                      ),
                                    ],
                                    onChanged: (v) => setState(
                                      () => _tamanhoTopCut = v ?? 0,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  _titulo('Organização'),

                                  TextFormField(
                                    controller: _organizadorController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome do organizador',
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  TextFormField(
                                    controller: _organizadorPlayerIdController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Player ID do organizador',
                                    ),
                                    validator: (v) => sancionado
                                        ? PokemonRulebook.validarIdentificador(v)
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  TextFormField(
                                    controller: _sanctionController,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Sanction ID do Play! Tools',
                                    ),
                                    validator: (v) => sancionado &&
                                            (v == null || v.trim().isEmpty)
                                        ? 'Obrigatório para evento sancionado'
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Sanction ID não é o código interno de '
                                    'convite. Para eventos oficiais, use o '
                                    'código emitido pelo Play! Tools.',
                                    style: TextStyle(
                                      color: TcgTheme.muted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  _titulo('Partidas'),

                                  _dropdown<String>(
                                    label: 'Formato',
                                    value: _formatoSelecionado,
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

                                      setState(
                                        () => _formatoSelecionado = valor,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  TextFormField(
                                    controller: _quantidadeRodadasController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    decoration: const InputDecoration(
                                      labelText: 'Quantidade de rodadas',
                                    ),
                                    validator: (valor) {
                                      if (valor == null ||
                                          valor.trim().isEmpty) {
                                        return 'Informe a quantidade de rodadas.';
                                      }

                                      final quantidade = int.tryParse(valor);

                                      if (quantidade == null ||
                                          quantidade <= 0) {
                                        return 'Informe uma quantidade válida.';
                                      }

                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 28),

                                  _titulo('Data e horário'),

                                  _campoSelecao(
                                    label: 'Data',
                                    valor: _dataSelecionada == null
                                        ? null
                                        : _formatarData(_dataSelecionada!),
                                    vazio: 'Selecionar data',
                                    icone: Icons.calendar_month,
                                    onTap: _selecionarData,
                                  ),
                                  const SizedBox(height: 16),

                                  _campoSelecao(
                                    label: 'Horário',
                                    valor: _horarioSelecionado?.format(context),
                                    vazio: 'Selecionar horário',
                                    icone: Icons.access_time,
                                    onTap: _selecionarHorario,
                                  ),
                                  const SizedBox(height: 28),

                                  TcgGradientButton(
                                    texto: 'Criar torneio',
                                    carregando: _salvando,
                                    onPressed: _salvar,
                                  ),
                                ],
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