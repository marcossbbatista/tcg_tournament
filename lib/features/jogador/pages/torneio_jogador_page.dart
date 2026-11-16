import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';

import '../../../core/session/usuario_session.dart';
import '../../partida/models/partida_model.dart';
import '../../partida/pages/informar_resultado_page.dart';
import '../../partida/services/partida_service.dart';
import '../models/torneio_jogador_model.dart';

const Color _amarelo = Color(0xFFFFB74D);
const Color _vermelho = Color(0xFFFF6B6B);

class TorneioJogadorPage extends StatefulWidget {
  final TorneioJogadorModel item;

  const TorneioJogadorPage({
    super.key,
    required this.item,
  });

  @override
  State<TorneioJogadorPage> createState() => _TorneioJogadorPageState();
}

class _TorneioJogadorPageState extends State<TorneioJogadorPage> {
  final PartidaService _partidaService = PartidaService();

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

  Color _corInscricao() {
    switch (widget.item.status) {
      case 'aprovado':
        return TcgTheme.verde;

      case 'recusado':
        return _vermelho;

      default:
        return _amarelo;
    }
  }

  // ============================================================
  // Estrutura
  // ============================================================

  Widget _estrutura(Widget corpo) {
    return TcgTheme.wrap(
      Scaffold(
        backgroundColor: TcgTheme.fundo,
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(child: corpo),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rotulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: TcgTheme.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _cabecalho() {
    final torneio = widget.item.torneio;
    final cor = _corInscricao();

    final faseEliminatoria = torneio.rodadaAtual > torneio.quantidadeRodadas;

    return TcgGlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: cor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: cor),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            _statusInscricao(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            torneio.nome,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Confira sua inscrição e acompanhe sua partida.',
            style: TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icone: Icons.sports_esports,
                texto: torneio.formato.toUpperCase(),
              ),
              _InfoChip(
                icone: Icons.flag,
                texto: faseEliminatoria
                    ? 'Fase eliminatória'
                    : 'Rodada ${torneio.rodadaAtual}/${torneio.quantidadeRodadas}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _conteudoPartida(
    TorneioJogadorModel item,
    dynamic usuario,
  ) {
    final torneio = item.torneio;

    if (item.status != 'aprovado') {
      return _AguardandoAprovacao(status: item.status);
    }

    if (torneio.status == 'inscricoes') {
      return const _EstadoCard(
        icone: Icons.hourglass_empty,
        mensagem: 'O torneio ainda não foi iniciado.',
        cor: _amarelo,
      );
    }

    return StreamBuilder<PartidaModel?>(
      stream: _partidaService.observarPartidaDoJogador(
        torneioId: torneio.id,
        rodada: torneio.rodadaAtual,
        jogadorUid: usuario.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const _EstadoCard(
            icone: Icons.cloud_off_outlined,
            mensagem: 'Não foi possível carregar sua partida.',
            cor: _vermelho,
          );
        }

        final partida = snapshot.data;

        if (partida == null) {
          return const _EstadoCard(
            icone: Icons.hourglass_empty,
            mensagem: 'Sua partida ainda não foi definida.',
            cor: _amarelo,
          );
        }

        if (partida.bye) {
          return _ByeCard(
            jogadorNome: usuario.nome,
            rodada: torneio.rodadaAtual,
          );
        }

        return _PartidaCard(
          partida: partida,
          jogadorUid: usuario.uid,
          jogadorNome: usuario.nome,
          rodada: torneio.rodadaAtual,
          formato: torneio.formato,
          torneioId: torneio.id,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = UsuarioSession.usuario;

    if (usuario == null) {
      return _estrutura(
        const Center(
          child: Text(
            'Usuário não identificado.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return _estrutura(
      Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _cabecalho(),
                const SizedBox(height: 28),
                _rotulo('Sua partida'),
                _conteudoPartida(widget.item, usuario),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Chip de informação
// ============================================================

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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

// ============================================================
// Avatar com iniciais (pronto para receber foto)
// ============================================================

class _AvatarJogador extends StatelessWidget {
  final String nome;
  final double tamanho;
  final Color cor;

  /// Quando existir foto de perfil, é só passar a URL aqui.
  final String? fotoUrl;

  const _AvatarJogador({
    required this.nome,
    required this.tamanho,
    required this.cor,
    this.fotoUrl,
  });

  String get _iniciais {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();

    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  Widget _texto() {
    return Text(
      _iniciais,
      style: TextStyle(
        color: Colors.white,
        fontSize: tamanho * 0.36,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoUrl != null && fotoUrl!.isNotEmpty;

    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor.withValues(alpha: 0.18),
        border: Border.all(color: cor, width: 2),
      ),
      child: temFoto
          ? ClipOval(
              child: Image.network(
                fotoUrl!,
                width: tamanho,
                height: tamanho,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _texto(),
              ),
            )
          : _texto(),
    );
  }
}

// ============================================================
// Estados simples (aguardando, erro)
// ============================================================

class _EstadoCard extends StatelessWidget {
  final IconData icone;
  final String mensagem;
  final Color cor;

  const _EstadoCard({
    required this.icone,
    required this.mensagem,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return TcgGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cor.withValues(alpha: 0.15),
            ),
            child: Icon(icone, size: 30, color: cor),
          ),
          const SizedBox(height: 16),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AguardandoAprovacao extends StatelessWidget {
  final String status;

  const _AguardandoAprovacao({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'recusado') {
      return const _EstadoCard(
        icone: Icons.cancel_outlined,
        mensagem: 'Sua inscrição foi recusada.',
        cor: _vermelho,
      );
    }

    return const _EstadoCard(
      icone: Icons.schedule,
      mensagem: 'Aguardando aprovação do organizador.',
      cor: _amarelo,
    );
  }
}

// ============================================================
// BYE
// ============================================================

class _ByeCard extends StatelessWidget {
  final String jogadorNome;
  final int rodada;

  const _ByeCard({
    required this.jogadorNome,
    required this.rodada,
  });

  @override
  Widget build(BuildContext context) {
    return TcgGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _Selo(texto: 'RODADA $rodada', cor: TcgTheme.verde),
          const SizedBox(height: 18),
          _AvatarJogador(nome: jogadorNome, tamanho: 72, cor: _amarelo),
          const SizedBox(height: 16),
          Text(
            '$jogadorNome recebeu BYE.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Você não possui adversário nesta rodada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          const _Selo(texto: 'BYE', cor: _amarelo),
        ],
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  final String texto;
  final Color cor;

  const _Selo({required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ============================================================
// Partida
// ============================================================

class _PartidaCard extends StatelessWidget {
  final PartidaModel partida;
  final String jogadorUid;
  final String jogadorNome;
  final int rodada;
  final String formato;
  final String torneioId;

  const _PartidaCard({
    required this.partida,
    required this.jogadorUid,
    required this.jogadorNome,
    required this.rodada,
    required this.formato,
    required this.torneioId,
  });

  bool get _souJogador1 => partida.jogador1Uid == jogadorUid;

  String get adversario {
    if (_souJogador1) {
      return partida.jogador2Nome ?? 'Adversário';
    }

    return partida.jogador1Nome;
  }

  bool get fuiEuQueInformei => partida.resultadoInformadoPor == jogadorUid;

  int get _meuPlacar =>
      _souJogador1 ? partida.placarJogador1 : partida.placarJogador2;

  int get _placarDele =>
      _souJogador1 ? partida.placarJogador2 : partida.placarJogador1;

  @override
  Widget build(BuildContext context) {
    return TcgGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Selo(texto: 'RODADA $rodada', cor: TcgTheme.verde),
              const Spacer(),
              _Selo(texto: 'MESA ${partida.mesa}', cor: TcgTheme.verde),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LadoJogador(
                nome: jogadorNome,
                legenda: 'Você',
                cor: TcgTheme.verde,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x1AFFFFFF),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _LadoJogador(
                nome: adversario,
                legenda: 'Adversário',
                cor: Colors.white54,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          _conteudoStatus(context),
        ],
      ),
    );
  }

  Widget _placar({Color cor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$_meuPlacar',
          style: TextStyle(
            color: cor,
            fontSize: 44,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '–',
            style: TextStyle(color: Colors.white38, fontSize: 32),
          ),
        ),
        Text(
          '$_placarDele',
          style: TextStyle(
            color: cor,
            fontSize: 44,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _caixa(IconData icone, String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: cor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudoStatus(BuildContext context) {
    if (partida.status == 'em_andamento') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Jogue sua partida e depois informe o resultado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          TcgGradientButton(
            texto: 'Informar resultado',
            icone: Icons.edit_note,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InformarResultadoPage(
                    torneioId: torneioId,
                    rodada: rodada,
                    formato: formato,
                    partida: partida,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    if (partida.status == 'aguardando_confirmacao') {
      if (fuiEuQueInformei) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _placar(),
            const SizedBox(height: 16),
            _caixa(
              Icons.schedule,
              'Aguardando confirmação do adversário.',
              _amarelo,
            ),
          ],
        );
      }

      return _ConfirmarResultado(
        torneioId: torneioId,
        rodada: rodada,
        partida: partida,
        meuPlacar: _meuPlacar,
        placarDele: _placarDele,
      );
    }

    if (partida.status == 'contestada') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _placar(),
          const SizedBox(height: 16),
          _caixa(
            Icons.warning_amber,
            'Resultado contestado. Aguarde a decisão do organizador.',
            _vermelho,
          ),
        ],
      );
    }

    if (partida.status == 'finalizada') {
      final String texto;
      final Color cor;

      if (_meuPlacar > _placarDele) {
        texto = 'Vitória';
        cor = TcgTheme.verde;
      } else if (_meuPlacar < _placarDele) {
        texto = 'Derrota';
        cor = _vermelho;
      } else {
        texto = 'Empate';
        cor = _amarelo;
      }

      return Column(
        children: [
          _placar(cor: cor),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: cor),
                const SizedBox(width: 8),
                Text(
                  '$texto  •  Partida finalizada',
                  style: TextStyle(
                    color: cor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Text(
      partida.status,
      textAlign: TextAlign.center,
      style: const TextStyle(color: TcgTheme.muted),
    );
  }
}

/// Um dos lados da mesa (avatar, nome e legenda).
class _LadoJogador extends StatelessWidget {
  final String nome;
  final String legenda;
  final Color cor;

  const _LadoJogador({
    required this.nome,
    required this.legenda,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          _AvatarJogador(nome: nome, tamanho: 60, cor: cor),
          const SizedBox(height: 10),
          Text(
            nome,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            legenda,
            style: const TextStyle(color: TcgTheme.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Confirmar ou contestar o resultado do adversário
// ============================================================

class _ConfirmarResultado extends StatefulWidget {
  final String torneioId;
  final int rodada;
  final PartidaModel partida;
  final int meuPlacar;
  final int placarDele;

  const _ConfirmarResultado({
    required this.torneioId,
    required this.rodada,
    required this.partida,
    required this.meuPlacar,
    required this.placarDele,
  });

  @override
  State<_ConfirmarResultado> createState() => _ConfirmarResultadoState();
}

class _ConfirmarResultadoState extends State<_ConfirmarResultado> {
  final PartidaService _service = PartidaService();

  bool _processando = false;

  Future<void> _confirmar() async {
    setState(() {
      _processando = true;
    });

    try {
      await _service.confirmarResultado(
        torneioId: widget.torneioId,
        rodada: widget.rodada,
        partidaId: widget.partida.id,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível confirmar o resultado.'),
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
        torneioId: widget.torneioId,
        rodada: widget.rodada,
        partidaId: widget.partida.id,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível contestar o resultado.'),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Seu adversário informou:',
          textAlign: TextAlign.center,
          style: TextStyle(color: TcgTheme.muted),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.meuPlacar}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '–',
                style: TextStyle(color: Colors.white38, fontSize: 32),
              ),
            ),
            Text(
              '${widget.placarDele}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Seu placar à esquerda',
          textAlign: TextAlign.center,
          style: TextStyle(color: TcgTheme.muted, fontSize: 11),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _processando ? null : _contestar,
                child: const Text('Contestar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TcgGradientButton(
                texto: 'Confirmar',
                carregando: _processando,
                onPressed: _processando ? null : _confirmar,
              ),
            ),
          ],
        ),
      ],
    );
  }
}