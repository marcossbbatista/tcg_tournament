import 'package:flutter/material.dart';

import '../models/torneio_model.dart';

class TorneioCard extends StatelessWidget {
  final TorneioModel torneio;
  final VoidCallback onGerenciar;

  const TorneioCard({
    super.key,
    required this.torneio,
    required this.onGerenciar,
  });

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  String _formatarHorario(DateTime data) {
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  String _retornarStatus() {
    switch (torneio.status) {
      case 'inscricoes':
        return 'Inscrições abertas';

      case 'em_andamento':
        return 'Em andamento';

      case 'finalizado':
        return 'Finalizado';

      default:
        return torneio.status;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              torneio.nome,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Text(
                  '${_formatarData(torneio.dataHora)} às ${_formatarHorario(torneio.dataHora)}',
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
                  torneio.formato.toUpperCase(),
                ),

                const SizedBox(width: 16),

                Text(
                  '${torneio.quantidadeRodadas} rodadas',
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.key,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Text(
                  torneio.codigo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              _retornarStatus(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onGerenciar,
                child: const Text(
                  'Gerenciar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}