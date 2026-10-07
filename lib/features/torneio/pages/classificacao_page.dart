import 'package:flutter/material.dart';

import '../../jogador/models/jogador_torneio_model.dart';
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
      List<JogadorTorneioModel>>
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
          List<JogadorTorneioModel>>(
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
              onRefresh: _atualizar,
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
            onRefresh: _atualizar,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(16),
              children: [
                _CabecalhoClassificacao(
                  nomeTorneio:
                      widget.nomeTorneio,
                  classificacaoFinal:
                      widget
                          .classificacaoFinal,
                ),

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
                          jogadores[index];

                      return _JogadorClassificacaoCard(
                        posicao:
                            index + 1,
                        jogador:
                            jogador,
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
            const EdgeInsets.all(20),
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

class _JogadorClassificacaoCard
    extends StatelessWidget {
  final int posicao;
  final JogadorTorneioModel jogador;

  const _JogadorClassificacaoCard({
    required this.posicao,
    required this.jogador,
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
        bottom: 10,
      ),
      child: ListTile(
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
        title: Text(
          jogador.nome,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              jogador.ativo
                  ? 'Participante ativo'
                  : 'Participante inativo',
            ),

            if (jogador.quantidadeByes >
                0)
              Text(
                'BYE: ${jogador.quantidadeByes}',
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              '${jogador.pontos}',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleLarge,
            ),
            const Text(
              'pts',
            ),
          ],
        ),
      ),
    );
  }
}