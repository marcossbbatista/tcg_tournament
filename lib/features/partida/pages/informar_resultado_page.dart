import 'package:tcg_tournament/core/responsive/responsive_body.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';

import '../../../core/session/usuario_session.dart';
import '../models/partida_model.dart';
import '../services/partida_service.dart';

class InformarResultadoPage extends StatefulWidget {
  final String torneioId;
  final int rodada;
  final String formato;
  final PartidaModel partida;

  const InformarResultadoPage({
    super.key,
    required this.torneioId,
    required this.rodada,
    required this.formato,
    required this.partida,
  });

  @override
  State<InformarResultadoPage> createState() =>
      _InformarResultadoPageState();
}

class _InformarResultadoPageState
    extends State<InformarResultadoPage> {
  final PartidaService _service =
      PartidaService();

  int? _placarJogador1;
  int? _placarJogador2;

  bool _salvando = false;
  ResultadoPartida? _resultadoEspecial;

  List<_OpcaoResultado> _opcoes() {
    if (widget.formato == 'md1') {
      return const [
        _OpcaoResultado(
          placarJogador1: 1,
          placarJogador2: 0,
        ),
        _OpcaoResultado(
          placarJogador1: 0,
          placarJogador2: 1,
        ),
        _OpcaoResultado(
          placarJogador1: 1,
          placarJogador2: 1,
        ),
      ];
    }

    return const [
      _OpcaoResultado(
        placarJogador1: 2,
        placarJogador2: 0,
      ),
      _OpcaoResultado(
        placarJogador1: 2,
        placarJogador2: 1,
      ),
      _OpcaoResultado(
        placarJogador1: 1,
        placarJogador2: 2,
      ),
      _OpcaoResultado(
        placarJogador1: 0,
        placarJogador2: 2,
      ),
      _OpcaoResultado(
        placarJogador1: 1,
        placarJogador2: 1,
      ),
    ];
  }

  Future<void> _salvar() async {
    if (_resultadoEspecial == null && (_placarJogador1 == null ||
        _placarJogador2 == null)) {
      _mostrarMensagem(
        'Selecione o resultado da partida.',
      );

      return;
    }

    final usuario =
        UsuarioSession.usuario;

    if (usuario == null) {
      _mostrarMensagem(
        'Usuário não identificado.',
      );

      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await _service.informarResultado(
        torneioId: widget.torneioId,
        rodada: widget.rodada,
        partidaId: widget.partida.id,
        placarJogador1: _placarJogador1 ?? 0,
        placarJogador2: _placarJogador2 ?? 0,
        informadoPor: usuario.uid,
        resultado: _resultadoEspecial,
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível informar o resultado.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  void _mostrarMensagem(
    String mensagem,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partida =
        widget.partida;

    return TcgTheme.wrap(Scaffold(
      appBar: AppBar(
        title: const Text(
          'Informar resultado',
        ),
      ),
      body: ResponsiveBody(maxWidth: 1080, child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          TcgHero(title: 'Mesa ${partida.mesa}', subtitle: 'Selecione o placar e envie para confirmação.', icon: Icons.scoreboard_rounded),
          Text(
            'Mesa ${partida.mesa}',
            style:
                Theme.of(context)
                    .textTheme
                    .titleLarge,
            textAlign:
                TextAlign.center,
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      partida.jogador1Nome,
                      style:
                          Theme.of(context)
                              .textTheme
                              .titleMedium,
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Text(
                  'X',
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    Text(
                      partida.jogador2Nome ??
                          '',
                      style:
                          Theme.of(context)
                              .textTheme
                              .titleMedium,
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            'Selecione o resultado',
            style:
                Theme.of(context)
                    .textTheme
                    .titleMedium,
          ),

          const SizedBox(height: 12),

          ..._opcoes().where((opcao) => widget.partida.fase != 'topcut' ||
              opcao.placarJogador1 != opcao.placarJogador2).map(
            (opcao) {
              final selecionado =
                  _placarJogador1 ==
                          opcao
                              .placarJogador1 &&
                      _placarJogador2 ==
                          opcao
                              .placarJogador2;

              return Card(
                child: RadioListTile<bool>(
                  value: true,
                  groupValue:
                      selecionado
                          ? true
                          : null,
                  title: Text(
                    '${partida.jogador1Nome} '
                    '${opcao.placarJogador1} x '
                    '${opcao.placarJogador2} '
                    '${partida.jogador2Nome}',
                  ),
                  onChanged: (_) {
                    setState(() {
                      _resultadoEspecial = null;
                      _placarJogador1 =
                          opcao
                              .placarJogador1;

                      _placarJogador2 =
                          opcao
                              .placarJogador2;
                    });
                  },
                ),
              );
            },
          ),

          if (UsuarioSession.ehAdm) ...[
            const SizedBox(height: 12),
            const Text('Decisão administrativa'),
            DropdownButtonFormField<ResultadoPartida>(
              value: _resultadoEspecial,
              hint: const Text('W.O. ou derrota dupla'),
              items: [
                const DropdownMenuItem(value: ResultadoPartida.woJogador1,
                    child: Text('W.O. Jogador 1 (vitória do Jogador 2)')),
                const DropdownMenuItem(value: ResultadoPartida.woJogador2,
                    child: Text('W.O. Jogador 2 (vitória do Jogador 1)')),
                if (widget.partida.fase != 'topcut')
                  const DropdownMenuItem(value: ResultadoPartida.derrotaDupla,
                      child: Text('Derrota dupla')),
              ],
              onChanged: (v) => setState(() {
                _resultadoEspecial = v;
                _placarJogador1 = null;
                _placarJogador2 = null;
              }),
            ),
          ],
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed:
                _salvando
                    ? null
                    : _salvar,
            icon: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.check,
                  ),
            label: const Text(
              'Enviar resultado',
            ),
          ),
        ],
      )),
    ));
  }
}

class _OpcaoResultado {
  final int placarJogador1;
  final int placarJogador2;

  const _OpcaoResultado({
    required this.placarJogador1,
    required this.placarJogador2,
  });
}