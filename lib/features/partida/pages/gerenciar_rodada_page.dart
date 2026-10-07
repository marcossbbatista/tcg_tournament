import 'package:flutter/material.dart';

import '../models/partida_model.dart';
import '../services/partida_service.dart';
import '../services/rodada_service.dart';

import 'editar_rodada_page.dart';

class GerenciarRodadaPage extends StatelessWidget {
  final String torneioId;
  final String nomeTorneio;
  final int rodada;
  final String formato;

  const GerenciarRodadaPage({
    super.key,
    required this.torneioId,
    required this.nomeTorneio,
    required this.rodada,
    required this.formato,
  });

  Future<void> _editarRodada(
    BuildContext context,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditarRodadaPage(
          torneioId: torneioId,
          rodada: rodada,
          nomeTorneio: nomeTorneio,
        ),
      ),
    );
  }

  Future<void> _iniciarRodada(
    BuildContext context,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Iniciar rodada',
          ),
          content: Text(
            'Deseja iniciar a Rodada $rodada? '
            'Os confrontos ficarão disponíveis para os jogadores.',
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
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Iniciar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      final resultado =
          await RodadaService().iniciarRodada(
        torneioId: torneioId,
        rodada: rodada,
      );

      if (!context.mounted) return;

      switch (resultado) {
        case 'ok':
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Rodada iniciada com sucesso.',
              ),
            ),
          );

          break;

        case 'rodada_ja_iniciada':
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'A rodada já foi iniciada.',
              ),
            ),
          );

          break;

        case 'rodada_finalizada':
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'A rodada já foi finalizada.',
              ),
            ),
          );

          break;

        case 'nenhuma_partida':
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Configure os confrontos antes de iniciar a rodada.',
              ),
            ),
          );

          break;

        default:
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível iniciar a rodada.',
              ),
            ),
          );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível iniciar a rodada.',
          ),
        ),
      );
    }
  }

  Future<void> _encerrarRodada(
    BuildContext context,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Encerrar rodada',
          ),
          content: Text(
            'Deseja encerrar a Rodada $rodada? '
            'Os pontos das partidas serão calculados.',
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
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Encerrar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      final resultado =
          await RodadaService().encerrarRodada(
        torneioId: torneioId,
        rodada: rodada,
      );

      if (!context.mounted) return;

      switch (resultado) {
        case 'ok':
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Rodada encerrada e pontuação calculada com sucesso.',
              ),
            ),
          );

          break;

        case 'partida_pendente':
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Todas as partidas precisam estar finalizadas.',
              ),
            ),
          );

          break;

        case 'rodada_finalizada':
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Esta rodada já foi encerrada.',
              ),
            ),
          );

          break;

        default:
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível encerrar a rodada.',
              ),
            ),
          );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível encerrar a rodada.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final PartidaService partidaService =
        PartidaService();

    final RodadaService rodadaService =
        RodadaService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rodada $rodada',
        ),
      ),
      body: StreamBuilder<String?>(
        stream:
            rodadaService.observarStatusRodada(
          torneioId: torneioId,
          rodada: rodada,
        ),
        builder: (
          context,
          rodadaSnapshot,
        ) {
          if (rodadaSnapshot.connectionState ==
                  ConnectionState.waiting &&
              !rodadaSnapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (rodadaSnapshot.hasError) {
            return const Center(
              child: Text(
                'Não foi possível carregar a rodada.',
              ),
            );
          }

          final statusRodada =
              rodadaSnapshot.data;

          return StreamBuilder<
              List<PartidaModel>>(
            stream:
                partidaService
                    .observarPartidasDaRodada(
              torneioId: torneioId,
              rodada: rodada,
            ),
            builder: (
              context,
              snapshot,
            ) {
              if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Não foi possível carregar as partidas.',
                  ),
                );
              }

              final partidas =
                  snapshot.data ?? [];

              final finalizadas =
                  partidas
                      .where(
                        (partida) =>
                            partida.status ==
                            'finalizada',
                      )
                      .length;

              final contestadas =
                  partidas
                      .where(
                        (partida) =>
                            partida.status ==
                            'contestada',
                      )
                      .length;

              final aguardandoConfirmacao =
                  partidas
                      .where(
                        (partida) =>
                            partida.status ==
                            'aguardando_confirmacao',
                      )
                      .length;

              final emAndamento =
                  partidas
                      .where(
                        (partida) =>
                            partida.status ==
                            'em_andamento',
                      )
                      .length;

              final podeEncerrar =
                  partidas.isNotEmpty &&
                      partidas.every(
                        (partida) =>
                            partida.status ==
                            'finalizada',
                      );

              return ListView(
                padding:
                    const EdgeInsets.all(16),
                children: [
                  Text(
                    nomeTorneio,
                    style:
                        Theme.of(context)
                            .textTheme
                            .titleLarge,
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'Rodada $rodada',
                    style:
                        Theme.of(context)
                            .textTheme
                            .headlineSmall,
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  _StatusRodada(
                    status:
                        statusRodada,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  if (statusRodada ==
                      'configuracao') ...[
                    OutlinedButton.icon(
                      onPressed: () =>
                          _editarRodada(
                        context,
                      ),
                      icon:
                          const Icon(
                        Icons.edit,
                      ),
                      label:
                          const Text(
                        'Editar confrontos',
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    ElevatedButton.icon(
                      onPressed:
                          partidas.isEmpty
                              ? null
                              : () =>
                                  _iniciarRodada(
                                context,
                              ),
                      icon:
                          const Icon(
                        Icons.play_arrow,
                      ),
                      label:
                          const Text(
                        'Iniciar rodada',
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),
                  ],

                  if (statusRodada ==
                      'em_andamento') ...[
                    OutlinedButton.icon(
                      onPressed: () =>
                          _editarRodada(
                        context,
                      ),
                      icon:
                          const Icon(
                        Icons.edit,
                      ),
                      label:
                          const Text(
                        'Editar confrontos',
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),
                  ],

                  if (statusRodada ==
                      'finalizada') ...[
                    const Card(
                      child: Padding(
                        padding:
                            EdgeInsets.all(
                          16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .check_circle,
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Text(
                                'Rodada finalizada.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child:
                            _ResumoRodada(
                          titulo:
                              'Finalizadas',
                          valor:
                              '$finalizadas/${partidas.length}',
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child:
                            _ResumoRodada(
                          titulo:
                              'Contestadas',
                          valor:
                              contestadas
                                  .toString(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            _ResumoRodada(
                          titulo:
                              'Em andamento',
                          valor:
                              emAndamento
                                  .toString(),
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child:
                            _ResumoRodada(
                          titulo:
                              'Aguardando',
                          valor:
                              aguardandoConfirmacao
                                  .toString(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  if (partidas.isEmpty)
                    const Card(
                      child: Padding(
                        padding:
                            EdgeInsets.all(
                          24,
                        ),
                        child: Text(
                          'Nenhum confronto configurado.',
                          textAlign:
                              TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ...partidas.map(
                      (partida) =>
                          _PartidaAdmCard(
                        torneioId:
                            torneioId,
                        rodada:
                            rodada,
                        formato:
                            formato,
                        partida:
                            partida,
                      ),
                    ),

                  if (statusRodada ==
                      'em_andamento') ...[
                    const SizedBox(
                      height: 24,
                    ),

                    ElevatedButton.icon(
                      onPressed:
                          podeEncerrar
                              ? () =>
                                  _encerrarRodada(
                                context,
                              )
                              : null,
                      icon:
                          const Icon(
                        Icons.flag,
                      ),
                      label:
                          const Text(
                        'Encerrar rodada',
                      ),
                    ),

                    if (!podeEncerrar) ...[
                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        'Todas as partidas precisam estar finalizadas antes de encerrar a rodada.',
                        textAlign:
                            TextAlign.center,
                      ),
                    ],
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusRodada extends StatelessWidget {
  final String? status;

  const _StatusRodada({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String texto;
    IconData icone;

    switch (status) {
      case 'configuracao':
        texto =
            'Aguardando configuração';
        icone =
            Icons.settings;

        break;

      case 'em_andamento':
        texto =
            'Em andamento';
        icone =
            Icons.play_circle;

        break;

      case 'finalizada':
        texto =
            'Finalizada';
        icone =
            Icons.check_circle;

        break;

      default:
        texto =
            'Status não identificado';
        icone =
            Icons.help_outline;
    }

    return Row(
      children: [
        Icon(
          icone,
          size: 20,
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          texto,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PartidaAdmCard extends StatelessWidget {
  final String torneioId;
  final int rodada;
  final String formato;
  final PartidaModel partida;

  const _PartidaAdmCard({
    required this.torneioId,
    required this.rodada,
    required this.formato,
    required this.partida,
  });

  String _statusFormatado() {
    switch (partida.status) {
      case 'aguardando':
        return 'Aguardando início';

      case 'em_andamento':
        return 'Em andamento';

      case 'aguardando_confirmacao':
        return 'Aguardando confirmação';

      case 'finalizada':
        return 'Finalizada';

      case 'contestada':
        return 'Contestada';

      default:
        return partida.status;
    }
  }

  IconData _iconeStatus() {
    switch (partida.status) {
      case 'aguardando':
        return Icons.hourglass_empty;

      case 'finalizada':
        return Icons.check_circle;

      case 'contestada':
        return Icons.warning_amber;

      case 'aguardando_confirmacao':
        return Icons.schedule;

      default:
        return Icons.sports_esports;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: partida.bye
                      ? const Icon(
                          Icons.skip_next,
                        )
                      : Text(
                          '${partida.mesa}',
                        ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Text(
                  partida.bye
                      ? 'BYE'
                      : 'Mesa ${partida.mesa}',
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleMedium,
                ),

                const Spacer(),

                Icon(
                  _iconeStatus(),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            if (partida.bye)
              Center(
                child: Column(
                  children: [
                    Text(
                      partida
                          .jogador1Nome,
                      style:
                          Theme.of(context)
                              .textTheme
                              .titleMedium,
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    const Text(
                      'Recebeu BYE nesta rodada',
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      partida
                          .jogador1Nome,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 12,
                    ),
                    child: Text(
                      '${partida.placarJogador1} x ${partida.placarJogador2}',
                      style:
                          Theme.of(context)
                              .textTheme
                              .titleLarge,
                    ),
                  ),

                  Expanded(
                    child: Text(
                      partida
                              .jogador2Nome ??
                          '',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(
              height: 16,
            ),

            Text(
              _statusFormatado(),
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            if (partida.status ==
                'contestada') ...[
              const SizedBox(
                height: 16,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed: () {
                    _resolverContestacao(
                      context,
                    );
                  },
                  icon:
                      const Icon(
                    Icons.gavel,
                  ),
                  label:
                      const Text(
                    'Resolver contestação',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _resolverContestacao(
    BuildContext context,
  ) async {
    int? placar1;
    int? placar2;

    final resultado =
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
                'Resolver contestação',
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    '${partida.jogador1Nome} x ${partida.jogador2Nome}',
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  DropdownButtonFormField<int>(
                    decoration:
                        InputDecoration(
                      labelText:
                          partida
                              .jogador1Nome,
                      border:
                          const OutlineInputBorder(),
                    ),
                    items: _valoresPlacar()
                        .map(
                          (valor) =>
                              DropdownMenuItem(
                            value: valor,
                            child: Text(
                              valor
                                  .toString(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setDialogState(() {
                        placar1 =
                            valor;
                      });
                    },
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  DropdownButtonFormField<int>(
                    decoration:
                        InputDecoration(
                      labelText:
                          partida
                              .jogador2Nome,
                      border:
                          const OutlineInputBorder(),
                    ),
                    items: _valoresPlacar()
                        .map(
                          (valor) =>
                              DropdownMenuItem(
                            value: valor,
                            child: Text(
                              valor
                                  .toString(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setDialogState(() {
                        placar2 =
                            valor;
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
                  child:
                      const Text(
                    'Cancelar',
                  ),
                ),

                ElevatedButton(
                  onPressed:
                      placar1 == null ||
                              placar2 ==
                                  null
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                true,
                              );
                            },
                  child:
                      const Text(
                    'Confirmar resultado',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado != true ||
        placar1 == null ||
        placar2 == null) {
      return;
    }

    try {
      await PartidaService()
          .resolverPartidaContestada(
        torneioId: torneioId,
        rodada: rodada,
        partidaId: partida.id,
        placarJogador1: placar1!,
        placarJogador2: placar2!,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Resultado definido com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível resolver a contestação.',
          ),
        ),
      );
    }
  }

  List<int> _valoresPlacar() {
    if (formato == 'md1') {
      return [
        0,
        1,
      ];
    }

    return [
      0,
      1,
      2,
    ];
  }
}

class _ResumoRodada extends StatelessWidget {
  final String titulo;
  final String valor;

  const _ResumoRodada({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              valor,
              style:
                  Theme.of(context)
                      .textTheme
                      .headlineSmall,
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              titulo,
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}