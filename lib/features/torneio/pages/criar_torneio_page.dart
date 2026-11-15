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
  static const int _totalPassos = 3;
  static const int _maxRodadas = 20;

  static const Map<String, String> _nomesFormatoJogo = {
    'standard': 'Standard',
    'expanded': 'Expanded',
    'limited': 'Limited / Selado',
  };

  static const Map<int, String> _nomesTopCut = {
    0: 'Sem Top Cut',
    2: 'Top 2',
    4: 'Top 4',
    8: 'Top 8',
  };

  final _formEventoKey = GlobalKey<FormState>();
  final _formOrganizacaoKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _sanctionController = TextEditingController();
  final _organizadorController = TextEditingController();
  final _organizadorPlayerIdController = TextEditingController();

  final TorneioService _torneioService = TorneioService();

  int _passo = 0;

  String _tipoEvento = 'custom';
  String _formatoJogo = 'standard';
  String _agrupamento = 'combinado';
  int _temporada = PokemonRulebook.temporadaAtual;
  int _tamanhoTopCut = 0;
  String _formatoSelecionado = 'md3';
  int _rodadas = 3;

  DateTime? _dataSelecionada;
  TimeOfDay? _horarioSelecionado;

  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _sanctionController.dispose();
    _organizadorController.dispose();
    _organizadorPlayerIdController.dispose();

    super.dispose();
  }

  // ============================================================
  // Navegação entre passos
  // ============================================================

  void _continuar() {
    FocusScope.of(context).unfocus();

    if (_passo == 0) {
      if (!_formEventoKey.currentState!.validate()) return;
      setState(() => _passo = 1);
    } else if (_passo == 1) {
      setState(() => _passo = 2);
    } else {
      _salvar();
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
  // Dados
  // ============================================================

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
      initialTime: _horarioSelecionado ?? TimeOfDay.now(),
    );

    if (horario == null || !mounted) return;

    setState(() => _horarioSelecionado = horario);
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    if (!_formOrganizacaoKey.currentState!.validate()) return;

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
        quantidadeRodadas: _rodadas,
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

  // ============================================================
  // Peças de layout
  // ============================================================

  Widget _rotulo(String texto) {
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

  Widget _tipoTile(
    String valor,
    IconData icone,
    String titulo,
    String subtitulo,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _OpcaoTile(
        icone: icone,
        titulo: titulo,
        subtitulo: subtitulo,
        selo: PokemonRulebook.eventoSancionado(valor) ? 'Sancionado' : null,
        selecionado: _tipoEvento == valor,
        onTap: () => setState(() => _tipoEvento = valor),
      ),
    );
  }

  // ============================================================
  // Passo 1: Evento
  // ============================================================

  Widget _passoEvento() {
    return Form(
      key: _formEventoKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalhoPasso(
            'Vamos começar',
            'Dê um nome e escolha o tipo do evento.',
          ),

          TextFormField(
            controller: _nomeController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Nome do torneio'),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Informe o nome do torneio.';
              }

              return null;
            },
          ),
          const SizedBox(height: 28),

          _rotulo('Tipo de evento'),
          _tipoTile(
            'custom',
            Icons.groups_outlined,
            'Casual / Custom',
            'Torneio livre entre amigos',
          ),
          _tipoTile(
            'league_challenge',
            Icons.emoji_events_outlined,
            'Desafio de Liga',
            'League Challenge',
          ),
          _tipoTile(
            'league_cup',
            Icons.military_tech_outlined,
            'Copa de Liga',
            'League Cup',
          ),
          _tipoTile(
            'prerelease',
            Icons.new_releases_outlined,
            'Pré-lançamento',
            'Prerelease',
          ),
          const SizedBox(height: 18),

          _rotulo('Formato do Pokémon TCG'),
          _Pilulas<String>(
            valor: _formatoJogo,
            opcoes: _nomesFormatoJogo,
            onChanged: (v) => setState(() => _formatoJogo = v),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Passo 2: Regras
  // ============================================================

  Widget _passoRegras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabecalhoPasso(
          'Regras da competição',
          'Defina a temporada, as partidas e as rodadas.',
        ),

        _rotulo('Temporada oficial'),
        _Pilulas<int>(
          valor: _temporada,
          opcoes: const {2026: '2026', 2027: '2027'},
          onChanged: (v) => setState(() => _temporada = v),
        ),
        const SizedBox(height: 28),

        _rotulo('Formato das partidas'),
        _Pilulas<String>(
          valor: _formatoSelecionado,
          opcoes: const {'md1': 'MD1', 'md3': 'MD3'},
          onChanged: (v) => setState(() => _formatoSelecionado = v),
        ),
        const SizedBox(height: 28),

        _rotulo('Rodadas Swiss'),
        _Contador(
          valor: _rodadas,
          onMenos: _rodadas > 1 ? () => setState(() => _rodadas--) : null,
          onMais:
              _rodadas < _maxRodadas ? () => setState(() => _rodadas++) : null,
        ),
        const SizedBox(height: 28),

        _rotulo('Divisões etárias / Pods'),
        _OpcaoTile(
          icone: Icons.merge_type_rounded,
          titulo: 'Swiss combinado',
          subtitulo: 'Divisões modificadas',
          selecionado: _agrupamento == 'combinado',
          onTap: () => setState(() => _agrupamento = 'combinado'),
        ),
        const SizedBox(height: 10),
        _OpcaoTile(
          icone: Icons.call_split_rounded,
          titulo: 'Swiss separado',
          subtitulo: 'Separado por divisão',
          selecionado: _agrupamento == 'separado',
          onTap: () => setState(() => _agrupamento = 'separado'),
        ),
        const SizedBox(height: 28),

        _rotulo('Top Cut após o Swiss'),
        _Pilulas<int>(
          valor: _tamanhoTopCut,
          opcoes: _nomesTopCut,
          onChanged: (v) => setState(() => _tamanhoTopCut = v),
        ),
      ],
    );
  }

  // ============================================================
  // Passo 3: Data e organização
  // ============================================================

  Widget _passoFinal() {
    final sancionado = PokemonRulebook.eventoSancionado(_tipoEvento);

    final nome = _nomeController.text.trim();
    final dataPrevia = _dataSelecionada ?? DateTime.now();
    final horaPrevia = _horarioSelecionado ?? TimeOfDay.now();

    final dataHoraPrevia = DateTime(
      dataPrevia.year,
      dataPrevia.month,
      dataPrevia.day,
      horaPrevia.hour,
      horaPrevia.minute,
    );

    final resumo = [
      _nomesFormatoJogo[_formatoJogo] ?? _formatoJogo,
      'Temporada $_temporada',
      '$_rodadas ${_rodadas == 1 ? 'rodada' : 'rodadas'}',
      _nomesTopCut[_tamanhoTopCut] ?? 'Sem Top Cut',
    ].join('  •  ');

    return Form(
      key: _formOrganizacaoKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalhoPasso(
            'Quase pronto',
            'Escolha quando acontece e quem organiza.',
          ),

          // ===== Pré-visualização =====
          _rotulo('Como os jogadores vão ver'),
          IgnorePointer(
            child: TcgTournamentTile(
              nome: nome.isEmpty ? 'Nome do torneio' : nome,
              data: dataHoraPrevia,
              formato: _formatoSelecionado,
              status: 'inscricoes',
              onTap: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: Text(
              resumo,
              style: const TextStyle(
                color: TcgTheme.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ===== Data e horário =====
          _rotulo('Data e horário'),
          Row(
            children: [
              Expanded(
                child: _CampoSelecao(
                  label: 'Data',
                  valor: _dataSelecionada == null
                      ? null
                      : _formatarData(_dataSelecionada!),
                  vazio: 'Selecionar',
                  icone: Icons.calendar_month,
                  onTap: _selecionarData,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CampoSelecao(
                  label: 'Horário',
                  valor: _horarioSelecionado?.format(context),
                  vazio: 'Selecionar',
                  icone: Icons.access_time,
                  onTap: _selecionarHorario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ===== Organização =====
          _rotulo('Organização'),

          if (sancionado) ...[
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
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFFFFB74D),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Evento sancionado: o Player ID do organizador e o '
                      'Sanction ID são obrigatórios.',
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
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _organizadorController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nome do organizador',
              helperText: 'Em branco, usa o seu nome.',
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _organizadorPlayerIdController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText:
                  'Player ID do organizador${sancionado ? ' *' : ''}',
            ),
            validator: (v) =>
                sancionado ? PokemonRulebook.validarIdentificador(v) : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _sanctionController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Sanction ID do Play! Tools${sancionado ? ' *' : ''}',
            ),
            validator: (v) => sancionado && (v == null || v.trim().isEmpty)
                ? 'Obrigatório para evento sancionado'
                : null,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sanction ID não é o código interno de convite. Para eventos '
            'oficiais, use o código emitido pelo Play! Tools.',
            style: TextStyle(color: TcgTheme.muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _conteudoPasso() {
    switch (_passo) {
      case 0:
        return _passoEvento();
      case 1:
        return _passoRegras();
      default:
        return _passoFinal();
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
                          onPressed: _salvando ? null : _voltarPasso,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Novo torneio',
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
                                onPressed: _salvando ? null : _voltarPasso,
                                child: const Text('Voltar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: TcgGradientButton(
                              texto:
                                  ultimoPasso ? 'Criar torneio' : 'Continuar',
                              icone: ultimoPasso
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              carregando: _salvando,
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

// ============================================================
// Componentes
// ============================================================

/// Cartão selecionável com ícone, título e subtítulo.
class _OpcaoTile extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final String? selo;
  final bool selecionado;
  final VoidCallback onTap;

  const _OpcaoTile({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.selecionado,
    required this.onTap,
    this.selo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selecionado
              ? const Color(0x1F3DDC84)
              : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selecionado ? TcgTheme.verde : const Color(0x26FFFFFF),
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selecionado
                    ? TcgTheme.verde
                    : const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icone,
                color: selecionado ? TcgTheme.fundo : Colors.white70,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (selo != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x26FFB74D),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            selo!,
                            style: const TextStyle(
                              color: Color(0xFFFFB74D),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: TcgTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selecionado
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: selecionado ? TcgTheme.verde : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opções curtas em formato de pílula.
class _Pilulas<T> extends StatelessWidget {
  final T valor;
  final Map<T, String> opcoes;
  final ValueChanged<T> onChanged;

  const _Pilulas({
    required this.valor,
    required this.opcoes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opcoes.entries.map((e) {
        final sel = e.key == valor;

        return GestureDetector(
          onTap: () => onChanged(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: sel
                  ? const Color(0x263DDC84)
                  : const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: sel ? TcgTheme.verde : const Color(0x26FFFFFF),
              ),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                color: sel ? TcgTheme.verde : Colors.white70,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Contador com botões − e +.
class _Contador extends StatelessWidget {
  final int valor;
  final VoidCallback? onMenos;
  final VoidCallback? onMais;

  const _Contador({
    required this.valor,
    required this.onMenos,
    required this.onMais,
  });

  Widget _botao(IconData icone, VoidCallback? onTap) {
    final ativo = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ativo ? const Color(0x2E3DDC84) : const Color(0x0DFFFFFF),
        ),
        child: Icon(
          icone,
          color: ativo ? TcgTheme.verde : Colors.white24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _botao(Icons.remove, onMenos),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$valor',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                valor == 1 ? 'rodada' : 'rodadas',
                style: const TextStyle(color: TcgTheme.muted, fontSize: 12),
              ),
            ],
          ),
          _botao(Icons.add, onMais),
        ],
      ),
    );
  }
}

/// Campo que abre um seletor (data, horário).
class _CampoSelecao extends StatelessWidget {
  final String label;
  final String? valor;
  final String vazio;
  final IconData icone;
  final VoidCallback onTap;

  const _CampoSelecao({
    required this.label,
    required this.valor,
    required this.vazio,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icone, size: 20),
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
}