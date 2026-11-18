import 'package:flutter/material.dart';

import '../../../core/theme/tcg_theme.dart';
import '../../partida/models/partida_model.dart';
import '../../partida/services/partida_service.dart';
import '../../partida/services/rodada_service.dart';

const Color _amarelo = Color(0xFFFFB74D);
const Color _vermelho = Color(0xFFFF6B6B);
const Color _ouro = Color(0xFFFFD54F);

/// Abre o painel com os confrontos de uma rodada.
///
/// [rodadas] são as rodadas que já começaram (1..rodadaAtual).
/// [quantidadeSwiss] separa as rodadas Swiss das eliminatórias.
Future<void> mostrarDetalhesRodada(
  BuildContext context, {
  required String torneioId,
  required List<int> rodadas,
  required int rodadaInicial,
  required int quantidadeSwiss,
  bool admin = false,
  String? meuUid,
  void Function(int rodada)? onGerenciar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: TcgTheme.card,
    builder: (_) => Theme(
      data: TcgTheme.data(),
      child: _RodadaSheet(
        torneioId: torneioId,
        rodadas: rodadas,
        rodadaInicial: rodadaInicial,
        quantidadeSwiss: quantidadeSwiss,
        admin: admin,
        meuUid: meuUid,
        onGerenciar: onGerenciar,
      ),
    ),
  );
}

// ============================================================
// Helpers de status
// ============================================================

String _statusTexto(String status) {
  switch (status) {
    case 'aguardando':
      return 'Aguardando';
    case 'em_andamento':
      return 'Em andamento';
    case 'aguardando_confirmacao':
      return 'Confirmando';
    case 'finalizada':
      return 'Finalizada';
    case 'contestada':
      return 'Contestada';
    default:
      return status;
  }
}

Color _statusCor(String status) {
  switch (status) {
    case 'finalizada':
      return TcgTheme.verde;
    case 'contestada':
      return _vermelho;
    case 'aguardando_confirmacao':
      return _amarelo;
    case 'em_andamento':
      return Colors.white;
    default:
      return Colors.white54;
  }
}

// ============================================================
// Painel
// ============================================================

class _RodadaSheet extends StatefulWidget {
  final String torneioId;
  final List<int> rodadas;
  final int rodadaInicial;
  final int quantidadeSwiss;
  final bool admin;
  final String? meuUid;
  final void Function(int rodada)? onGerenciar;

  const _RodadaSheet({
    required this.torneioId,
    required this.rodadas,
    required this.rodadaInicial,
    required this.quantidadeSwiss,
    required this.admin,
    required this.meuUid,
    required this.onGerenciar,
  });

  @override
  State<_RodadaSheet> createState() => _RodadaSheetState();
}

class _RodadaSheetState extends State<_RodadaSheet> {
  final GlobalKey _chaveSelecionada = GlobalKey();

  late int _rodada;
  late Stream<String?> _statusStream;
  late Stream<List<PartidaModel>> _partidasStream;

  @override
  void initState() {
    super.initState();

    _rodada = widget.rodadaInicial;
    _assinar();
    _centralizar();
  }

  void _assinar() {
    _statusStream = RodadaService().observarStatusRodada(
      torneioId: widget.torneioId,
      rodada: _rodada,
    );

    _partidasStream = PartidaService().observarPartidasDaRodada(
      torneioId: widget.torneioId,
      rodada: _rodada,
    );
  }

  void _centralizar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexto = _chaveSelecionada.currentContext;

