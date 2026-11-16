import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import '../models/partida_model.dart';

/// Histórico somente leitura: uma rodada por vez, inclusive as encerradas.
class DetalhesRodadaPage extends StatelessWidget {
  final String torneioId;
  final String nomeTorneio;
  final int numero;

  const DetalhesRodadaPage({
    super.key,
    required this.torneioId,
    required this.nomeTorneio,
    required this.numero,
  });

  String _resultado(PartidaModel p) {
    if (p.bye) return 'BYE';
    if (p.status == 'contestada') return 'Resultado contestado';
    if (p.status == 'aguardando_confirmacao') return 'Aguardando confirmação';
    if (p.status != 'finalizada') return 'Em andamento';
    return '${p.placarJogador1} × ${p.placarJogador2}';
  }

  @override
  Widget build(BuildContext context) {
    final torneio = FirebaseFirestore.instance.collection('tournaments').doc(torneioId);
    return TcgTheme.wrap(Scaffold(
      backgroundColor: TcgTheme.fundo,
      appBar: AppBar(title: Text('Rodada $numero'), backgroundColor: TcgTheme.fundo),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: torneio.collection('rounds').doc('$numero').snapshots(),
        builder: (context, rodadaSnap) {
          if (!rodadaSnap.hasData) return const Center(child: CircularProgressIndicator());
          if (!rodadaSnap.data!.exists) return const Center(child: Text('Esta rodada ainda não foi criada.', style: TextStyle(color: Colors.white70)));
          final rodada = rodadaSnap.data!.data() ?? {};
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: torneio.collection('rounds').doc('$numero').collection('matches').snapshots(),
            builder: (context, partidasSnap) {
              if (!partidasSnap.hasData) return const Center(child: CircularProgressIndicator());
              final partidas = partidasSnap.data!.docs.map((d) => PartidaModel.fromMap(d.id, d.data())).toList()
                ..sort((a, b) => a.mesa.compareTo(b.mesa));
              final participantes = <String>{};
              for (final partida in partidas) {
                participantes.add(partida.jogador1Uid);
                if (partida.jogador2Uid != null) participantes.add(partida.jogador2Uid!);
              }
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: torneio.collection('players').snapshots(),
                builder: (context, jogadoresSnap) {
                  final decks = <String, String>{};
                  for (final doc in jogadoresSnap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                    decks[doc.id] = (doc.data()['deckNome'] as String?)?.trim() ?? '';
                  }
                  Widget jogador(String nome, String? uid) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      if (uid != null && (decks[uid]?.isNotEmpty ?? false))
                        Text('Deck: ${decks[uid]}', style: const TextStyle(color: TcgTheme.muted, fontSize: 12)),
                    ],
                  );
                  return ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Text(nomeTorneio, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Status: ${rodada['status'] ?? 'Não informado'}  •  ${partidas.length} mesas  •  ${participantes.length} jogadores', style: const TextStyle(color: TcgTheme.muted)),
                      const SizedBox(height: 16),
                      if (partidas.isEmpty) const Text('Os pareamentos ainda não foram definidos.', style: TextStyle(color: Colors.white70)),
                      for (final partida in partidas)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TcgGlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(partida.bye ? 'BYE' : 'Mesa ${partida.mesa}', style: const TextStyle(color: TcgTheme.verde, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              jogador(partida.jogador1Nome, partida.jogador1Uid),
                              const SizedBox(height: 6),
                              if (!partida.bye) ...[
                                const Text('×', style: TextStyle(color: Colors.white54)),
                                jogador(partida.jogador2Nome ?? 'Adversário', partida.jogador2Uid),
                              ],
                              const SizedBox(height: 10),
                              Text(_resultado(partida), style: const TextStyle(color: Colors.white70)),
                            ]),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    ));
  }
}
