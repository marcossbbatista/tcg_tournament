import 'package:flutter/material.dart';

import '../models/jogador_torneio_model.dart';
import '../services/jogador_torneio_service.dart';

class GerenciarJogadoresPage extends StatelessWidget {
  final String torneioId;
  final String nomeTorneio;

  const GerenciarJogadoresPage({
    super.key,
    required this.torneioId,
    required this.nomeTorneio,
  });

  Future<void> _aprovar(
    BuildContext context,
    JogadorTorneioModel jogador,
  ) async {
    try {
      await JogadorTorneioService().aprovarJogador(
        torneioId: torneioId,
        jogadorUid: jogador.uid,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${jogador.nome} foi aprovado.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível aprovar o jogador.',
          ),
        ),
      );
    }
  }

  Future<void> _recusar(
    BuildContext context,
    JogadorTorneioModel jogador,
  ) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Recusar jogador',
          ),
          content: Text(
            'Deseja realmente recusar a participação de ${jogador.nome}?',
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
                'Recusar',
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
      await JogadorTorneioService().recusarJogador(
        torneioId: torneioId,
        jogadorUid: jogador.uid,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${jogador.nome} foi recusado.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível recusar o jogador.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final JogadorTorneioService service =
        JogadorTorneioService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gerenciar jogadores',
        ),
      ),
      body: StreamBuilder<List<JogadorTorneioModel>>(
        stream: service.listarJogadores(
          torneioId,
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
                'Não foi possível carregar os jogadores.',
              ),
            );
          }

          final jogadores =
              snapshot.data ?? [];

          final pendentes = jogadores
              .where(
                (jogador) =>
                    jogador.status == 'pendente',
              )
              .toList();

          final aprovados = jogadores
              .where(
                (jogador) =>
                    jogador.status == 'aprovado',
              )
              .toList();

          final recusados = jogadores
              .where(
                (jogador) =>
                    jogador.status == 'recusado',
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                nomeTorneio,
                style:
                    Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 24),

              _TituloSecao(
                titulo: 'Pendentes',
                quantidade: pendentes.length,
              ),

              const SizedBox(height: 8),

              if (pendentes.isEmpty)
                const _ListaVazia(
                  mensagem:
                      'Nenhum jogador aguardando aprovação.',
                )
              else
                ...pendentes.map(
                  (jogador) => _JogadorCard(
                    jogador: jogador,
                    mostrarAcoes: true,
                    onAprovar: () =>
                        _aprovar(
                      context,
                      jogador,
                    ),
                    onRecusar: () =>
                        _recusar(
                      context,
                      jogador,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              _TituloSecao(
                titulo: 'Aprovados',
                quantidade: aprovados.length,
              ),

              const SizedBox(height: 8),

              if (aprovados.isEmpty)
                const _ListaVazia(
                  mensagem:
                      'Nenhum jogador aprovado.',
                )
              else
                ...aprovados.map(
                  (jogador) => _JogadorCard(
                    jogador: jogador,
                  ),
                ),

              if (recusados.isNotEmpty) ...[
                const SizedBox(height: 24),

                _TituloSecao(
                  titulo: 'Recusados',
                  quantidade: recusados.length,
                ),

                const SizedBox(height: 8),

                ...recusados.map(
                  (jogador) => _JogadorCard(
                    jogador: jogador,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  final String titulo;
  final int quantidade;

  const _TituloSecao({
    required this.titulo,
    required this.quantidade,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          titulo,
          style:
              Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(width: 8),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            quantidade.toString(),
          ),
        ),
      ],
    );
  }
}

class _JogadorCard extends StatelessWidget {
  final JogadorTorneioModel jogador;
  final bool mostrarAcoes;

  final VoidCallback? onAprovar;
  final VoidCallback? onRecusar;

  const _JogadorCard({
    required this.jogador,
    this.mostrarAcoes = false,
    this.onAprovar,
    this.onRecusar,
  });

  String _statusFormatado() {
    switch (jogador.status) {
      case 'aprovado':
        return 'Aprovado';

      case 'recusado':
        return 'Recusado';

      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
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
                    jogador.nome.isNotEmpty
                        ? jogador.nome[0]
                            .toUpperCase()
                        : '?',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        jogador.nome,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        jogador.email,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (!mostrarAcoes) ...[
              const SizedBox(height: 12),

              Text(
                _statusFormatado(),
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                  color:
                      Theme.of(context).colorScheme.primary,
                ),
              ),
            ],

            if (mostrarAcoes) ...[
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          onRecusar,
                      child: const Text(
                        'Recusar',
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          onAprovar,
                      child: const Text(
                        'Aprovar',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  final String mensagem;

  const _ListaVazia({
    required this.mensagem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          mensagem,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}