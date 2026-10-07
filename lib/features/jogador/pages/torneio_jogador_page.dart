import 'package:flutter/material.dart';

import '../../../core/session/usuario_session.dart';
import '../../partida/models/partida_model.dart';
import '../../partida/services/partida_service.dart';
import '../models/torneio_jogador_model.dart';
import '../../torneio/models/torneio_model.dart';
import '../../torneio/services/torneio_service.dart';

class TorneioJogadorPage extends StatefulWidget {
  final TorneioJogadorModel item;
  final TorneioService _torneioService = TorneioService();

  const TorneioJogadorPage({
    super.key,
    required this.item,
  });

  @override
  State<TorneioJogadorPage> createState() =>
      _TorneioJogadorPageState();
}

class _TorneioJogadorPageState
    extends State<TorneioJogadorPage> {
  final PartidaService _partidaService =
      PartidaService();

  PartidaModel? _partida;

  bool _carregando = true;

  @override
  void initState() {
    super.initState();

    _carregarPartida();
  }

  Future<void> _carregarPartida() async {
    final usuario =
        UsuarioSession.usuario;

    final torneio =
        widget.item.torneio;

    if (usuario == null) {
      setState(() {
        _carregando = false;
      });

      return;
    }

    if (torneio.rodadaAtual <= 0) {
      setState(() {
        _carregando = false;
      });

      return;
    }

    try {
      final partida =
          await _partidaService.buscarPartidaDoJogador(
        torneioId: torneio.id,
        rodada: torneio.rodadaAtual,
        jogadorUid: usuario.uid,
      );

      if (!mounted) return;

      setState(() {
        _partida = partida;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar sua partida.',
          ),
        ),
      );
    }
  }

  String _nomeAdversario(
    PartidaModel partida,
    String jogadorUid,
  ) {
    if (partida.bye) {
      return 'BYE';
    }

    if (partida.jogador1Uid ==
        jogadorUid) {
      return partida.jogador2Nome ??
          'Adversário';
    }

    return partida.jogador1Nome;
  }

  @override
  Widget build(BuildContext context) {
    final usuario =
        UsuarioSession.usuario;

    final item =
        widget.item;

    final torneio =
        item.torneio;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          torneio.nome,
        ),
      ),
      body: _carregando
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.all(16),
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
                          torneio.nome,
                          style:
                              Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Text(
                          'Formato: ${torneio.formato.toUpperCase()}',
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          'Rodada: ${torneio.rodadaAtual}/${torneio.quantidadeRodadas}',
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          _statusInscricao(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                if (item.status !=
                    'aprovado')
                  _AguardandoAprovacao(
                    status: item.status,
                  )
                else if (torneio.status ==
                    'inscricoes')
                  const _AguardandoRodada(
                    mensagem:
                        'O torneio ainda não foi iniciado.',
                  )
                else if (_partida == null)
                  const _AguardandoRodada(
                    mensagem:
                        'Sua partida ainda não foi definida.',
                  )
                else if (_partida!.bye)
                  _ByeCard(
                    jogadorNome:
                        usuario?.nome ??
                            'Jogador',
                    rodada:
                        torneio.rodadaAtual,
                  )
                else
                  _PartidaCard(
                    partida: _partida!,
                    jogadorUid:
                        usuario?.uid ?? '',
                    adversario:
                        _nomeAdversario(
                      _partida!,
                      usuario?.uid ?? '',
                    ),
                    rodada:
                        torneio.rodadaAtual,
                  ),
              ],
            ),
    );
  }

  String _statusInscricao() {
    switch (widget.item.status) {
      case 'aprovado':
        return 'Inscrição confirmada';

      case 'recusado':
        return 'Inscrição recusada';

      default:
        return 'Aguardando aprovação';
    }
  }
}

class _PartidaCard extends StatelessWidget {
  final PartidaModel partida;
  final String jogadorUid;
  final String adversario;
  final int rodada;

  const _PartidaCard({
    required this.partida,
    required this.jogadorUid,
    required this.adversario,
    required this.rodada,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'RODADA $rodada',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium,
            ),

            const SizedBox(height: 8),

            Text(
              'Mesa ${partida.mesa}',
              style:
                  Theme.of(context)
                      .textTheme
                      .headlineSmall,
            ),

            const SizedBox(height: 28),

            const Icon(
              Icons.sports_esports,
              size: 40,
            ),

            const SizedBox(height: 20),

            Text(
              adversario,
              style:
                  Theme.of(context)
                      .textTheme
                      .headlineSmall,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'Seu adversário',
            ),

            const SizedBox(height: 28),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'O lançamento do resultado será implementado na próxima etapa.',
                      ),
                    ),
                  );
                },
                icon:
                    const Icon(
                  Icons.edit_note,
                ),
                label:
                    const Text(
                  'Informar resultado',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ByeCard extends StatelessWidget {
  final String jogadorNome;
  final int rodada;

  const _ByeCard({
    required this.jogadorNome,
    required this.rodada,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.skip_next,
              size: 48,
            ),

            const SizedBox(height: 16),

            Text(
              'RODADA $rodada',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium,
            ),

            const SizedBox(height: 16),

            Text(
              '$jogadorNome recebeu BYE.',
              style:
                  Theme.of(context)
                      .textTheme
                      .titleLarge,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 8),

            const Text(
              'Você não possui adversário nesta rodada.',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AguardandoRodada
    extends StatelessWidget {
  final String mensagem;

  const _AguardandoRodada({
    required this.mensagem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.hourglass_empty,
              size: 42,
            ),

            const SizedBox(height: 16),

            Text(
              mensagem,
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AguardandoAprovacao
    extends StatelessWidget {
  final String status;

  const _AguardandoAprovacao({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'recusado') {
      return const Card(
        child: Padding(
          padding:
              EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.cancel_outlined,
                size: 42,
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                'Sua inscrição foi recusada.',
                textAlign:
                    TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return const Card(
      child: Padding(
        padding:
            EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.schedule,
              size: 42,
            ),
            SizedBox(
              height: 16,
            ),
            Text(
              'Aguardando aprovação do organizador.',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}