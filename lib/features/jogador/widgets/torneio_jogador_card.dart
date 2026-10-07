import 'package:flutter/material.dart';

import '../models/torneio_jogador_model.dart';

class TorneioJogadorCard extends StatelessWidget {
  final TorneioJogadorModel item;
  final VoidCallback onAbrir;

  const TorneioJogadorCard({
    super.key,
    required this.item,
    required this.onAbrir,
  });

  String _formatarData(
    DateTime data,
  ) {
    final dia =
        data.day.toString().padLeft(2, '0');

    final mes =
        data.month.toString().padLeft(2, '0');

    final ano = data.year;

    final hora =
        data.hour.toString().padLeft(2, '0');

    final minuto =
        data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  String _statusFormatado() {
    switch (item.status) {
      case 'aprovado':
        return 'Inscrição confirmada';

      case 'recusado':
        return 'Inscrição recusada';

      default:
        return 'Aguardando aprovação';
    }
  }

  IconData _iconeStatus() {
    switch (item.status) {
      case 'aprovado':
        return Icons.check_circle;

      case 'recusado':
        return Icons.cancel;

      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final torneio = item.torneio;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: onAbrir,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                torneio.nome,
                style:
                    Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 18,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      _formatarData(
                        torneio.dataHora,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.sports_esports,
                    size: 18,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    torneio.formato
                        .toUpperCase(),
                  ),

                  const SizedBox(width: 16),

                  Text(
                    '${torneio.quantidadeRodadas} rodadas',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    _iconeStatus(),
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    _statusFormatado(),
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}