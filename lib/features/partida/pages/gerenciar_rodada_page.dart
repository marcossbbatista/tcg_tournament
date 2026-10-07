import 'package:flutter/material.dart';

import '../models/partida_model.dart';
import '../services/partida_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final PartidaService partidaService =
        PartidaService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rodada $rodada',
        ),
      ),
      body: StreamBuilder<List<PartidaModel>>(
        stream:
            partidaService.observarPartidasDaRodada(
          torneioId: torneioId,
          rodada: rodada,
        ),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
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

          if (partidas.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma partida encontrada nesta rodada.',
              ),
            );
          }

          final finalizadas = partidas
              .where(
                (partida) =>
                    partida.status == 'finalizada',
              )
              .length;

          final contestadas = partidas
              .where(
                (partida) =>
                    partida.status == 'contestada',
              )
              .length;

          final podeEncerrar =
              partidas.every(
            (partida) =>
                partida.status == 'finalizada',
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                nomeTorneio,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 8),

              Text(
                'Rodada $rodada',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _ResumoRodada(
                      titulo: 'Finalizadas',
                      valor:
                          '$finalizadas/${partidas.length}',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _ResumoRodada(
                      titulo: 'Contestadas',
                      valor:
                          contestadas.toString(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              ...partidas.map(
                (partida) =>
                    _PartidaAdmCard(
                  torneioId: torneioId,
                  rodada: rodada,
                  formato: formato,
                  partida: partida,
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed:
                    podeEncerrar
                        ? () {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'O encerramento da rodada será implementado na próxima etapa.',
                                ),
                              ),
                            );
                          }
                        : null,
                icon: const Icon(
                  Icons.flag,
                ),
                label: const Text(
                  'Encerrar rodada',
                ),
              ),

              if (!podeEncerrar) ...[
                const SizedBox(height: 8),

                const Text(
                  'Todas as partidas precisam estar finalizadas antes de encerrar a rodada.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
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
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    '${partida.mesa}',
                  ),
                ),

                const SizedBox(width: 12),

                Text(
                  'Mesa ${partida.mesa}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),

                const Spacer(),

                Icon(
                  _iconeStatus(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    partida.jogador1Nome,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: partida.bye
                      ? const Text(
                          'BYE',
                        )
                      : Text(
                          '${partida.placarJogador1} x ${partida.placarJogador2}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge,
                        ),
                ),

                Expanded(
                  child: Text(
                    partida.jogador2Nome ??
                        '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              _statusFormatado(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            if (partida.status ==
                'contestada') ...[
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _resolverContestacao(
                      context,
                    );
                  },
                  icon: const Icon(
                    Icons.gavel,
                  ),
                  label: const Text(
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

                  const SizedBox(height: 20),

                  DropdownButtonFormField<int>(
                    decoration:
                        InputDecoration(
                      labelText:
                          partida.jogador1Nome,
                    ),
                    items: _valoresPlacar()
                        .map(
                          (valor) =>
                              DropdownMenuItem(
                            value: valor,
                            child: Text(
                              valor.toString(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setDialogState(() {
                        placar1 = valor;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    decoration:
                        InputDecoration(
                      labelText:
                          partida.jogador2Nome,
                    ),
                    items: _valoresPlacar()
                        .map(
                          (valor) =>
                              DropdownMenuItem(
                            value: valor,
                            child: Text(
                              valor.toString(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      setDialogState(() {
                        placar2 = valor;
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
                  onPressed:
                      placar1 == null ||
                              placar2 == null
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                true,
                              );
                            },
                  child: const Text(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              valor,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),

            const SizedBox(height: 4),

            Text(
              titulo,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}