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

class _MontarPrimeiraRodadaPageState
    extends State<MontarPrimeiraRodadaPage> {
  final RodadaService _service =
      RodadaService();

  List<JogadorTorneioModel> _jogadores = [];

  final List<_ConfrontoSelecionado> _confrontos = [];

  JogadorTorneioModel? _bye;

  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();

    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final jogadores =
          await _service.listarJogadoresAprovados(
        widget.torneioId,
      );

      if (!mounted) return;

      setState(() {
        _jogadores = jogadores;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        'Não foi possível carregar os jogadores.',
      );
    }
  }

  List<JogadorTorneioModel>
      _jogadoresDisponiveis() {
    final usados = <String>{};

    for (final confronto in _confrontos) {
      usados.add(confronto.jogador1.uid);
      usados.add(confronto.jogador2.uid);
    }

    if (_bye != null) {
      usados.add(_bye!.uid);
    }

    return _jogadores
        .where(
          (jogador) =>
              !usados.contains(jogador.uid),
        )
        .toList();
  }

  Future<void> _adicionarConfronto() async {
    final disponiveis =
        _jogadoresDisponiveis();

    if (disponiveis.length < 2) {
      _mostrarMensagem(
        'Não existem jogadores suficientes disponíveis.',
      );

      return;
    }

    JogadorTorneioModel? jogador1;
    JogadorTorneioModel? jogador2;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Novo confronto',
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  DropdownButtonFormField<
                      JogadorTorneioModel>(
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Jogador 1',
                    ),
                    items: disponiveis
                        .map(
                          (jogador) =>
                              DropdownMenuItem(
                            value: jogador,
                            child: Text(
                              jogador.nome,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setDialogState(() {
                        jogador1 = valor;

                        if (jogador2?.uid ==
                            jogador1?.uid) {
                          jogador2 = null;
                        }
                      });
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  DropdownButtonFormField<
                      JogadorTorneioModel>(
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Jogador 2',
                    ),
                    items: disponiveis
                        .where(
                          (jogador) =>
                              jogador.uid !=
                              jogador1?.uid,
                        )
                        .map(
                          (jogador) =>
                              DropdownMenuItem(
                            value: jogador,
                            child: Text(
                              jogador.nome,
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
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      false,
                    );
                  },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (jogador1 == null ||
                        jogador2 == null) {
                      return;
                    }

                    Navigator.pop(
                      context,
                      true,
                    );
                  },
                  child: const Text(
                    'Adicionar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmou != true ||
        jogador1 == null ||
        jogador2 == null) {
      return;
    }

    setState(() {
      _confrontos.add(
        _ConfrontoSelecionado(
          jogador1: jogador1!,
          jogador2: jogador2!,
        ),
      );
    });
  }

  Future<void> _definirBye() async {
    final disponiveis =
        _jogadoresDisponiveis();

    if (disponiveis.isEmpty) {
      _mostrarMensagem(
        'Nenhum jogador disponível.',
      );

      return;
    }

    JogadorTorneioModel? selecionado;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Selecionar BYE',
              ),
              content:
                  DropdownButtonFormField<
                      JogadorTorneioModel>(
                decoration:
                    const InputDecoration(
                  labelText: 'Jogador',
                ),
                items: disponiveis
                    .map(
                      (jogador) =>
                          DropdownMenuItem(
                        value: jogador,
                        child: Text(
                          jogador.nome,
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
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      false,
                    );
                  },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selecionado == null) {
                      return;
                    }

                    Navigator.pop(
                      context,
                      true,
                    );
                  },
                  child: const Text(
                    'Confirmar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmou != true ||
        selecionado == null) {
      return;
    }

    setState(() {
      _bye = selecionado;
    });
  }

  void _removerConfronto(
    int index,
  ) {
    setState(() {
      _confrontos.removeAt(index);
    });
  }

  Future<void> _iniciarRodada() async {
    final disponiveis =
        _jogadoresDisponiveis();

    if (disponiveis.isNotEmpty) {
      _mostrarMensagem(
        'Todos os jogadores precisam estar em uma partida ou receber BYE.',
      );

      return;
    }

    if (_jogadores.length.isOdd &&
        _bye == null) {
      _mostrarMensagem(
        'Selecione um jogador para receber BYE.',
      );

      return;
    }

    if (_jogadores.length.isEven &&
        _bye != null) {
      _mostrarMensagem(
        'Não é necessário BYE com quantidade par de jogadores.',
      );

      return;
    }

    final List<PartidaModel> partidas =
        [];

    for (int i = 0;
        i < _confrontos.length;
        i++) {
      final confronto =
          _confrontos[i];

      partidas.add(
        PartidaModel(
          id: '',
          mesa: i + 1,
          jogador1Uid:
              confronto.jogador1.uid,
          jogador1Nome:
              confronto.jogador1.nome,
          jogador2Uid:
              confronto.jogador2.uid,
          jogador2Nome:
              confronto.jogador2.nome,
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
          mesa:
              _confrontos.length + 1,
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
        torneioId:
            widget.torneioId,
        partidas: partidas,
      );

      if (!mounted) return;

      _mostrarMensagem(
        'Rodada iniciada com sucesso.',
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível iniciar a rodada.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  void _mostrarMensagem(
    String mensagem,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Montar Rodada 1',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Text(
            widget.nomeTorneio,
            style:
                Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          Text(
            '${_jogadores.length} jogadores aprovados',
          ),

          const SizedBox(height: 24),

          if (_confrontos.isEmpty)
            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(20),
                child: Text(
                  'Nenhum confronto configurado.',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            )
          else
            ...List.generate(
              _confrontos.length,
              (index) {
                final confronto =
                    _confrontos[index];

                return Card(
                  child: ListTile(
                    leading:
                        CircleAvatar(
                      child: Text(
                        '${index + 1}',
                      ),
                    ),
                    title: Text(
                      '${confronto.jogador1.nome} x ${confronto.jogador2.nome}',
                    ),
                    subtitle: Text(
                      'Mesa ${index + 1}',
                    ),
                    trailing:
                        IconButton(
                      onPressed: () =>
                          _removerConfronto(
                        index,
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                    ),
                  ),
                );
              },
            ),

          if (_bye != null) ...[
            const SizedBox(height: 8),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.skip_next,
                ),
                title: Text(
                  _bye!.nome,
                ),
                subtitle:
                    const Text(
                  'BYE',
                ),
                trailing:
                    IconButton(
                  onPressed: () {
                    setState(() {
                      _bye = null;
                    });
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed:
                _adicionarConfronto,
            icon: const Icon(
              Icons.add,
            ),
            label: const Text(
              'Adicionar confronto',
            ),
          ),

          if (_jogadores.length.isOdd)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 12,
              ),
              child:
                  OutlinedButton.icon(
                onPressed:
                    _definirBye,
                icon: const Icon(
                  Icons.skip_next,
                ),
                label: const Text(
                  'Selecionar BYE',
                ),
              ),
            ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed:
                _salvando
                    ? null
                    : _iniciarRodada,
            icon: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.play_arrow,
                  ),
            label: const Text(
              'Iniciar rodada',
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfrontoSelecionado {
  final JogadorTorneioModel jogador1;
  final JogadorTorneioModel jogador2;

  _ConfrontoSelecionado({
    required this.jogador1,
    required this.jogador2,
  });
}