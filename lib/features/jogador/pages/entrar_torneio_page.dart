import 'package:flutter/material.dart';

import '../../../core/session/usuario_session.dart';
import '../../torneio/models/torneio_model.dart';
import '../services/jogador_torneio_service.dart';

class EntrarTorneioPage extends StatefulWidget {
  const EntrarTorneioPage({
    super.key,
  });

  @override
  State<EntrarTorneioPage> createState() =>
      _EntrarTorneioPageState();
}

class _EntrarTorneioPageState
    extends State<EntrarTorneioPage> {
  final TextEditingController _codigoController =
      TextEditingController();

  final JogadorTorneioService _service =
      JogadorTorneioService();

  TorneioModel? _torneio;

  bool _buscando = false;
  bool _solicitando = false;

  @override
  void dispose() {
    _codigoController.dispose();

    super.dispose();
  }

  Future<void> _buscarTorneio() async {
    final codigo =
        _codigoController.text.trim();

    if (codigo.isEmpty) {
      _mostrarMensagem(
        'Informe o código do torneio.',
      );

      return;
    }

    setState(() {
      _buscando = true;
      _torneio = null;
    });

    try {
      final torneio =
          await _service.buscarTorneioPorCodigo(
        codigo,
      );

      if (!mounted) return;

      if (torneio == null) {
        _mostrarMensagem(
          'Torneio não encontrado.',
        );

        return;
      }

      setState(() {
        _torneio = torneio;
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível localizar o torneio.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _buscando = false;
        });
      }
    }
  }

  Future<void> _solicitarParticipacao() async {
    final torneio = _torneio;
    final usuario = UsuarioSession.usuario;

    if (torneio == null) return;

    if (usuario == null) {
      _mostrarMensagem(
        'Usuário não identificado.',
      );

      return;
    }

    setState(() {
      _solicitando = true;
    });

    try {
      final resultado =
          await _service.solicitarParticipacao(
        torneio: torneio,
        uid: usuario.uid,
        nome: usuario.nome,
        email: usuario.email,
      );

      if (!mounted) return;

      switch (resultado) {
        case 'pendente':
          _mostrarMensagem(
            'Solicitação enviada. Aguarde a aprovação do organizador.',
          );

          Navigator.pop(
            context,
            true,
          );

          break;

        case 'aprovado':
          _mostrarMensagem(
            'Você já está aprovado neste torneio.',
          );

          Navigator.pop(
            context,
            true,
          );

          break;

        case 'recusado':
          _mostrarMensagem(
            'Sua inscrição neste torneio foi recusada.',
          );

          break;

        case 'inscricoes_encerradas':
          _mostrarMensagem(
            'As inscrições deste torneio estão encerradas.',
          );

          break;

        default:
          _mostrarMensagem(
            'Você já possui uma inscrição neste torneio.',
          );
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível solicitar a participação.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _solicitando = false;
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

  String _formatarData(
    DateTime data,
  ) {
    final dia =
        data.day.toString().padLeft(2, '0');

    final mes =
        data.month.toString().padLeft(2, '0');

    final ano = data.year;

    final hora =
        data.hour.toString().padLeft(2, '0');

    final minuto =
        data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Entrar em torneio',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              'Código do torneio',
              style:
                  Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            const Text(
              'Informe o código fornecido pelo organizador.',
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _codigoController,
              textCapitalization:
                  TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Ex.: TCG4387',
                border: OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.key,
                ),
              ),
              onSubmitted: (_) {
                _buscarTorneio();
              },
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed:
                  _buscando ? null : _buscarTorneio,
              icon: _buscando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.search,
                    ),
              label: const Text(
                'Buscar torneio',
              ),
            ),

            if (_torneio != null) ...[
              const SizedBox(height: 32),

              _TorneioEncontradoCard(
                torneio: _torneio!,
                dataFormatada:
                    _formatarData(
                  _torneio!.dataHora,
                ),
                solicitando: _solicitando,
                onParticipar:
                    _solicitarParticipacao,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TorneioEncontradoCard
    extends StatelessWidget {
  final TorneioModel torneio;
  final String dataFormatada;
  final bool solicitando;
  final VoidCallback onParticipar;

  const _TorneioEncontradoCard({
    required this.torneio,
    required this.dataFormatada,
    required this.solicitando,
    required this.onParticipar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              torneio.nome,
              style:
                  Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    dataFormatada,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.sports_esports,
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

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.key,
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

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed:
                  solicitando ? null : onParticipar,
              icon: solicitando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.person_add,
                    ),
              label: const Text(
                'Solicitar participação',
              ),
            ),
          ],
        ),
      ),
    );
  }
}