      if (contexto != null) {
        Scrollable.ensureVisible(
          contexto,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  void _trocar(int rodada) {
    if (rodada == _rodada) return;

    setState(() {
      _rodada = rodada;
      _assinar();
    });

    _centralizar();
  }

  String _rotulo(int r) => r <= widget.quantidadeSwiss
      ? 'R$r'
      : 'E${r - widget.quantidadeSwiss}';

  String _titulo(int r) => r <= widget.quantidadeSwiss
      ? 'Rodada $r'
      : 'Eliminatória ${r - widget.quantidadeSwiss}';

  // ============================================================
  // Peças
  // ============================================================

  Widget _seletor() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          for (final r in widget.rodadas) ...[
            GestureDetector(
              key: r == _rodada ? _chaveSelecionada : null,
              onTap: () => _trocar(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: r == _rodada
                      ? const Color(0x263DDC84)
                      : const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: r == _rodada
                        ? TcgTheme.verde
                        : const Color(0x26FFFFFF),
                  ),
                ),
                child: Text(
                  _rotulo(r),
                  style: TextStyle(
                    color: r == _rodada ? TcgTheme.verde : Colors.white70,
                    fontWeight:
                        r == _rodada ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _seloRodada(String? status) {
    String texto;
    Color cor;

    switch (status) {
      case 'configuracao':
        texto = 'Aguardando configuração';
        cor = _amarelo;
        break;
      case 'em_andamento':
        texto = 'Em andamento';
        cor = TcgTheme.verde;
        break;
      case 'finalizada':
        texto = 'Finalizada';
        cor = Colors.white70;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Flexible(
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: cor.withValues(alpha: 0.4)),
        ),
        child: Text(
          texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _cabecalho(String? status, int finalizadas, int total) {
    final fracao = total == 0 ? 0.0 : finalizadas / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _titulo(_rodada),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            _seloRodada(status),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$finalizadas de $total partidas finalizadas',
                  style: const TextStyle(color: TcgTheme.muted, fontSize: 12),
                ),
              ),
              Text(
                '${(fracao * 100).round()}%',
                style: const TextStyle(
                  color: TcgTheme.verde,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fracao,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(TcgTheme.verde),
            ),
          ),
        ],
      ],
    );
  }

  Widget _aviso(IconData icone, String texto, Color cor) {
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

  /// Resumo da sua partida nesta rodada (só na visão do jogador).
  Widget _meuResumo(List<PartidaModel> partidas) {
    final uid = widget.meuUid;

    if (uid == null) return const SizedBox.shrink();

    PartidaModel? minha;

    for (final p in partidas) {
      if (p.jogador1Uid == uid || p.jogador2Uid == uid) {
        minha = p;
        break;
      }
    }

    if (minha == null) return const SizedBox.shrink();

    Widget conteudo;

    if (minha.bye) {
      conteudo = _aviso(
        Icons.skip_next,
        'Você recebeu BYE nesta rodada.',
        _amarelo,
      );
    } else {
      final souJ1 = minha.jogador1Uid == uid;
      final oponente =
          souJ1 ? (minha.jogador2Nome ?? 'Adversário') : minha.jogador1Nome;
      final meu = souJ1 ? minha.placarJogador1 : minha.placarJogador2;
      final dele = souJ1 ? minha.placarJogador2 : minha.placarJogador1;

      if (minha.status == 'finalizada') {
        String rotulo;
        Color cor;

        if (meu > dele) {
          rotulo = 'Vitória';
          cor = TcgTheme.verde;
        } else if (meu < dele) {
          rotulo = 'Derrota';
          cor = _vermelho;
        } else {
          rotulo = 'Empate';
          cor = _amarelo;
        }

        conteudo = _aviso(
          Icons.check_circle,
          '$rotulo • $meu x $dele contra $oponente',
          cor,
        );
      } else {
        conteudo = _aviso(
          Icons.sports_esports,
          'Mesa ${minha.mesa} • contra $oponente '
          '(${_statusTexto(minha.status).toLowerCase()})',
          TcgTheme.verde,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: conteudo,
    );
  }

  Widget _carregando() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _vazio(IconData icone, String mensagem) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(icone, size: 44, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _rolagem(List<Widget> filhos) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: filhos,
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.of(context).size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: altura),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.rodadas.length > 1) _seletor(),
          Flexible(
            child: StreamBuilder<String?>(
              stream: _statusStream,
              builder: (context, snapStatus) {
                if (snapStatus.connectionState == ConnectionState.waiting &&
                    !snapStatus.hasData) {
                  return _carregando();
                }

                final status = snapStatus.data;

                // O jogador só vê os confrontos depois que a rodada inicia.
                if (status == 'configuracao' && !widget.admin) {
                  return _rolagem([
                    _cabecalho(status, 0, 0),
                    _vazio(
                      Icons.lock_clock_outlined,
                      'Confrontos ainda não liberados.\n'
                      'Eles aparecem quando o organizador iniciar a rodada.',
                    ),
                  ]);
                }

                return StreamBuilder<List<PartidaModel>>(
                  stream: _partidasStream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return _rolagem([
                        _cabecalho(status, 0, 0),
                        _vazio(
                          Icons.cloud_off_outlined,
                          'Não foi possível carregar os confrontos.',
                        ),
                      ]);
                    }

                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return _carregando();
                    }

                    final partidas = [...(snap.data ?? <PartidaModel>[])]
                      ..sort((a, b) => a.mesa.compareTo(b.mesa));

                    final finalizadas =
                        partidas.where((p) => p.status == 'finalizada').length;

                    return _rolagem([
                      _cabecalho(status, finalizadas, partidas.length),
                      _meuResumo(partidas),
                      const SizedBox(height: 20),
                      if (partidas.isEmpty)
                        _vazio(
                          Icons.table_restaurant_outlined,
                          'Nenhum confronto nesta rodada.',
                        )
                      else
                        ...partidas.map(
                          (p) => _MesaDetalhe(
                            partida: p,
                            meuUid: widget.meuUid,
                          ),
                        ),
                      if (widget.admin && widget.onGerenciar != null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onGerenciar!(_rodada);
                          },
                          icon: const Icon(Icons.table_rows),
                          label: const Text('Gerenciar rodada'),
                        ),
                      ],
                    ]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Mesa
// ============================================================

class _MesaDetalhe extends StatelessWidget {
  final PartidaModel partida;
  final String? meuUid;

  const _MesaDetalhe({required this.partida, required this.meuUid});

  bool get _minha =>
      meuUid != null &&
      (partida.jogador1Uid == meuUid || partida.jogador2Uid == meuUid);

  bool get _mostraPlacar =>
      partida.status == 'finalizada' ||
      partida.status == 'contestada' ||
      partida.status == 'aguardando_confirmacao';

  /// 1 = jogador 1 venceu, 2 = jogador 2 venceu, 0 = sem vencedor.
  int get _vencedor {
    if (partida.status != 'finalizada') return 0;
    if (partida.placarJogador1 > partida.placarJogador2) return 1;
    if (partida.placarJogador2 > partida.placarJogador1) return 2;
    return 0;
  }

  Widget _chipStatus() {
    final cor = _statusCor(partida.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusTexto(partida.status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: cor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  BoxDecoration? get _destaque => _minha
      ? BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: TcgTheme.verde.withValues(alpha: 0.6),
            width: 1.5,
          ),
        )
      : null;

  @override
  Widget build(BuildContext context) {
    // ===== BYE =====
    if (partida.bye) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: _destaque,
        child: TcgGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _Selo(texto: 'MESA ${partida.mesa}', cor: _amarelo),
              const SizedBox(width: 12),
              _AvatarMini(
                nome: partida.jogador1Nome,
                tamanho: 34,
                cor: _amarelo,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  partida.jogador1Nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const _Selo(texto: 'BYE', cor: _amarelo),
            ],
          ),
        ),
      );
    }

    final vencedor = _vencedor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _destaque,
      child: TcgGlassCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            Row(
              children: [
                _Selo(texto: 'MESA ${partida.mesa}', cor: TcgTheme.verde),
                if (_minha) ...[
                  const SizedBox(width: 8),
                  const _Selo(texto: 'SUA MESA', cor: _ouro),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _chipStatus(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LadoMesa(
                  nome: partida.jogador1Nome,
                  vencedor: vencedor == 1,
                  perdedor: vencedor == 2,
                  souEu: meuUid != null && partida.jogador1Uid == meuUid,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: SizedBox(
                    width: 60,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x26FFFFFF)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _mostraPlacar
                              ? '${partida.placarJogador1} – '
                                  '${partida.placarJogador2}'
                              : 'VS',
                          style: TextStyle(
                            color: _mostraPlacar ? Colors.white : Colors.white54,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _LadoMesa(
                  nome: partida.jogador2Nome ?? '',
                  vencedor: vencedor == 2,
                  perdedor: vencedor == 1,
                  souEu: meuUid != null && partida.jogador2Uid == meuUid,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LadoMesa extends StatelessWidget {
  final String nome;
  final bool vencedor;
  final bool perdedor;
  final bool souEu;

  const _LadoMesa({
    required this.nome,
    required this.vencedor,
    required this.perdedor,
    required this.souEu,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: perdedor ? 0.55 : 1,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _AvatarMini(
                  nome: nome,
                  tamanho: 46,
                  cor: vencedor || souEu ? TcgTheme.verde : Colors.white54,
                ),
                if (vencedor)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _ouro,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        size: 11,
                        color: TcgTheme.fundo,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              nome,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: vencedor ? FontWeight.w800 : FontWeight.w600,
                height: 1.2,
              ),
            ),
            if (souEu)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Você',
                  style: TextStyle(
                    color: TcgTheme.verde,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
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

/// Avatar com iniciais (pronto para receber foto).
class _AvatarMini extends StatelessWidget {
  final String nome;
  final double tamanho;
  final Color cor;

  /// Quando existir foto de perfil, é só passar a URL aqui.
  final String? fotoUrl;

  const _AvatarMini({
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