import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';

import '../../jogador/models/jogador_torneio_model.dart';
import '../models/partida_model.dart';
import '../services/rodada_service.dart';

class MontarPrimeiraRodadaPage extends StatefulWidget {
  final String torneioId;
  final String nomeTorneio;

  const MontarPrimeiraRodadaPage({
    super.key,
    required this.torneioId,
    required this.nomeTorneio,
  });

  @override
  State<MontarPrimeiraRodadaPage> createState() =>
      _MontarPrimeiraRodadaPageState();
}

class _MontarPrimeiraRodadaPageState extends State<MontarPrimeiraRodadaPage> {
  static const Color _amarelo = Color(0xFFFFB74D);
  static const Color _vermelho = Color(0xFFFF6B6B);

  final RodadaService _service = RodadaService();

  List<JogadorTorneioModel> _jogadores = [];

  final List<_ConfrontoSelecionado> _confrontos = [];

  JogadorTorneioModel? _bye;

  bool _carregando = true;
  bool _erroCarregar = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();

    _carregar();
  }

  // ============================================================
  // Lógica
  // ============================================================

  Future<void> _carregar() async {
    try {
      final jogadores = await _service.listarJogadoresAprovados(
        widget.torneioId,
      );

      if (!mounted) return;

      setState(() {
        _jogadores = jogadores;
        _carregando = false;
        _erroCarregar = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erroCarregar = true;
      });

      _mostrarMensagem('Não foi possível carregar os jogadores.');
    }
  }

  List<JogadorTorneioModel> _jogadoresDisponiveis() {
    final usados = <String>{};

    for (final confronto in _confrontos) {
      usados.add(confronto.jogador1.uid);
      usados.add(confronto.jogador2.uid);
    }

    if (_bye != null) {
      usados.add(_bye!.uid);
    }

    return _jogadores.where((jogador) => !usados.contains(jogador.uid)).toList();
  }

  int get _alocados => _confrontos.length * 2 + (_bye != null ? 1 : 0);

  Future<void> _adicionarConfronto() async {
    final disponiveis = _jogadoresDisponiveis();

    if (disponiveis.length < 2) {
      _mostrarMensagem('Não existem jogadores suficientes disponíveis.');

      return;
    }

    JogadorTorneioModel? jogador1;
    JogadorTorneioModel? jogador2;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Theme(
          data: TcgTheme.data(),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Novo confronto'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<JogadorTorneioModel>(
                        value: jogador1,
                        isExpanded: true,
                        dropdownColor: TcgTheme.card,
                        decoration: const InputDecoration(
                          labelText: 'Jogador 1',
                        ),
                        items: disponiveis
                            .map(
                              (jogador) => DropdownMenuItem(
                                value: jogador,
                                child: Text(
                                  jogador.nome,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (valor) {
                          setDialogState(() {
                            jogador1 = valor;

                            if (jogador2?.uid == jogador1?.uid) {
                              jogador2 = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<JogadorTorneioModel>(
                        value: jogador2,
                        isExpanded: true,
                        dropdownColor: TcgTheme.card,
                        decoration: const InputDecoration(
                          labelText: 'Jogador 2',
                        ),
                        items: disponiveis
                            .where((jogador) => jogador.uid != jogador1?.uid)
                            .map(
                              (jogador) => DropdownMenuItem(
                                value: jogador,
                                child: Text(
                                  jogador.nome,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (valor) {
                          setDialogState(() {
                            jogador2 = valor;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: jogador1 == null || jogador2 == null
                        ? null
                        : () {
                            Navigator.pop(context, true);
                          },
                    child: const Text('Adicionar'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (confirmou != true || jogador1 == null || jogador2 == null) {
      return;
    }

    setState(() {
      _confrontos.add(
        _ConfrontoSelecionado(jogador1: jogador1!, jogador2: jogador2!),
      );
    });
  }

  Future<void> _definirBye() async {
    final disponiveis = _jogadoresDisponiveis();

    if (disponiveis.isEmpty) {
      _mostrarMensagem('Nenhum jogador disponível.');

      return;
    }

    JogadorTorneioModel? selecionado;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Theme(
          data: TcgTheme.data(),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Selecionar BYE'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: DropdownButtonFormField<JogadorTorneioModel>(
                    value: selecionado,
                    isExpanded: true,
                    dropdownColor: TcgTheme.card,
                    decoration: const InputDecoration(labelText: 'Jogador'),
                    items: disponiveis
                        .map(
                          (jogador) => DropdownMenuItem(
                            value: jogador,
                            child: Text(
                              jogador.nome,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setDialogState(() {
                        selecionado = valor;
                      });
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: selecionado == null
                        ? null
                        : () {
                            Navigator.pop(context, true);
                          },
                    child: const Text('Confirmar'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (confirmou != true || selecionado == null) {
      return;
    }

    setState(() {
      _bye = selecionado;
    });
  }

  void _removerConfronto(int index) {
    setState(() {
      _confrontos.removeAt(index);
    });
  }

  Future<void> _iniciarRodada() async {
    final disponiveis = _jogadoresDisponiveis();

    if (disponiveis.isNotEmpty) {
      _mostrarMensagem(
        'Todos os jogadores precisam estar em uma partida ou receber BYE.',
      );

      return;
    }

    if (_jogadores.length.isOdd && _bye == null) {
      _mostrarMensagem('Selecione um jogador para receber BYE.');

      return;
    }

    if (_jogadores.length.isEven && _bye != null) {
      _mostrarMensagem(
        'Não é necessário BYE com quantidade par de jogadores.',
      );

      return;
    }

    final List<PartidaModel> partidas = [];

    for (int i = 0; i < _confrontos.length; i++) {
      final confronto = _confrontos[i];

      partidas.add(
        PartidaModel(
          id: '',
          mesa: i + 1,
          jogador1Uid: confronto.jogador1.uid,
          jogador1Nome: confronto.jogador1.nome,
          jogador2Uid: confronto.jogador2.uid,
          jogador2Nome: confronto.jogador2.nome,
          status: 'em_andamento',
          placarJogador1: 0,
          placarJogador2: 0,
          bye: false,
        ),
      );
    }

    if (_bye != null) {
      partidas.add(
        PartidaModel(
          id: '',
          mesa: _confrontos.length + 1,
          jogador1Uid: _bye!.uid,
          jogador1Nome: _bye!.nome,
          jogador2Uid: null,
          jogador2Nome: null,
          status: 'finalizada',
          placarJogador1: 0,
          placarJogador2: 0,
          bye: true,
        ),
      );
    }

    setState(() {
      _salvando = true;
    });

    try {
      await _service.salvarPrimeiraRodada(
        torneioId: widget.torneioId,
        partidas: partidas,
      );

      if (!mounted) return;

      _mostrarMensagem('Rodada iniciada com sucesso.');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem('Não foi possível iniciar a rodada.');
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  Future<void> _gerarAutomaticamente() async {
    if (_confrontos.isNotEmpty || _bye != null) {
      _mostrarMensagem(
        'Remova os confrontos manuais antes de gerar automaticamente.',
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final retorno = await _service.gerarPrimeiraRodadaAutomatica(
        torneioId: widget.torneioId,
      );
      if (!mounted) return;
      if (retorno == 'ok') {
        _mostrarMensagem('Pareamentos Swiss criados. Revise antes de iniciar.');
        Navigator.pop(context, true);
      } else {
        _mostrarMensagem('Não foi possível gerar: $retorno');
      }
    } catch (e) {
      if (mounted) _mostrarMensagem('Erro ao gerar os confrontos: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  // ============================================================
  // Peças de layout
  // ============================================================

  Widget _rotulo(String texto, {int? quantidade}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            texto.toUpperCase(),
            style: const TextStyle(
              color: TcgTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          if (quantidade != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: TcgTheme.verde.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$quantidade',
                style: const TextStyle(
                  color: TcgTheme.verde,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return TcgGlassCard(
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
              Icons.account_tree_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Montar Rodada 1',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.nomeTorneio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.groups, size: 16, color: TcgTheme.verde),
                const SizedBox(width: 7),
                Text(
                  '${_jogadores.length} jogadores aprovados',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoAutomatico() {
    return TcgGlassCard(
      onTap: _salvando ? null : _gerarAutomaticamente,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0x1F3DDC84),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shuffle_rounded, color: TcgTheme.verde),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gerar automaticamente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pareamentos suíços. Você revisa antes de iniciar.',
                  style: TextStyle(
                    color: TcgTheme.muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _salvando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _separadorOu() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'OU MONTE MANUALMENTE',
              style: TextStyle(
                color: TcgTheme.muted,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _cartaMesa(int index, _ConfrontoSelecionado c) {
    return TcgGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x263DDC84),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'MESA ${index + 1}',
                  style: const TextStyle(
                    color: TcgTheme.verde,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Remover confronto',
                onPressed: _salvando ? null : () => _removerConfronto(index),
                icon: const Icon(Icons.delete_outline, color: Colors.white54),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _JogadorMesa(nome: c.jogador1.nome),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1AFFFFFF),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                _JogadorMesa(nome: c.jogador2.nome),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaBye(JogadorTorneioModel jogador) {
    return TcgGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          _AvatarMini(nome: jogador.nome, tamanho: 44, cor: _amarelo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jogador.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _amarelo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BYE',
                    style: TextStyle(
                      color: _amarelo,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remover BYE',
            onPressed: _salvando
                ? null
                : () {
                    setState(() {
                      _bye = null;
                    });
                  },
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _vazioConfrontos() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.table_restaurant_outlined, size: 44, color: Colors.white24),
          SizedBox(height: 12),
          Text(
            'Nenhum confronto configurado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TcgTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _faltamAlocar(List<JogadorTorneioModel> disponiveis) {
    if (disponiveis.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TcgTheme.verde.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TcgTheme.verde.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: TcgTheme.verde),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Todos os jogadores alocados.',
                style: TextStyle(color: TcgTheme.verde, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _rotulo('Faltam alocar', quantidade: disponiveis.length),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: disponiveis
              .map(
                (j) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _amarelo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border:
                        Border.all(color: _amarelo.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    j.nome,
                    style: const TextStyle(
                      color: _amarelo,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erroCarregar) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 44, color: Colors.white24),
              const SizedBox(height: 12),
              const Text(
                'Não foi possível carregar os jogadores.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TcgTheme.muted),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 220,
                child: TcgGradientButton(
                  texto: 'Tentar novamente',
                  icone: Icons.refresh_rounded,
                  onPressed: () {
                    setState(() {
                      _carregando = true;
                      _erroCarregar = false;
                    });
                    _carregar();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    final disponiveis = _jogadoresDisponiveis();

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cabecalho(),
              const SizedBox(height: 20),

              _cartaoAutomatico(),
              _separadorOu(),

              _rotulo('Confrontos', quantidade: _confrontos.length),

              if (_confrontos.isEmpty && _bye == null)
                _vazioConfrontos()
              else ...[
                ...List.generate(
                  _confrontos.length,
                  (i) => _cartaMesa(i, _confrontos[i]),
                ),
                if (_bye != null) _cartaBye(_bye!),
              ],

              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: _salvando ? null : _adicionarConfronto,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar confronto'),
              ),

              if (_jogadores.length.isOdd && _bye == null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _salvando ? null : _definirBye,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Selecionar BYE'),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Número ímpar de jogadores: um deles receberá BYE.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TcgTheme.muted, fontSize: 12),
                  ),
                ),
              ],

              _faltamAlocar(disponiveis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rodape() {
    final total = _jogadores.length;
    final fracao = total == 0 ? 0.0 : (_alocados / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xCC14142B),
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$_alocados de $total jogadores alocados',
                      style: const TextStyle(
                        color: TcgTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${(fracao * 100).round()}%',
                    style: const TextStyle(
                      color: TcgTheme.verde,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fracao,
                  minHeight: 5,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(TcgTheme.verde),
                ),
              ),
              const SizedBox(height: 12),
              TcgGradientButton(
                texto: 'Iniciar rodada',
                icone: Icons.play_arrow,
                carregando: _salvando,
                onPressed: _iniciarRodada,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final mostrarRodape = !_carregando && !_erroCarregar;

    return TcgTheme.wrap(
      Scaffold(
        backgroundColor: TcgTheme.fundo,
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
                Expanded(child: _corpo()),

                // Barra fixa embaixo
                if (mostrarRodape) _rodape(),
              ],
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

class _ConfrontoSelecionado {
  final JogadorTorneioModel jogador1;
  final JogadorTorneioModel jogador2;

  _ConfrontoSelecionado({
    required this.jogador1,
    required this.jogador2,
  });
}

/// Jogador dentro do cartão da mesa (avatar + nome).
class _JogadorMesa extends StatelessWidget {
  final String nome;

  const _JogadorMesa({required this.nome});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          _AvatarMini(nome: nome, tamanho: 56, cor: TcgTheme.verde),
          const SizedBox(height: 10),
          Text(
            nome,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar com iniciais (pronto para receber foto).
class _AvatarMini extends StatelessWidget {
  final String nome;
  final double tamanho;
  final Color cor;

  /// Quando existir foto de perfil, é só passar a URL aqui.
  final String? fotoUrl;

  const _AvatarMini({
    required this.nome,
    required this.tamanho,
    required this.cor,
    this.fotoUrl,
  });

  String get _iniciais {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();

    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  Widget _texto() {
    return Text(
      _iniciais,
      style: TextStyle(
        color: Colors.white,
        fontSize: tamanho * 0.36,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoUrl != null && fotoUrl!.isNotEmpty;

    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor.withValues(alpha: 0.18),
        border: Border.all(color: cor, width: 2),
      ),
      child: temFoto
          ? ClipOval(
              child: Image.network(
                fotoUrl!,
                width: tamanho,
                height: tamanho,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _texto(),
              ),
            )
          : _texto(),
    );
  }
}