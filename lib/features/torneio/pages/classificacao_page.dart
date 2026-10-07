import 'package:flutter/material.dart';

import '../models/classificacao_jogador_model.dart';
import '../../partida/services/rodada_service.dart';

class ClassificacaoPage
    extends StatefulWidget {
  final String torneioId;
  final String nomeTorneio;
  final bool classificacaoFinal;

  const ClassificacaoPage({
    super.key,
    required this.torneioId,
    required this.nomeTorneio,
    this.classificacaoFinal = false,
  });

  @override
  State<ClassificacaoPage>
      createState() =>
          _ClassificacaoPageState();
}

class _ClassificacaoPageState
    extends State<ClassificacaoPage> {
  late Future<
      List<ClassificacaoJogadorModel>>
      _classificacao;

  @override
  void initState() {
    super.initState();

    _carregarClassificacao();
  }

  void _carregarClassificacao() {
    _classificacao =
        RodadaService()
            .buscarClassificacao(
      torneioId:
          widget.torneioId,
    );
  }

  Future<void> _atualizar() async {
    setState(() {
      _carregarClassificacao();
    });

    await _classificacao;
  }

  String _formatarPercentual(
    double valor,
  ) {
    return '${(valor * 100).toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.classificacaoFinal
              ? 'Classificação final'
              : 'Classificação',
        ),
      ),
      body: FutureBuilder<
          List<ClassificacaoJogadorModel>>(
        future: _classificacao,
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh:
                  _atualizar,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 200,
                  ),
                  Center(
                    child: Text(
                      'Não foi possível carregar a classificação.',
                    ),
                  ),
                ],
              ),
            );
          }

          final jogadores =
              snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh:
                _atualizar,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(
                16,
              ),
              children: [
                _CabecalhoClassificacao(
                  nomeTorneio:
                      widget.nomeTorneio,
                  classificacaoFinal:
                      widget
                          .classificacaoFinal,
                ),

                const SizedBox(
                  height: 16,
                ),

                const _LegendaClassificacao(),

                const SizedBox(
                  height: 24,
                ),

                if (jogadores.isEmpty)
                  const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(
                        24,
                      ),
                      child: Text(
                        'Nenhum jogador encontrado.',
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...List.generate(
                    jogadores.length,
                    (index) {
                      final jogador =
                          jogadores[
                              index];

                      return _JogadorClassificacaoCard(
                        posicao:
                            index + 1,
                        jogador:
                            jogador,
                        formatarPercentual:
                            _formatarPercentual,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CabecalhoClassificacao
    extends StatelessWidget {
  final String nomeTorneio;
  final bool classificacaoFinal;

  const _CabecalhoClassificacao({
    required this.nomeTorneio,
    required this.classificacaoFinal,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Column(
          children: [
            Icon(
              classificacaoFinal
                  ? Icons.emoji_events
                  : Icons.leaderboard,
              size: 48,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              nomeTorneio,
              style:
                  Theme.of(context)
                      .textTheme
                      .titleLarge,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              classificacaoFinal
                  ? 'Classificação final do torneio'
                  : 'Classificação atual',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendaClassificacao
    extends StatelessWidget {
  const _LegendaClassificacao();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Critérios de classificação',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              '1. Pontos',
            ),

            const Text(
              '2. Op Win %',
            ),

            const Text(
              '3. Op Op Win %',
            ),

            const Text(
              '4. Confronto direto',
            ),
          ],
        ),
      ),
    );
  }
}

class _JogadorClassificacaoCard
    extends StatelessWidget {
  final int posicao;

  final ClassificacaoJogadorModel
      jogador;

  final String Function(double)
      formatarPercentual;

  const _JogadorClassificacaoCard({
    required this.posicao,
    required this.jogador,
    required this.formatarPercentual,
  });

  IconData? _iconePosicao() {
    switch (posicao) {
      case 1:
        return Icons.emoji_events;

      case 2:
        return Icons.workspace_premium;

      case 3:
        return Icons.military_tech;

      default:
        return null;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final icone =
        _iconePosicao();

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: icone != null
              ? Icon(
                  icone,
                  size: 20,
                )
              : Text(
                  '$posicao',
                ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                jogador.nome,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            Text(
              '${jogador.pontos} pts',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium,
            ),
          ],
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 4,
          ),
          child: Text(
            '${jogador.vitorias}V • '
            '${jogador.derrotas}D • '
            '${jogador.empates}E',
          ),
        ),
        children: [
          const Divider(
            height: 1,
          ),

          Padding(
            padding:
                const EdgeInsets.all(
              16,
            ),
            child: Column(
              children: [
                _LinhaEstatistica(
                  titulo:
                      'Retrospecto',
                  valor:
                      jogador
                          .retrospecto,
                ),

                const SizedBox(
                  height: 12,
                ),

                _LinhaEstatistica(
                  titulo:
                      'Win %',
                  valor:
                      formatarPercentual(
                    jogador
                        .winPercentage,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _LinhaEstatistica(
                  titulo:
                      'Op Win %',
                  valor:
                      formatarPercentual(
                    jogador
                        .opponentWinPercentage,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                _LinhaEstatistica(
                  titulo:
                      'Op Op Win %',
                  valor:
                      formatarPercentual(
                    jogador
                        .opponentOpponentWinPercentage,
                  ),
                ),

                if (jogador
                        .quantidadeByes >
                    0) ...[
                  const SizedBox(
                    height: 12,
                  ),

                  _LinhaEstatistica(
                    titulo: 'BYE',
                    valor:
                        jogador
                            .quantidadeByes
                            .toString(),
                  ),
                ],

                const SizedBox(
                  height: 12,
                ),

                _LinhaEstatistica(
                  titulo:
                      'Status',
                  valor:
                      jogador.ativo
                          ? 'Ativo'
                          : 'Drop',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaEstatistica
    extends StatelessWidget {
  final String titulo;
  final String valor;

  const _LinhaEstatistica({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
          ),
        ),

        Text(
          valor,
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