import 'package:flutter/material.dart';

import '../../../core/session/usuario_session.dart';
import '../../partida/models/partida_model.dart';
import '../../partida/pages/informar_resultado_page.dart';
import '../../partida/services/partida_service.dart';
import '../models/torneio_jogador_model.dart';

class TorneioJogadorPage extends StatefulWidget {
  final TorneioJogadorModel item;

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

  @override
  Widget build(BuildContext context) {
    final usuario = UsuarioSession.usuario;
    final item = widget.item;
    final torneio = item.torneio;

    if (usuario == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Usuário não identificado.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          torneio.nome,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    torneio.nome,
                    style: Theme.of(context)
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

          if (item.status != 'aprovado')
            _AguardandoAprovacao(
              status: item.status,
            )
          else if (torneio.status == 'inscricoes')
            const _AguardandoRodada(
              mensagem:
                  'O torneio ainda não foi iniciado.',
            )
          else
            StreamBuilder<PartidaModel?>(
              stream: _partidaService
                  .observarPartidaDoJogador(
                torneioId: torneio.id,
                rodada: torneio.rodadaAtual,
                jogadorUid: usuario.uid,
              ),
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
                  return const _AguardandoRodada(
                    mensagem:
                        'Não foi possível carregar sua partida.',
                  );
                }

                final partida =
                    snapshot.data;

                if (partida == null) {
                  return const _AguardandoRodada(
                    mensagem:
                        'Sua partida ainda não foi definida.',
                  );
                }

                if (partida.bye) {
                  return _ByeCard(
                    jogadorNome:
                        usuario.nome,
                    rodada:
                        torneio.rodadaAtual,
                  );
                }

                return _PartidaCard(
                  partida: partida,
                  jogadorUid:
                      usuario.uid,
                  rodada:
                      torneio.rodadaAtual,
                  formato:
                      torneio.formato,
                  torneioId:
                      torneio.id,
                );
              },
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
  final int rodada;
  final String formato;
  final String torneioId;

  const _PartidaCard({
    required this.partida,
    required this.jogadorUid,
    required this.rodada,
    required this.formato,
    required this.torneioId,
  });

  String get adversario {
    if (partida.jogador1Uid ==
        jogadorUid) {
      return partida.jogador2Nome ??
          'Adversário';
    }

    return partida.jogador1Nome;
  }

  bool get fuiEuQueInformei =>
      partida.resultadoInformadoPor ==
      jogadorUid;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'RODADA $rodada',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Mesa ${partida.mesa}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),

            const SizedBox(
              height: 24,
            ),

            Text(
              adversario,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(
              height: 4,
            ),

            const Text(
              'Seu adversário',
            ),

            const SizedBox(
              height: 24,
            ),

            _conteudoStatus(
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudoStatus(
    BuildContext context,
  ) {
    if (partida.status ==
        'em_andamento') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    InformarResultadoPage(
                  torneioId:
                      torneioId,
                  rodada:
                      rodada,
                  formato:
                      formato,
                  partida:
                      partida,
                ),
              ),
            );
          },
          icon: const Icon(
            Icons.edit_note,
          ),
          label: const Text(
            'Informar resultado',
          ),
        ),
      );
    }

    if (partida.status ==
        'aguardando_confirmacao') {
      if (fuiEuQueInformei) {
        return Column(
          children: [
            Text(
              '${partida.placarJogador1} x ${partida.placarJogador2}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Aguardando confirmação do adversário.',
              textAlign:
                  TextAlign.center,
            ),
          ],
        );
      }

      return _ConfirmarResultado(
        torneioId: torneioId,
        rodada: rodada,
        partida: partida,
      );
    }

    if (partida.status ==
        'contestada') {
      return Column(
        children: [
          const Icon(
            Icons.warning_amber,
            size: 36,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            '${partida.placarJogador1} x ${partida.placarJogador2}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'Resultado contestado. Aguarde a decisão do organizador.',
            textAlign:
                TextAlign.center,
          ),
        ],
      );
    }

    if (partida.status ==
        'finalizada') {
      return Column(
        children: [
          const Icon(
            Icons.check_circle,
            size: 36,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            '${partida.placarJogador1} x ${partida.placarJogador2}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Partida finalizada',
          ),
        ],
      );
    }

    return Text(
      partida.status,
    );
  }
}

class _ConfirmarResultado
    extends StatefulWidget {
  final String torneioId;
  final int rodada;
  final PartidaModel partida;

  const _ConfirmarResultado({
    required this.torneioId,
    required this.rodada,
    required this.partida,
  });

  @override
  State<_ConfirmarResultado>
      createState() =>
          _ConfirmarResultadoState();
}

class _ConfirmarResultadoState
    extends State<_ConfirmarResultado> {
  final PartidaService _service =
      PartidaService();

  bool _processando = false;

  Future<void> _confirmar() async {
    setState(() {
      _processando = true;
    });

    try {
      await _service.confirmarResultado(
        torneioId:
            widget.torneioId,
        rodada:
            widget.rodada,
        partidaId:
            widget.partida.id,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível confirmar o resultado.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  Future<void> _contestar() async {
    setState(() {
      _processando = true;
    });

    try {
      await _service.contestarResultado(
        torneioId:
            widget.torneioId,
        rodada:
            widget.rodada,
        partidaId:
            widget.partida.id,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível contestar o resultado.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Seu adversário informou:',
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          '${widget.partida.placarJogador1} x ${widget.partida.placarJogador2}',
          style: Theme.of(context)
              .textTheme
              .headlineSmall,
        ),

        const SizedBox(
          height: 20,
        ),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _processando
                        ? null
                        : _contestar,
                child: const Text(
                  'Contestar',
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: ElevatedButton(
                onPressed:
                    _processando
                        ? null
                        : _confirmar,
                child: _processando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirmar',
                      ),
              ),
            ),
          ],
        ),
      ],
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

            const SizedBox(
              height: 16,
            ),

            Text(
              'RODADA $rodada',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              '$jogadorNome recebeu BYE.',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 8,
            ),

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

            const SizedBox(
              height: 16,
            ),

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