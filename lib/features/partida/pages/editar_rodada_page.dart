import 'package:flutter/material.dart';

import '../../jogador/models/jogador_torneio_model.dart';
import '../models/partida_model.dart';
import '../services/partida_service.dart';
import '../services/rodada_service.dart';

class EditarRodadaPage extends StatefulWidget {
  final String torneioId;
  final int rodada;
  final String nomeTorneio;

  const EditarRodadaPage({
    super.key,
    required this.torneioId,
    required this.rodada,
    required this.nomeTorneio,
  });

  @override
  State<EditarRodadaPage> createState() =>
      _EditarRodadaPageState();
}

class _EditarRodadaPageState
    extends State<EditarRodadaPage> {
  final RodadaService _rodadaService =
      RodadaService();

  final PartidaService _partidaService =
      PartidaService();

  List<JogadorTorneioModel> _jogadores = [];

  final List<_ConfrontoEditavel> _confrontos = [];

  JogadorTorneioModel? _bye;

  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();

    _carregar();
  }

  JogadorTorneioModel? _buscarJogador(
    List<JogadorTorneioModel> jogadores,
    String? uid,
  ) {
    if (uid == null) {
      return null;
    }

    for (final jogador in jogadores) {
      if (jogador.uid == uid) {
        return jogador;
      }
    }

    return null;
  }

  Future<void> _carregar() async {
    try {
      final jogadores =
          await _rodadaService.listarJogadoresAprovados(
        widget.torneioId,
      );

      final partidas =
          await _partidaService.buscarPartidasDaRodada(
        torneioId: widget.torneioId,
        rodada: widget.rodada,
      );

      if (!mounted) return;

      final confrontos =
          <_ConfrontoEditavel>[];

      JogadorTorneioModel? bye;

      for (final partida in partidas) {
        final jogador1 =
            _buscarJogador(
          jogadores,
          partida.jogador1Uid,
        );

        if (jogador1 == null) {
          continue;
        }

        if (partida.bye) {
          bye = jogador1;

          continue;
        }

        final jogador2 =
            _buscarJogador(
          jogadores,
          partida.jogador2Uid,
        );

        if (jogador2 == null) {
          continue;
        }

        confrontos.add(
          _ConfrontoEditavel(
            jogador1: jogador1,
            jogador2: jogador2,
          ),
        );
      }

      setState(() {
        _jogadores = jogadores;

        _confrontos
          ..clear()
          ..addAll(confrontos);

        _bye = bye;

        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        'Não foi possível carregar a rodada.',
      );
    }
  }

  List<JogadorTorneioModel>
      _jogadoresDisponiveis() {
    final utilizados = <String>{};

    for (final confronto in _confrontos) {
      utilizados.add(
        confronto.jogador1.uid,
      );

      utilizados.add(
        confronto.jogador2.uid,
      );
    }

    if (_bye != null) {
      utilizados.add(
        _bye!.uid,
      );
    }

    return _jogadores
        .where(
          (jogador) =>
              !utilizados.contains(
            jogador.uid,
          ),
        )
        .toList();
  }

  Future<void> _adicionarConfronto() async {
    final disponiveis =
        _jogadoresDisponiveis();

    if (disponiveis.length < 2) {
      _mostrarMensagem(
        'Não existem dois jogadores disponíveis.',
      );

      return;
    }

    JogadorTorneioModel? jogador1;
    JogadorTorneioModel? jogador2;

    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Adicionar confronto',
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  DropdownButtonFormField<
                      JogadorTorneioModel>(
                    decoration:
                        const InputDecoration(
                      labelText: 'Jogador 1',
                      border:
                          OutlineInputBorder(),
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
                      labelText: 'Jogador 2',
                      border:
                          OutlineInputBorder(),
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

    if (confirmar != true ||
        jogador1 == null ||
        jogador2 == null) {
      return;
    }

    setState(() {
      _confrontos.add(
        _ConfrontoEditavel(
          jogador1: jogador1!,
          jogador2: jogador2!,
        ),
      );
    });
  }

  Future<void> _selecionarBye() async {
    final disponiveis =
        _jogadoresDisponiveis();

    if (disponiveis.isEmpty) {
      _mostrarMensagem(
        'Nenhum jogador disponível.',
      );

      return;
    }

    JogadorTorneioModel? selecionado;

    final confirmar =
        await showDialog<bool>(
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
                  border:
                      OutlineInputBorder(),
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
                  onPressed:
                      selecionado == null
                          ? null
                          : () {
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

    if (confirmar != true ||
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
      _confrontos.removeAt(
        index,
      );
    });
  }

  Future<void> _salvar() async {
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
        'Selecione quem receberá o BYE.',
      );

      return;
    }

    if (_jogadores.length.isEven &&
        _bye != null) {
      _mostrarMensagem(
        'Não deve existir BYE com quantidade par de jogadores.',
      );

      return;
    }

    final novasPartidas =
        <PartidaModel>[];

    for (int i = 0;
        i < _confrontos.length;
        i++) {
      final confronto =
          _confrontos[i];

      novasPartidas.add(
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
          resultadoInformadoPor: null,
          bye: false,
        ),
      );
    }

    if (_bye != null) {
      novasPartidas.add(
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
          resultadoInformadoPor: null,
          bye: true,
        ),
      );
    }

    setState(() {
      _salvando = true;
    });

    try {
      final resultado =
          await _rodadaService.editarRodada(
        torneioId: widget.torneioId,
        rodada: widget.rodada,
        novasPartidas: novasPartidas,
      );

      if (!mounted) return;

      switch (resultado) {
        case 'ok':
          _mostrarMensagem(
            'Rodada atualizada com sucesso.',
          );

          Navigator.pop(
            context,
            true,
          );

          break;

        case 'rodada_finalizada':
          _mostrarMensagem(
            'Uma rodada finalizada não pode ser alterada.',
          );

          break;

        case 'jogador_duplicado':
          _mostrarMensagem(
            'Um jogador não pode participar de duas partidas na mesma rodada.',
          );

          break;

        case 'jogador_invalido':
          _mostrarMensagem(
            'Existe um jogador inválido na rodada.',
          );

          break;

        case 'mesmo_jogador':
          _mostrarMensagem(
            'Um jogador não pode enfrentar a si mesmo.',
          );

          break;

        case 'jogadores_sem_partida':
          _mostrarMensagem(
            'Existem jogadores sem partida.',
          );

          break;

        case 'bye_obrigatorio':
          _mostrarMensagem(
            'É necessário definir um jogador com BYE.',
          );

          break;

        case 'bye_invalido':
          _mostrarMensagem(
            'Não é necessário BYE nesta rodada.',
          );

          break;

        default:
          _mostrarMensagem(
            'Não foi possível atualizar a rodada.',
          );
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível atualizar a rodada.',
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
        content: Text(
          mensagem,
        ),
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

    final disponiveis =
        _jogadoresDisponiveis();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Editar Rodada ${widget.rodada}',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Text(
            widget.nomeTorneio,
            style:
                Theme.of(context)
                    .textTheme
                    .titleLarge,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            '${_jogadores.length} jogadores aprovados',
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Remova os confrontos que deseja alterar e monte novamente com os jogadores disponíveis.',
          ),

          const SizedBox(
            height: 24,
          ),

          Text(
            'Confrontos',
            style:
                Theme.of(context)
                    .textTheme
                    .titleMedium,
          ),

          const SizedBox(
            height: 8,
          ),

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
                      tooltip:
                          'Remover confronto',
                      onPressed: () {
                        _removerConfronto(
                          index,
                        );
                      },
                      icon:
                          const Icon(
                        Icons.delete_outline,
                      ),
                    ),
                  ),
                );
              },
            ),

          if (_bye != null) ...[
            const SizedBox(
              height: 8,
            ),

            Card(
              child: ListTile(
                leading:
                    const Icon(
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
                  tooltip:
                      'Remover BYE',
                  onPressed: () {
                    setState(() {
                      _bye = null;
                    });
                  },
                  icon:
                      const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ),
            ),
          ],

          if (disponiveis.isNotEmpty) ...[
            const SizedBox(
              height: 24,
            ),

            Text(
              'Jogadores disponíveis',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium,
            ),

            const SizedBox(
              height: 8,
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: disponiveis
                  .map(
                    (jogador) =>
                        Chip(
                      label: Text(
                        jogador.nome,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(
            height: 24,
          ),

          OutlinedButton.icon(
            onPressed:
                _adicionarConfronto,
            icon:
                const Icon(
              Icons.add,
            ),
            label:
                const Text(
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
                    _selecionarBye,
                icon:
                    const Icon(
                  Icons.skip_next,
                ),
                label:
                    const Text(
                  'Selecionar BYE',
                ),
              ),
            ),

          const SizedBox(
            height: 24,
          ),

          ElevatedButton.icon(
            onPressed:
                _salvando
                    ? null
                    : _salvar,
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
                    Icons.save,
                  ),
            label:
                const Text(
              'Salvar rodada',
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfrontoEditavel {
  final JogadorTorneioModel jogador1;
  final JogadorTorneioModel jogador2;

  _ConfrontoEditavel({
    required this.jogador1,
    required this.jogador2,
  });
}