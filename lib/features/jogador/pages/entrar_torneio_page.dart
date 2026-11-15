import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:tcg_tournament/features/jogador/service/jogador_torneio_service.dart';

import '../../../core/session/usuario_session.dart';
import '../../auth/pages/perfil_page.dart';
import '../../torneio/models/torneio_model.dart';

class EntrarTorneioPage extends StatefulWidget {
  const EntrarTorneioPage({super.key});

  @override
  State<EntrarTorneioPage> createState() => _EntrarTorneioPageState();
}

class _EntrarTorneioPageState extends State<EntrarTorneioPage> {
  final TextEditingController _codigoController = TextEditingController();

  final JogadorTorneioService _service = JogadorTorneioService();

  TorneioModel? _torneio;

  bool _buscando = false;
  bool _solicitando = false;

  @override
  void dispose() {
    _codigoController.dispose();

    super.dispose();
  }

  // ============================================================
  // Lógica
  // ============================================================

  Future<void> _buscarTorneio() async {
    if (_buscando) return;

    final codigo = _codigoController.text.trim();

    if (codigo.isEmpty) {
      _mostrarMensagem('Informe o código do torneio.');

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _buscando = true;
      _torneio = null;
    });

    try {
      final torneio = await _service.buscarTorneioPorCodigo(codigo);

      if (!mounted) return;

      if (torneio == null) {
        _mostrarMensagem('Torneio não encontrado.');

        return;
      }

      setState(() {
        _torneio = torneio;
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem('Não foi possível localizar o torneio.');
    } finally {
      if (mounted) {
        setState(() {
          _buscando = false;
        });
      }
    }
  }

  Future<void> _abrirPerfil() async {
    FocusScope.of(context).unfocus();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilPage()),
    );

    // Atualiza o aviso de perfil incompleto ao voltar.
    if (mounted) setState(() {});
  }

  Future<void> _solicitarParticipacao() async {
    final torneio = _torneio;
    final usuario = UsuarioSession.usuario;

    if (torneio == null) return;

    if (usuario == null) {
      _mostrarMensagem('Usuário não identificado.');

      return;
    }

    if (!usuario.possuiDadosOficiais) {
      final completar = await showDialog<bool>(
        context: context,
        builder: (context) => Theme(
          data: TcgTheme.data(),
          child: AlertDialog(
            title: const Text('Complete seu perfil'),
            content: const Text('Informe primeiro nome, sobrenome, '
                'Pokémon Player ID e nascimento para participar de torneios TOM.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Agora não'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Meu perfil'),
              ),
            ],
          ),
        ),
      );
      if (completar == true && mounted) {
        await _abrirPerfil();
      }
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _solicitando = true;
    });

    try {
      final resultado = await _service.solicitarParticipacao(
        torneio: torneio,
        usuario: usuario,
      );

      if (!mounted) return;

      switch (resultado) {
        case 'pendente':
          _mostrarMensagem(
            'Solicitação enviada. Aguarde a aprovação do organizador.',
          );

          Navigator.pop(context, true);

          break;

        case 'aprovado':
          _mostrarMensagem('Você já está aprovado neste torneio.');

          Navigator.pop(context, true);

          break;

        case 'recusado':
          _mostrarMensagem('Sua inscrição neste torneio foi recusada.');

          break;

        case 'inscricoes_encerradas':
          _mostrarMensagem('As inscrições deste torneio estão encerradas.');

          break;

        default:
          _mostrarMensagem('Você já possui uma inscrição neste torneio.');
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem('Não foi possível solicitar a participação: $e');
    } finally {
      if (mounted) {
        setState(() {
          _solicitando = false;
        });
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');

    final mes = data.month.toString().padLeft(2, '0');

    final ano = data.year;

    final hora = data.hour.toString().padLeft(2, '0');

    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  // ============================================================
  // Peças de layout
  // ============================================================

  Widget _cabecalho() {
    return TcgGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: TcgTheme.gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x553DDC84),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.confirmation_number_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Entrar em torneio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Digite o código compartilhado pelo organizador para encontrar '
            'o torneio.',
            style: TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _avisoPerfil() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _abrirPerfil,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x1FFFB74D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x55FFB74D)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFFFFB74D)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Complete seu perfil para poder solicitar participação.',
                  style: TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Color(0xFFFFB74D)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoCodigo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'CÓDIGO DO TORNEIO',
          style: TextStyle(
            color: TcgTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _codigoController,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.search,
          textAlign: TextAlign.center,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
          decoration: InputDecoration(
            hintText: 'TCG4387',
            hintStyle: const TextStyle(
              color: Colors.white24,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 22),
            suffixIcon: _codigoController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _codigoController.clear();
                      setState(() => _torneio = null);
                    },
                  ),
          ),
          onChanged: (_) {
            // O código mudou: o resultado antigo deixa de valer.
            setState(() => _torneio = null);
          },
          onSubmitted: (_) => _buscarTorneio(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Exemplo: TCG4387',
          textAlign: TextAlign.center,
          style: TextStyle(color: TcgTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        TcgGradientButton(
          texto: 'Buscar torneio',
          icone: Icons.search,
          carregando: _buscando,
          onPressed: _buscarTorneio,
        ),
      ],
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final usuario = UsuarioSession.usuario;
    final perfilIncompleto =
        usuario != null && !usuario.possuiDadosOficiais;

    return TcgTheme.wrap(
      Scaffold(
        backgroundColor: TcgTheme.fundo,
        resizeToAvoidBottomInset: true,
        body: TcgBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Seta fixa no topo
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: IconButton(
                      tooltip: 'Voltar',
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Só esta área rola
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _cabecalho(),

                            if (perfilIncompleto) _avisoPerfil(),

                            const SizedBox(height: 28),

                            _campoCodigo(),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _torneio == null
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      key: ValueKey(_torneio!.id),
                                      padding: const EdgeInsets.only(top: 32),
                                      child: _TorneioEncontradoCard(
                                        torneio: _torneio!,
                                        dataFormatada:
                                            _formatarData(_torneio!.dataHora),
                                        solicitando: _solicitando,
                                        onParticipar: _solicitarParticipacao,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Cartão do torneio encontrado
// ============================================================

class _TorneioEncontradoCard extends StatelessWidget {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: TcgTheme.verde),
            SizedBox(width: 8),
            Text(
              'TORNEIO ENCONTRADO',
              style: TextStyle(
                color: TcgTheme.verde,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TcgGlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: TcgTheme.gradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      torneio.nome,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: TcgStatusBadge(status: torneio.status),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icone: Icons.calendar_month,
                    texto: dataFormatada,
                  ),
                  _InfoChip(
                    icone: Icons.sports_esports,
                    texto: torneio.formato.toUpperCase(),
                  ),
                  _InfoChip(
                    icone: Icons.repeat,
                    texto: '${torneio.quantidadeRodadas} rodadas',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.key, size: 18, color: TcgTheme.verde),
                  const SizedBox(width: 10),
                  const Text(
                    'Código',
                    style: TextStyle(color: TcgTheme.muted),
                  ),
                  const Spacer(),
                  Text(
                    torneio.codigo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TcgGradientButton(
                texto: 'Solicitar participação',
                icone: Icons.person_add,
                carregando: solicitando,
                onPressed: solicitando ? null : onParticipar,
              ),
              const SizedBox(height: 10),
              const Text(
                'O organizador precisa aprovar a sua solicitação.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TcgTheme.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _InfoChip({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: TcgTheme.verde),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}