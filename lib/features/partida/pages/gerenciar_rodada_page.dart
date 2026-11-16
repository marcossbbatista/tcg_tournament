import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';

import '../models/partida_model.dart';
import '../services/partida_service.dart';
import '../services/rodada_service.dart';

import 'editar_rodada_page.dart';

class GerenciarRodadaPage extends StatelessWidget {
  final String torneioId;
  final String nomeTorneio;
  final int rodada;
  final String formato;

  const GerenciarRodadaPage({
    super.key,
    required this.torneioId,
    required this.nomeTorneio,
    required this.rodada,
    required this.formato,
  });

  static const Color _amarelo = Color(0xFFFFB74D);
  static const Color _vermelho = Color(0xFFFF6B6B);

  // ============================================================
  // Lógica
  // ============================================================

  Future<void> _editarRodada(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarRodadaPage(
          torneioId: torneioId,
          rodada: rodada,
          nomeTorneio: nomeTorneio,
        ),
      ),
    );
  }

  Future<void> _iniciarRodada(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Theme(
          data: TcgTheme.data(),
          child: AlertDialog(
            title: const Text('Iniciar rodada'),
            content: Text(
              'Deseja iniciar a Rodada $rodada? '
              'Os confrontos ficarão disponíveis para os jogadores.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Iniciar'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      final resultado = await RodadaService().iniciarRodada(
        torneioId: torneioId,
        rodada: rodada,
      );

      if (!context.mounted) return;

      switch (resultado) {
        case 'ok':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rodada iniciada com sucesso.')),
          );

          break;

        case 'rodada_ja_iniciada':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A rodada já foi iniciada.')),
          );

          break;

        case 'rodada_finalizada':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A rodada já foi finalizada.')),
          );

          break;

        case 'nenhuma_partida':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Configure os confrontos antes de iniciar a rodada.',
              ),
            ),
          );

          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível iniciar a rodada.')),
          );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível iniciar a rodada.')),
      );
    }
  }

  Future<void> _encerrarRodada(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Theme(
          data: TcgTheme.data(),
          child: AlertDialog(
            title: const Text('Encerrar rodada'),
            content: Text(
              'Deseja encerrar a Rodada $rodada? '
              'Os pontos das partidas serão calculados.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Encerrar'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      final resultado = await RodadaService().encerrarRodada(
        torneioId: torneioId,
        rodada: rodada,
      );

      if (!context.mounted) return;

      switch (resultado) {
        case 'ok':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Rodada encerrada e pontuação calculada com sucesso.',
              ),
            ),
          );

          break;

        case 'partida_pendente':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todas as partidas precisam estar finalizadas.'),
            ),
          );

          break;

        case 'rodada_finalizada':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Esta rodada já foi encerrada.')),
          );

          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível encerrar a rodada.'),
            ),
          );
      }
    } catch (e, stackTrace) {
      debugPrint('Erro ao encerrar rodada: $e');
      debugPrint('Detalhes do erro: $stackTrace');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao encerrar rodada: $e'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  // ============================================================
  // Estrutura da página
  // ============================================================

  /// Fundo + barra fixa no topo + corpo + rodapé opcional.
  Widget _estrutura(
    BuildContext context, {
    required Widget corpo,
    Widget? acao,
    Widget? rodape,
  }) {
    return TcgTheme.wrap(
      Scaffold(
        backgroundColor: TcgTheme.fundo,
        body: TcgBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Voltar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (acao != null) acao,
                    ],
                  ),
                ),
                Expanded(child: corpo),
                if (rodape != null) rodape,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _centro(IconData icone, String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 44, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TcgTheme.muted),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PartidaService partidaService = PartidaService();

    final RodadaService rodadaService = RodadaService();

    return StreamBuilder<String?>(
      stream: rodadaService.observarStatusRodada(
        torneioId: torneioId,
        rodada: rodada,
      ),
      builder: (context, rodadaSnapshot) {
        if (rodadaSnapshot.connectionState == ConnectionState.waiting &&
            !rodadaSnapshot.hasData) {
          return _estrutura(
            context,
            corpo: const Center(child: CircularProgressIndicator()),
          );
        }

        if (rodadaSnapshot.hasError) {
          return _estrutura(
            context,
            corpo: _centro(
              Icons.cloud_off_outlined,
              'Não foi possível carregar a rodada.',
            ),
          );
        }

        final statusRodada = rodadaSnapshot.data;

        return StreamBuilder<List<PartidaModel>>(
          stream: partidaService.observarPartidasDaRodada(
            torneioId: torneioId,
            rodada: rodada,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return _estrutura(
                context,
                corpo: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _estrutura(
                context,
                corpo: _centro(
                  Icons.cloud_off_outlined,
                  'Não foi possível carregar as partidas.',
                ),
              );
            }

            final partidas = snapshot.data ?? [];

            return _estrutura(
              context,
              acao: statusRodada == 'configuracao' ||
                      statusRodada == 'em_andamento'
                  ? _BotaoPilula(
                      icone: Icons.edit,
                      texto: 'Editar',
                      onTap: () => _editarRodada(context),
                    )
                  : null,
              corpo: _corpo(context, statusRodada, partidas),
              rodape: _rodape(context, statusRodada, partidas),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Corpo
  // ============================================================

  Widget _corpo(
    BuildContext context,
    String? statusRodada,
    List<PartidaModel> partidas,
  ) {
    final finalizadas =
        partidas.where((p) => p.status == 'finalizada').length;

    final contestadas =
        partidas.where((p) => p.status == 'contestada').length;

    final aguardandoConfirmacao =
        partidas.where((p) => p.status == 'aguardando_confirmacao').length;

    final emAndamento =
        partidas.where((p) => p.status == 'em_andamento').length;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cabecalho(statusRodada, finalizadas, partidas.length),

              if (statusRodada == 'finalizada') ...[
                const SizedBox(height: 14),
                _caixa(
                  icone: Icons.check_circle,
                  texto: 'Rodada finalizada.',
                  cor: TcgTheme.verde,
                ),
              ],

              if (contestadas > 0) ...[
                const SizedBox(height: 14),
                _caixa(
                  icone: Icons.gavel,
                  texto: contestadas == 1
                      ? '1 partida contestada aguardando sua decisão.'
                      : '$contestadas partidas contestadas aguardando sua '
                          'decisão.',
                  cor: _vermelho,
                ),
              ],

              const SizedBox(height: 14),
              Row(
                children: [
                  _contador(
                    'Finalizadas',
                    '$finalizadas/${partidas.length}',
                    TcgTheme.verde,
                  ),
                  const SizedBox(width: 10),
                  _contador(
                    'Contestadas',
                    '$contestadas',
                    contestadas > 0 ? _vermelho : Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _contador('Em andamento', '$emAndamento', Colors.white),
                  const SizedBox(width: 10),
                  _contador(
                    'Aguardando',
                    '$aguardandoConfirmacao',
                    aguardandoConfirmacao > 0 ? _amarelo : Colors.white,
                  ),
                ],
              ),

              const SizedBox(height: 28),
              _rotulo('Confrontos', quantidade: partidas.length),

              if (partidas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: _centro(
                    Icons.table_restaurant_outlined,
                    'Nenhum confronto configurado.',
                  ),
                )
              else
                ...partidas.map(
                  (partida) => _PartidaAdmCard(
                    torneioId: torneioId,
                    rodada: rodada,
                    formato: formato,
                    partida: partida,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalho(String? status, int finalizadas, int total) {
    final fracao = total == 0 ? 0.0 : finalizadas / total;

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
                  Icons.sports_esports,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              _SeloRodada(status: status),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Rodada $rodada',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nomeTorneio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
          if (total > 0) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$finalizadas de $total partidas finalizadas',
                    style: const TextStyle(
                      color: TcgTheme.muted,
                      fontSize: 12,
                    ),
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
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(TcgTheme.verde),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contador(String titulo, String valor, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: TextStyle(
                color: cor,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: TcgTheme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _caixa({
    required IconData icone,
    required String texto,
    required Color cor,
  }) {
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

  Widget _rotulo(String texto, {int? quantidade}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            texto.toUpperCase(),
            style: const TextStyle(
              color: TcgTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          if (quantidade != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: TcgTheme.verde.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$quantidade',
                style: const TextStyle(
                  color: TcgTheme.verde,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // Rodapé (ações fixas)
  // ============================================================

  Widget? _rodape(
    BuildContext context,
    String? statusRodada,
    List<PartidaModel> partidas,
  ) {
    if (statusRodada != 'configuracao' && statusRodada != 'em_andamento') {
      return null;
    }

    final configuracao = statusRodada == 'configuracao';

    final podeEncerrar = partidas.isNotEmpty &&
        partidas.every((partida) => partida.status == 'finalizada');

    final String? dica = configuracao
        ? (partidas.isEmpty
            ? 'Configure os confrontos antes de iniciar a rodada.'
            : null)
        : (podeEncerrar
            ? null
            : 'Todas as partidas precisam estar finalizadas antes de '
                'encerrar a rodada.');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xCC14142B),
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (dica != null) ...[
                Text(
                  dica,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TcgTheme.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (configuracao)
                TcgGradientButton(
                  texto: 'Iniciar rodada',
                  icone: Icons.play_arrow,
                  onPressed:
                      partidas.isEmpty ? null : () => _iniciarRodada(context),
                )
              else
                TcgGradientButton(
                  texto: 'Encerrar rodada',
                  icone: Icons.flag,
                  onPressed:
                      podeEncerrar ? () => _encerrarRodada(context) : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Botão em pílula (barra do topo)
// ============================================================

class _BotaoPilula extends StatelessWidget {
  final IconData icone;
  final String texto;
  final VoidCallback onTap;

  const _BotaoPilula({
    required this.icone,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 18, color: TcgTheme.verde),
            const SizedBox(width: 8),
            Text(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Selo de status da rodada
// ============================================================

class _SeloRodada extends StatelessWidget {
  final String? status;

  const _SeloRodada({required this.status});

  @override
  Widget build(BuildContext context) {
    String texto;
    Color cor;

    switch (status) {
      case 'configuracao':
        texto = 'Aguardando configuração';
        cor = const Color(0xFFFFB74D);

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
        texto = 'Status não identificado';
        cor = Colors.white54;
    }

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Carta de partida
// ============================================================

class _PartidaAdmCard extends StatelessWidget {
  final String torneioId;
  final int rodada;
  final String formato;
  final PartidaModel partida;

  const _PartidaAdmCard({
    required this.torneioId,
    required this.rodada,
    required this.formato,
    required this.partida,
  });

  static const Color _amarelo = Color(0xFFFFB74D);
  static const Color _vermelho = Color(0xFFFF6B6B);

  String _statusFormatado() {
    switch (partida.status) {
      case 'aguardando':
        return 'Aguardando início';

      case 'em_andamento':
        return 'Em andamento';

      case 'aguardando_confirmacao':
        return 'Aguardando confirmação';

      case 'finalizada':
        return 'Finalizada';

      case 'contestada':
        return 'Contestada';

      default:
        return partida.status;
    }
  }

  IconData _iconeStatus() {
    switch (partida.status) {
      case 'aguardando':
        return Icons.hourglass_empty;

      case 'finalizada':
        return Icons.check_circle;

      case 'contestada':
        return Icons.warning_amber;

      case 'aguardando_confirmacao':
        return Icons.schedule;

      default:
        return Icons.sports_esports;
    }
  }

  Color _corStatus() {
    switch (partida.status) {
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

  List<int> _valoresPlacar() {
    if (formato == 'md1') {
      return [0, 1];
    }

    return [0, 1, 2];
  }

  /// 1 = jogador 1 venceu, 2 = jogador 2 venceu, 0 = sem vencedor.
  int get _vencedor {
    if (partida.status != 'finalizada') return 0;
    if (partida.placarJogador1 > partida.placarJogador2) return 1;
    if (partida.placarJogador2 > partida.placarJogador1) return 2;
    return 0;
  }

  Widget _chipStatus() {
    final cor = _corStatus();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconeStatus(), size: 14, color: cor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _statusFormatado(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: cor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selo(String texto, Color cor) {
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

  @override
  Widget build(BuildContext context) {
    final contestada = partida.status == 'contestada';

    // ===== BYE =====
    if (partida.bye) {
      return TcgGlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _AvatarMesa(
              nome: partida.jogador1Nome,
              tamanho: 48,
              cor: _amarelo,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partida.jogador1Nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Recebeu BYE nesta rodada',
                    style: TextStyle(color: TcgTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            _selo('BYE', _amarelo),
          ],
        ),
      );
    }

    // ===== Partida normal =====
    final vencedor = _vencedor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: contestada
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _vermelho.withValues(alpha: 0.6)),
            )
          : null,
      child: TcgGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _selo('MESA ${partida.mesa}', TcgTheme.verde),
                const Spacer(),
                Flexible(child: _chipStatus()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _JogadorPlacar(
                  nome: partida.jogador1Nome,
                  vencedor: vencedor == 1,
                  perdedor: vencedor == 2,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x26FFFFFF)),
                    ),
                    child: Text(
                      '${partida.placarJogador1} – ${partida.placarJogador2}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                _JogadorPlacar(
                  nome: partida.jogador2Nome ?? '',
                  vencedor: vencedor == 2,
                  perdedor: vencedor == 1,
                ),
              ],
            ),
            if (contestada) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _resolverContestacao(context);
                },
                icon: const Icon(Icons.gavel),
                label: const Text('Resolver contestação'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _resolverContestacao(BuildContext context) async {
    int? placar1;
    int? placar2;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Theme(
          data: TcgTheme.data(),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Resolver contestação'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${partida.jogador1Nome} x ${partida.jogador2Nome}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        value: placar1,
                        isExpanded: true,
                        dropdownColor: TcgTheme.card,
                        decoration: InputDecoration(
                          labelText: partida.jogador1Nome,
                        ),
                        items: _valoresPlacar()
                            .map(
                              (valor) => DropdownMenuItem(
                                value: valor,
                                child: Text(valor.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (valor) {
                          setDialogState(() {
                            placar1 = valor;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: placar2,
                        isExpanded: true,
                        dropdownColor: TcgTheme.card,
                        decoration: InputDecoration(
                          labelText: partida.jogador2Nome,
                        ),
                        items: _valoresPlacar()
                            .map(
                              (valor) => DropdownMenuItem(
                                value: valor,
                                child: Text(valor.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (valor) {
                          setDialogState(() {
                            placar2 = valor;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: placar1 == null || placar2 == null
                        ? null
                        : () {
                            Navigator.pop(context, true);
                          },
                    child: const Text('Confirmar resultado'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (resultado != true || placar1 == null || placar2 == null) {
      return;
    }

    try {
      await PartidaService().resolverPartidaContestada(
        torneioId: torneioId,
        rodada: rodada,
        partidaId: partida.id,
        placarJogador1: placar1!,
        placarJogador2: placar2!,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultado definido com sucesso.')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível resolver a contestação.'),
        ),
      );
    }
  }
}

// ============================================================
// Jogador dentro da carta (avatar + nome)
// ============================================================

class _JogadorPlacar extends StatelessWidget {
  final String nome;
  final bool vencedor;
  final bool perdedor;

  const _JogadorPlacar({
    required this.nome,
    this.vencedor = false,
    this.perdedor = false,
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
                _AvatarMesa(
                  nome: nome,
                  tamanho: 56,
                  cor: vencedor ? TcgTheme.verde : Colors.white54,
                ),
                if (vencedor)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFD54F),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        size: 12,
                        color: TcgTheme.fundo,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Avatar com iniciais (pronto para receber foto)
// ============================================================

class _AvatarMesa extends StatelessWidget {
  final String nome;
  final double tamanho;
  final Color cor;

  /// Quando existir foto de perfil, é só passar a URL aqui.
  final String? fotoUrl;

  const _AvatarMesa({
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