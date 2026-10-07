import 'package:flutter/material.dart';

import '../models/torneio_model.dart';
import '../services/torneio_service.dart';

import '../../jogador/models/jogador_torneio_model.dart';
import '../../jogador/services/jogador_torneio_service.dart';
import '../../jogador/pages/gerenciar_jogadores_page.dart';

import '../../partida/pages/montar_primeira_rodada_page.dart';
import '../../partida/pages/gerenciar_rodada_page.dart';
import '../../partida/services/rodada_service.dart';

import 'classificacao_page.dart';

class GerenciarTorneioPage
    extends StatelessWidget {
  final TorneioModel torneio;

  const GerenciarTorneioPage({
    super.key,
    required this.torneio,
  });

  String _formatarData(
    DateTime data,
  ) {
    final dia =
        data.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    final mes =
        data.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final ano =
        data.year.toString();

    return '$dia/$mes/$ano';
  }

  String _formatarHorario(
    DateTime data,
  ) {
    final hora =
        data.hour
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minuto =
        data.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$hora:$minuto';
  }

  String _formatarStatus(
    String status,
  ) {
    switch (status) {
      case 'inscricoes':
        return 'Inscrições abertas';

      case 'em_andamento':
        return 'Em andamento';

      case 'finalizado':
        return 'Finalizado';

      default:
        return status;
    }
  }

  Future<void> _iniciarTorneio(
    BuildContext context,
    TorneioModel torneioAtual,
  ) async {
    try {
      final resultado =
          await RodadaService()
              .iniciarTorneio(
        torneioId:
            torneioAtual.id,
      );

      if (!context.mounted) {
        return;
      }

      if (resultado ==
          'jogadores_insuficientes') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'São necessários pelo menos 2 jogadores aprovados.',
            ),
          ),
        );

        return;
      }

      if (resultado != 'ok') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível iniciar o torneio.',
            ),
          ),
        );

        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MontarPrimeiraRodadaPage(
            torneioId:
                torneioAtual.id,
            nomeTorneio:
                torneioAtual.nome,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível iniciar o torneio.',
          ),
        ),
      );
    }
  }

  void _abrirClassificacao(
    BuildContext context,
    TorneioModel torneioAtual, {
    bool classificacaoFinal = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ClassificacaoPage(
          torneioId:
              torneioAtual.id,
          nomeTorneio:
              torneioAtual.nome,
          classificacaoFinal:
              classificacaoFinal,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final TorneioService
        torneioService =
        TorneioService();

    return StreamBuilder<
        TorneioModel?>(
      stream:
          torneioService
              .observarTorneio(
        torneio.id,
      ),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot
                    .connectionState ==
                ConnectionState
                    .waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Não foi possível carregar o torneio.',
              ),
            ),
          );
        }

        final torneioAtual =
            snapshot.data ??
                torneio;

        return _buildPagina(
          context,
          torneioAtual,
        );
      },
    );
  }

  Widget _buildPagina(
    BuildContext context,
    TorneioModel torneioAtual,
  ) {
    final JogadorTorneioService
        jogadorService =
        JogadorTorneioService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          torneioAtual.nome,
        ),
      ),
      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      torneioAtual.nome,
                      style:
                          Theme.of(
                            context,
                          )
                              .textTheme
                              .headlineSmall,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _InfoLinha(
                      icone:
                          Icons.key,
                      titulo:
                          'Código',
                      valor:
                          torneioAtual
                              .codigo,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _InfoLinha(
                      icone:
                          Icons
                              .calendar_month,
                      titulo:
                          'Data',
                      valor:
                          _formatarData(
                        torneioAtual
                            .dataHora,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _InfoLinha(
                      icone:
                          Icons
                              .access_time,
                      titulo:
                          'Horário',
                      valor:
                          _formatarHorario(
                        torneioAtual
                            .dataHora,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _InfoLinha(
                      icone:
                          Icons
                              .sports_esports,
                      titulo:
                          'Formato',
                      valor:
                          torneioAtual
                              .formato
                              .toUpperCase(),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _InfoLinha(
                      icone:
                          Icons.repeat,
                      titulo:
                          'Rodadas',
                      valor:
                          '${torneioAtual.quantidadeRodadas}',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _InfoLinha(
                      icone:
                          Icons.flag,
                      titulo:
                          'Rodada atual',
                      valor:
                          '${torneioAtual.rodadaAtual}',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _InfoLinha(
                      icone:
                          Icons
                              .info_outline,
                      titulo:
                          'Status',
                      valor:
                          _formatarStatus(
                        torneioAtual
                            .status,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            Text(
              'Participantes',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleLarge,
            ),

            const SizedBox(
              height: 12,
            ),

            StreamBuilder<
                List<
                    JogadorTorneioModel>>(
              stream:
                  jogadorService
                      .listarJogadores(
                torneioAtual.id,
              ),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Card(
                    child: Padding(
                      padding:
                          EdgeInsets
                              .all(
                        24,
                      ),
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot
                    .hasError) {
                  return const Card(
                    child: Padding(
                      padding:
                          EdgeInsets
                              .all(
                        16,
                      ),
                      child: Text(
                        'Não foi possível carregar os participantes.',
                      ),
                    ),
                  );
                }

                final jogadores =
                    snapshot.data ??
                        [];

                final aprovados =
                    jogadores
                        .where(
                          (
                            jogador,
                          ) =>
                              jogador
                                  .status ==
                              'aprovado',
                        )
                        .length;

                final pendentes =
                    jogadores
                        .where(
                          (
                            jogador,
                          ) =>
                              jogador
                                  .status ==
                              'pendente',
                        )
                        .length;

                return Card(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .all(
                      16,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child:
                                  _ResumoParticipantes(
                                titulo:
                                    'Aprovados',
                                quantidade:
                                    aprovados,
                              ),
                            ),

                            const SizedBox(
                              width:
                                  12,
                            ),

                            Expanded(
                              child:
                                  _ResumoParticipantes(
                                titulo:
                                    'Pendentes',
                                quantidade:
                                    pendentes,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height:
                              16,
                        ),

                        SizedBox(
                          width:
                              double
                                  .infinity,
                          child:
                              OutlinedButton
                                  .icon(
                            onPressed:
                                () {
                              Navigator
                                  .push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          GerenciarJogadoresPage(
                                    torneioId:
                                        torneioAtual.id,
                                    nomeTorneio:
                                        torneioAtual.nome,
                                  ),
                                ),
                              );
                            },
                            icon:
                                const Icon(
                              Icons
                                  .people,
                            ),
                            label:
                                const Text(
                              'Gerenciar jogadores',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(
              height: 24,
            ),

            if (torneioAtual.status ==
                'inscricoes')
              _CardTorneioNaoIniciado(
                onIniciar: () =>
                    _iniciarTorneio(
                  context,
                  torneioAtual,
                ),
              )
            else if (torneioAtual.status ==
                'em_andamento')
              StreamBuilder<String?>(
                stream:
                    RodadaService()
                        .observarStatusRodada(
                  torneioId:
                      torneioAtual.id,
                  rodada:
                      torneioAtual
                          .rodadaAtual,
                ),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot
                              .connectionState ==
                          ConnectionState
                              .waiting &&
                      !snapshot
                          .hasData) {
                    return const Card(
                      child: Padding(
                        padding:
                            EdgeInsets
                                .all(
                          24,
                        ),
                        child: Center(
                          child:
                              CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }

                  return _CardRodadaAtual(
                    torneio:
                        torneioAtual,
                    statusRodada:
                        snapshot.data,
                    onVerClassificacao:
                        () =>
                            _abrirClassificacao(
                      context,
                      torneioAtual,
                    ),
                  );
                },
              )
            else if (torneioAtual.status ==
                'finalizado')
              _CardTorneioFinalizado(
                onVerClassificacao:
                    () =>
                        _abrirClassificacao(
                  context,
                  torneioAtual,
                  classificacaoFinal:
                      true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardTorneioNaoIniciado
    extends StatelessWidget {
  final VoidCallback onIniciar;

  const _CardTorneioNaoIniciado({
    required this.onIniciar,
  });

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
          children: [
            const Icon(
              Icons
                  .emoji_events_outlined,
              size: 42,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'O torneio ainda não foi iniciado.',
            ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    onIniciar,
                icon:
                    const Icon(
                  Icons.play_arrow,
                ),
                label:
                    const Text(
                  'Iniciar torneio',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardRodadaAtual
    extends StatelessWidget {
  final TorneioModel torneio;
  final String? statusRodada;
  final VoidCallback
      onVerClassificacao;

  const _CardRodadaAtual({
    required this.torneio,
    required this.statusRodada,
    required this.onVerClassificacao,
  });

  bool get _ultimaRodada =>
      torneio.rodadaAtual >=
      torneio.quantidadeRodadas;

  String _titulo() {
    switch (statusRodada) {
      case 'configuracao':
        return 'Rodada ${torneio.rodadaAtual} aguardando configuração';

      case 'finalizada':
        return 'Rodada ${torneio.rodadaAtual} finalizada';

      case 'em_andamento':
        return 'Rodada ${torneio.rodadaAtual} em andamento';

      default:
        return 'Rodada ${torneio.rodadaAtual}';
    }
  }

  Future<void>
      _gerarProximaRodada(
    BuildContext context,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (
        context,
      ) {
        return AlertDialog(
          title: Text(
            'Gerar Rodada ${torneio.rodadaAtual + 1}',
          ),
          content:
              const Text(
            'O sistema irá sugerir os próximos confrontos com base na classificação e no histórico de partidas. '
            'Você poderá revisar e alterar os confrontos antes de iniciar a rodada.',
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
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
                  () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text(
                'Gerar rodada',
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
          await RodadaService()
              .gerarProximaRodada(
        torneioId:
            torneio.id,
        rodadaAtual:
            torneio.rodadaAtual,
      );

      if (!context.mounted) {
        return;
      }

      switch (resultado) {
        case 'ok':
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                'Rodada ${torneio.rodadaAtual + 1} gerada. Revise os confrontos antes de iniciar.',
              ),
            ),
          );

          break;

        case 'ultima_rodada':
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'O torneio já chegou à última rodada.',
              ),
            ),
          );

          break;

        case 'rodada_ja_existe':
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'A próxima rodada já existe.',
              ),
            ),
          );

          break;

        case 'rodada_nao_finalizada':
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Finalize a rodada atual antes de gerar a próxima.',
              ),
            ),
          );

          break;

        case 'jogadores_insuficientes':
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Não existem jogadores suficientes para gerar a próxima rodada.',
              ),
            ),
          );

          break;

        default:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível gerar a próxima rodada.',
              ),
            ),
          );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível gerar a próxima rodada.',
          ),
        ),
      );
    }
  }

  Future<void> _finalizarTorneio(
    BuildContext context,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,
      builder: (
        context,
      ) {
        return AlertDialog(
          title:
              const Text(
            'Finalizar torneio',
          ),
          content:
              const Text(
            'Todas as rodadas foram concluídas. Deseja finalizar o torneio?\n\n'
            'Após a finalização, novas rodadas não poderão ser geradas.',
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
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
                  () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text(
                'Finalizar torneio',
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
          await TorneioService()
              .finalizarTorneio(
        torneioId:
            torneio.id,
      );

      if (!context.mounted) {
        return;
      }

      switch (resultado) {
        case 'ok':
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Torneio finalizado com sucesso.',
              ),
            ),
          );

          break;

        case 'torneio_finalizado':
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Este torneio já foi finalizado.',
              ),
            ),
          );

          break;

        case 'rodadas_pendentes':
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Ainda existem rodadas pendentes.',
              ),
            ),
          );

          break;

        case 'rodada_nao_finalizada':
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'A última rodada ainda não foi finalizada.',
              ),
            ),
          );

          break;

        default:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível finalizar o torneio.',
              ),
            ),
          );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível finalizar o torneio.',
          ),
        ),
      );
    }
  }

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
          children: [
            const Icon(
              Icons.sports_esports,
              size: 42,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              _titulo(),
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              GerenciarRodadaPage(
                        torneioId:
                            torneio.id,
                        nomeTorneio:
                            torneio.nome,
                        rodada:
                            torneio
                                .rodadaAtual,
                        formato:
                            torneio
                                .formato,
                      ),
                    ),
                  );
                },
                icon:
                    const Icon(
                  Icons.table_rows,
                ),
                label:
                    Text(
                  statusRodada ==
                          'configuracao'
                      ? 'Revisar rodada'
                      : 'Abrir rodada atual',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    onVerClassificacao,
                icon:
                    const Icon(
                  Icons.leaderboard,
                ),
                label:
                    const Text(
                  'Ver classificação',
                ),
              ),
            ),

            if (statusRodada ==
                    'finalizada' &&
                !_ultimaRodada) ...[
              const SizedBox(
                height: 12,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      () =>
                          _gerarProximaRodada(
                    context,
                  ),
                  icon:
                      const Icon(
                    Icons.next_plan,
                  ),
                  label:
                      Text(
                    'Gerar Rodada ${torneio.rodadaAtual + 1}',
                  ),
                ),
              ),
            ],

            if (statusRodada ==
                    'finalizada' &&
                _ultimaRodada) ...[
              const SizedBox(
                height: 16,
              ),

              const Divider(),

              const SizedBox(
                height: 16,
              ),

              const Text(
                'Todas as rodadas foram concluídas.',
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 12,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      () =>
                          _finalizarTorneio(
                    context,
                  ),
                  icon:
                      const Icon(
                    Icons
                        .emoji_events,
                  ),
                  label:
                      const Text(
                    'Finalizar torneio',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardTorneioFinalizado
    extends StatelessWidget {
  final VoidCallback
      onVerClassificacao;

  const _CardTorneioFinalizado({
    required this.onVerClassificacao,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.emoji_events,
              size: 52,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              'Torneio finalizado',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleLarge,
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Todas as rodadas foram concluídas e a classificação final está disponível.',
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    onVerClassificacao,
                icon:
                    const Icon(
                  Icons.leaderboard,
                ),
                label:
                    const Text(
                  'Ver classificação final',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLinha
    extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const _InfoLinha({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icone,
          size: 20,
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                titulo,
                style:
                    Theme.of(
                      context,
                    )
                        .textTheme
                        .bodySmall,
              ),

              Text(
                valor,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumoParticipantes
    extends StatelessWidget {
  final String titulo;
  final int quantidade;

  const _ResumoParticipantes({
    required this.titulo,
    required this.quantidade,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        border: Border.all(
          color:
              Theme.of(context)
                  .dividerColor,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child: Column(
        children: [
          Text(
            quantidade
                .toString(),
            style:
                Theme.of(
                  context,
                )
                    .textTheme
                    .headlineSmall,
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            titulo,
          ),
        ],
      ),
    );
  }
}