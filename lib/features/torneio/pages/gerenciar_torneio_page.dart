import 'package:flutter/material.dart';

import '../models/torneio_model.dart';
import '../services/torneio_service.dart';

import '../../jogador/models/jogador_torneio_model.dart';
import '../../jogador/services/jogador_torneio_service.dart';
import '../../jogador/pages/gerenciar_jogadores_page.dart';

import '../../partida/pages/montar_primeira_rodada_page.dart';
import '../../partida/pages/gerenciar_rodada_page.dart';
import '../../partida/services/rodada_service.dart';

class GerenciarTorneioPage extends StatelessWidget {
  final TorneioModel torneio;

  const GerenciarTorneioPage({
    super.key,
    required this.torneio,
  });

  String _formatarData(
    DateTime data,
  ) {
    final dia =
        data.day.toString().padLeft(2, '0');

    final mes =
        data.month.toString().padLeft(2, '0');

    final ano =
        data.year.toString();

    return '$dia/$mes/$ano';
  }

  String _formatarHorario(
    DateTime data,
  ) {
    final hora =
        data.hour.toString().padLeft(2, '0');

    final minuto =
        data.minute.toString().padLeft(2, '0');

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

      if (!context.mounted) return;

      if (resultado ==
          'jogadores_insuficientes') {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'São necessários pelo menos 2 jogadores aprovados.',
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
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível iniciar o torneio.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final TorneioService torneioService =
        TorneioService();

    return StreamBuilder<TorneioModel?>(
      stream:
          torneioService.observarTorneio(
        torneio.id,
      ),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
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
            snapshot.data ?? torneio;

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
    final JogadorTorneioService jogadorService =
        JogadorTorneioService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          torneioAtual.nome,
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      torneioAtual.nome,
                      style:
                          Theme.of(context)
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
                          torneioAtual.codigo,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _InfoLinha(
                      icone:
                          Icons.calendar_month,
                      titulo:
                          'Data',
                      valor:
                          _formatarData(
                        torneioAtual.dataHora,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _InfoLinha(
                      icone:
                          Icons.access_time,
                      titulo:
                          'Horário',
                      valor:
                          _formatarHorario(
                        torneioAtual.dataHora,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _InfoLinha(
                      icone:
                          Icons.sports_esports,
                      titulo:
                          'Formato',
                      valor:
                          torneioAtual.formato
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
                          Icons.info_outline,
                      titulo:
                          'Status',
                      valor:
                          _formatarStatus(
                        torneioAtual.status,
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
                List<JogadorTorneioModel>>(
              stream:
                  jogadorService.listarJogadores(
                torneioAtual.id,
              ),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(24),
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(16),
                      child: Text(
                        'Não foi possível carregar os participantes.',
                      ),
                    ),
                  );
                }

                final jogadores =
                    snapshot.data ?? [];

                final aprovados =
                    jogadores
                        .where(
                          (jogador) =>
                              jogador.status ==
                              'aprovado',
                        )
                        .length;

                final pendentes =
                    jogadores
                        .where(
                          (jogador) =>
                              jogador.status ==
                              'pendente',
                        )
                        .length;

                return Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
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
                              width: 12,
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
                          height: 16,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
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
                              Icons.people,
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
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
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
                          onPressed: () =>
                              _iniciarTorneio(
                            context,
                            torneioAtual,
                          ),
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
                      torneioAtual.rodadaAtual,
                ),
                builder: (
                  context,
                  snapshot,
                ) {
                  return _CardRodadaAtual(
                    torneio:
                        torneioAtual,
                    statusRodada:
                        snapshot.data,
                  );
                },
              )
            else if (torneioAtual.status ==
                'finalizado')
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 48,
                      ),

                      SizedBox(
                        height: 12,
                      ),

                      Text(
                        'Torneio finalizado.',
                      ),
                    ],
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

  const _CardRodadaAtual({
    required this.torneio,
    required this.statusRodada,
  });

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

  Future<void> _gerarProximaRodada(
    BuildContext context,
  ) async {
    try {
      final resultado =
          await RodadaService()
              .gerarProximaRodada(
        torneioId:
            torneio.id,
        rodadaAtual:
            torneio.rodadaAtual,
      );

      if (!context.mounted) return;

      switch (resultado) {
        case 'ok':
          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                'Rodada ${torneio.rodadaAtual + 1} gerada. Revise os confrontos antes de iniciar.',
              ),
            ),
          );

          break;

        case 'ultima_rodada':
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'O torneio já chegou à última rodada.',
              ),
            ),
          );

          break;

        case 'rodada_ja_existe':
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'A próxima rodada já existe.',
              ),
            ),
          );

          break;

        case 'rodada_nao_finalizada':
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Finalize a rodada atual antes de gerar a próxima.',
              ),
            ),
          );

          break;

        default:
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível gerar a próxima rodada.',
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
            'Não foi possível gerar a próxima rodada.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ultimaRodada =
        torneio.rodadaAtual >=
        torneio.quantidadeRodadas;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GerenciarRodadaPage(
                        torneioId:
                            torneio.id,
                        nomeTorneio:
                            torneio.nome,
                        rodada:
                            torneio.rodadaAtual,
                        formato:
                            torneio.formato,
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

            if (statusRodada ==
                    'finalizada' &&
                !ultimaRodada) ...[
              const SizedBox(
                height: 12,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed: () =>
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
                ultimaRodada) ...[
              const SizedBox(
                height: 16,
              ),

              const Text(
                'Todas as rodadas foram concluídas.',
                textAlign:
                    TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const _InfoLinha({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
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
                CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style:
                    Theme.of(context)
                        .textTheme
                        .bodySmall,
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
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              Theme.of(context)
                  .dividerColor,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            quantidade.toString(),
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
          ),
        ],
      ),
    );
  }
}