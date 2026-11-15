import 'package:flutter/services.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';
import 'package:tcg_tournament/features/jogador/service/jogador_torneio_service.dart';

import '../models/torneio_model.dart';
import '../services/torneio_service.dart';

import '../../jogador/models/jogador_torneio_model.dart';
import '../../jogador/pages/gerenciar_jogadores_page.dart';

import '../../partida/pages/montar_primeira_rodada_page.dart';
import '../../partida/pages/gerenciar_rodada_page.dart';
import '../../partida/services/rodada_service.dart';
import '../../partida/services/topcut_service.dart';

import 'classificacao_page.dart';
import 'tom_preflight_page.dart';
import 'tom_tdf_page.dart';
import 'tom_tdf_metadata_page.dart';

class GerenciarTorneioPage extends StatelessWidget {
  final TorneioModel torneio;

  const GerenciarTorneioPage({super.key, required this.torneio});

  // ============================================================
  // Formatação
  // ============================================================

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  String _formatarHorario(DateTime data) {
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  String _formatarStatus(String status) {
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

  // ============================================================
  // Ações
  // ============================================================

  Future<void> _iniciarTorneio(
    BuildContext context,
    TorneioModel torneioAtual,
  ) async {
    try {
      final resultado = await RodadaService().iniciarTorneio(
        torneioId: torneioAtual.id,
      );

      if (!context.mounted) return;

      if (resultado == 'jogadores_insuficientes') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('São necessários pelo menos 2 jogadores aprovados.'),
          ),
        );

        return;
      }

      if (resultado != 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível iniciar o torneio.')),
        );

        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MontarPrimeiraRodadaPage(
            torneioId: torneioAtual.id,
            nomeTorneio: torneioAtual.nome,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível iniciar o torneio.')),
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
        builder: (_) => ClassificacaoPage(
          torneioId: torneioAtual.id,
          nomeTorneio: torneioAtual.nome,
          classificacaoFinal: classificacaoFinal,
        ),
      ),
    );
  }

  void _abrirGerenciarJogadores(
    BuildContext context,
    TorneioModel torneioAtual,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GerenciarJogadoresPage(
          torneioId: torneioAtual.id,
          nomeTorneio: torneioAtual.nome,
        ),
      ),
    );
  }

  Future<void> _copiarCodigo(BuildContext context, String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado.')),
    );
  }

  void _abrirFerramentasTom(BuildContext context, TorneioModel torneioAtual) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: TcgTheme.card,
      builder: (sheetContext) {
        void ir(Widget pagina) {
          Navigator.pop(sheetContext);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => pagina),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOM / TDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Prepare e exporte o torneio para o Tournament Operations Manager.',
                  style: TextStyle(color: TcgTheme.muted, height: 1.4),
                ),
                const SizedBox(height: 18),
                _AcaoTom(
                  icone: Icons.fact_check_outlined,
                  titulo: 'Verificar dados',
                  subtitulo: 'Confira se está tudo certo antes de exportar',
                  onTap: () => ir(TomPreflightPage(torneioId: torneioAtual.id)),
                ),
                const SizedBox(height: 10),
                _AcaoTom(
                  icone: Icons.edit_document,
                  titulo: 'Editar metadados',
                  subtitulo: 'Informações do evento no arquivo TOM',
                  onTap: () =>
                      ir(TomTdfMetadataPage(torneioId: torneioAtual.id)),
                ),
                const SizedBox(height: 10),
                _AcaoTom(
                  icone: Icons.file_download_outlined,
                  titulo: 'Exportar torneio .tdf',
                  subtitulo: 'Gera o arquivo para o TOM',
                  destaque: true,
                  onTap: () => ir(TomTdfPage(torneioId: torneioAtual.id)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // Estrutura da página
  // ============================================================

  /// Fundo + barra fixa no topo (seta e ação opcional) + conteúdo.
  Widget _estrutura(
    BuildContext context,
    Widget child, {
    Widget? acao,
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
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TorneioService torneioService = TorneioService();

    return StreamBuilder<TorneioModel?>(
      stream: torneioService.observarTorneio(torneio.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _estrutura(
            context,
            const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _estrutura(
            context,
            const Center(
              child: Text(
                'Não foi possível carregar o torneio.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final torneioAtual = snapshot.data ?? torneio;

        return _buildPagina(context, torneioAtual);
      },
    );
  }

  // ============================================================
  // Hero
  // ============================================================

  Widget _hero(BuildContext context, TorneioModel t) {
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
              const Spacer(),
              _SeloStatus(
                status: t.status,
                texto: _formatarStatus(t.status),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            t.nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icone: Icons.calendar_month,
                texto: _formatarData(t.dataHora),
              ),
              _InfoChip(
                icone: Icons.access_time,
                texto: _formatarHorario(t.dataHora),
              ),
              _InfoChip(
                icone: Icons.sports_esports,
                texto: t.formato.toUpperCase(),
              ),
              _InfoChip(
                icone: Icons.repeat,
                texto:
                    '${t.quantidadeRodadas} ${t.quantidadeRodadas == 1 ? 'rodada' : 'rodadas'}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),
          _CodigoTorneio(
            codigo: t.codigo,
            onCopiar: () => _copiarCodigo(context, t.codigo),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Página principal
  // ============================================================

  Widget _buildPagina(BuildContext context, TorneioModel torneioAtual) {
    final JogadorTorneioService jogadorService = JogadorTorneioService();

    return _estrutura(
      context,
      Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _hero(context, torneioAtual),

                const SizedBox(height: 28),

                // ===== PROGRESSO =====
                const _TituloSecao('Progresso'),
                _CardProgresso(torneio: torneioAtual),

                const SizedBox(height: 28),

                // ===== PARTICIPANTES =====
                const _TituloSecao('Participantes'),

                StreamBuilder<List<JogadorTorneioModel>>(
                  stream: jogadorService.listarJogadores(torneioAtual.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const TcgGlassCard(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return const TcgGlassCard(
                        child: Text(
                          'Não foi possível carregar os participantes.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final jogadores = snapshot.data ?? [];

                    final aprovados = jogadores
                        .where((jogador) => jogador.status == 'aprovado')
                        .length;

                    final pendentes = jogadores
                        .where((jogador) => jogador.status == 'pendente')
                        .length;

                    return _CardParticipantes(
                      aprovados: aprovados,
                      pendentes: pendentes,
                      onGerenciar: () =>
                          _abrirGerenciarJogadores(context, torneioAtual),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ===== ANDAMENTO =====
                _TituloSecao(
                  'Andamento',
                  aoVivo: torneioAtual.status == 'em_andamento',
                ),

                if (torneioAtual.status == 'inscricoes')
                  _CardTorneioNaoIniciado(
                    onIniciar: () => _iniciarTorneio(context, torneioAtual),
                  )
                else if (torneioAtual.status == 'em_andamento')
                  StreamBuilder<String?>(
                    stream: RodadaService().observarStatusRodada(
                      torneioId: torneioAtual.id,
                      rodada: torneioAtual.rodadaAtual,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const TcgGlassCard(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      return _CardRodadaAtual(
                        torneio: torneioAtual,
                        statusRodada: snapshot.data,
                        onVerClassificacao: () =>
                            _abrirClassificacao(context, torneioAtual),
                      );
                    },
                  )
                else if (torneioAtual.status == 'finalizado')
                  _CardTorneioFinalizado(
                    onVerClassificacao: () => _abrirClassificacao(
                      context,
                      torneioAtual,
                      classificacaoFinal: true,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      // Botão TOM no topo (Builder para o sheet herdar o tema escuro)
      acao: Builder(
        builder: (ctx) => GestureDetector(
          onTap: () => _abrirFerramentasTom(ctx, torneioAtual),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.file_present_outlined,
                    size: 18, color: TcgTheme.verde),
                SizedBox(width: 8),
                Text(
                  'TOM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
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
// Título de seção
// ============================================================

class _TituloSecao extends StatelessWidget {
  final String texto;
  final bool aoVivo;

  const _TituloSecao(this.texto, {this.aoVivo = false});

  @override
  Widget build(BuildContext context) {
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
          if (aoVivo) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x263DDC84),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 7, color: TcgTheme.verde),
                  SizedBox(width: 5),
                  Text(
                    'AO VIVO',
                    style: TextStyle(
                      color: TcgTheme.verde,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Hero: selo, chips e código
// ============================================================

class _SeloStatus extends StatelessWidget {
  final String status;
  final String texto;

  const _SeloStatus({required this.status, required this.texto});

  Color get _cor {
    switch (status) {
      case 'em_andamento':
        return TcgTheme.verde;
      case 'finalizado':
        return Colors.white70;
      default:
        return const Color(0xFFFFB74D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _cor;

    return Container(
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
          Text(
            texto,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodigoTorneio extends StatelessWidget {
  final String codigo;
  final VoidCallback onCopiar;

  const _CodigoTorneio({required this.codigo, required this.onCopiar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onCopiar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0x1F3DDC84),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.key, size: 18, color: TcgTheme.verde),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Código de convite',
                    style: TextStyle(color: TcgTheme.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    codigo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, size: 20, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Progresso (linha do tempo)
// ============================================================

enum _EstadoEtapa { feita, atual, pendente }

class _Etapa {
  final String rotulo;
  final IconData? icone;
  final _EstadoEtapa estado;

  const _Etapa({required this.rotulo, required this.estado, this.icone});
}

class _CardProgresso extends StatelessWidget {
  final TorneioModel torneio;

  const _CardProgresso({required this.torneio});

  bool get _emAndamento => torneio.status == 'em_andamento';
  bool get _finalizado => torneio.status == 'finalizado';
  bool get _faseTopCut =>
      _emAndamento && torneio.rodadaAtual > torneio.quantidadeRodadas;

  List<_Etapa> _etapas() {
    final etapas = <_Etapa>[];

    for (var i = 1; i <= torneio.quantidadeRodadas; i++) {
      _EstadoEtapa estado;

      if (_finalizado || (_emAndamento && i < torneio.rodadaAtual)) {
        estado = _EstadoEtapa.feita;
      } else if (_emAndamento && i == torneio.rodadaAtual) {
        estado = _EstadoEtapa.atual;
      } else {
        estado = _EstadoEtapa.pendente;
      }

      etapas.add(_Etapa(rotulo: 'R$i', estado: estado));
    }

    if (torneio.tamanhoTopCut > 0) {
      final estado = _finalizado || torneio.topcutConcluido
          ? _EstadoEtapa.feita
          : (_faseTopCut ? _EstadoEtapa.atual : _EstadoEtapa.pendente);

      etapas.add(
        _Etapa(
          rotulo: 'Top ${torneio.tamanhoTopCut}',
          icone: Icons.account_tree_rounded,
          estado: estado,
        ),
      );
    }

    etapas.add(
      _Etapa(
        rotulo: 'Final',
        icone: Icons.emoji_events_rounded,
        estado: _finalizado ? _EstadoEtapa.feita : _EstadoEtapa.pendente,
      ),
    );

    return etapas;
  }

  String _resumo() {
    if (_finalizado) return 'Torneio concluído';
    if (_faseTopCut) return 'Fase eliminatória';
    if (_emAndamento) {
      return 'Rodada ${torneio.rodadaAtual} de ${torneio.quantidadeRodadas}';
    }
    return 'Aguardando início';
  }

  @override
  Widget build(BuildContext context) {
    final etapas = _etapas();
    final feitas = etapas.where((e) => e.estado == _EstadoEtapa.feita).length;
    final fracao = feitas / etapas.length;

    return TcgGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _resumo(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(fracao * 100).round()}%',
                style: const TextStyle(
                  color: TcgTheme.verde,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fracao,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(TcgTheme.verde),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: etapas.map((e) => _NoEtapa(etapa: e)).toList(),
          ),
        ],
      ),
    );
  }
}

class _NoEtapa extends StatelessWidget {
  final _Etapa etapa;

  const _NoEtapa({required this.etapa});

  @override
  Widget build(BuildContext context) {
    final feita = etapa.estado == _EstadoEtapa.feita;
    final atual = etapa.estado == _EstadoEtapa.atual;

    Widget conteudo;

    if (feita) {
      conteudo = Icon(
        etapa.icone ?? Icons.check_rounded,
        size: 20,
        color: TcgTheme.fundo,
      );
    } else if (etapa.icone != null) {
      conteudo = Icon(
        etapa.icone,
        size: 20,
        color: atual ? TcgTheme.verde : Colors.white38,
      );
    } else {
      conteudo = Text(
        etapa.rotulo.substring(1),
        style: TextStyle(
          color: atual ? TcgTheme.verde : Colors.white38,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return SizedBox(
      width: 48,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: feita ? TcgTheme.gradient : null,
              color: feita
                  ? null
                  : (atual
                      ? const Color(0x333DDC84)
                      : const Color(0x14FFFFFF)),
              border: Border.all(
                color: feita
                    ? Colors.transparent
                    : (atual ? TcgTheme.verde : const Color(0x26FFFFFF)),
                width: atual ? 2 : 1,
              ),
              boxShadow: atual
                  ? const [
                      BoxShadow(
                        color: Color(0x663DDC84),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: conteudo,
          ),
          const SizedBox(height: 5),
          Text(
            etapa.rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: atual ? TcgTheme.verde : TcgTheme.muted,
              fontSize: 10,
              fontWeight: atual ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Participantes
// ============================================================

class _CardParticipantes extends StatelessWidget {
  final int aprovados;
  final int pendentes;
  final VoidCallback onGerenciar;

  const _CardParticipantes({
    required this.aprovados,
    required this.pendentes,
    required this.onGerenciar,
  });

  @override
  Widget build(BuildContext context) {
    final total = aprovados + pendentes;
    final fracao = total == 0 ? 0.0 : aprovados / total;

    return TcgGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ResumoParticipantes(
                  titulo: 'Aprovados',
                  quantidade: aprovados,
                  destaque: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResumoParticipantes(
                  titulo: 'Pendentes',
                  quantidade: pendentes,
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fracao,
                minHeight: 6,
                backgroundColor: const Color(0x33FFB74D),
                valueColor: const AlwaysStoppedAnimation(TcgTheme.verde),
              ),
            ),
          ],
          if (pendentes > 0) ...[
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onGerenciar,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1FFFB74D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x55FFB74D)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      size: 18,
                      color: Color(0xFFFFB74D),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pendentes == 1
                            ? '1 jogador aguardando aprovação'
                            : '$pendentes jogadores aguardando aprovação',
                        style: const TextStyle(
                          color: Color(0xFFFFB74D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFFFB74D),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onGerenciar,
              icon: const Icon(Icons.people),
              label: const Text('Gerenciar jogadores'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumoParticipantes extends StatelessWidget {
  final String titulo;
  final int quantidade;
  final bool destaque;

  const _ResumoParticipantes({
    required this.titulo,
    required this.quantidade,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        border: Border.all(color: const Color(0x26FFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            quantidade.toString(),
            style: TextStyle(
              color: destaque ? TcgTheme.verde : Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(color: TcgTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Painel TOM
// ============================================================

class _AcaoTom extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final bool destaque;

  const _AcaoTom({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: destaque ? const Color(0x1F3DDC84) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: destaque ? TcgTheme.verde : const Color(0x26FFFFFF),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: destaque ? TcgTheme.verde : const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icone,
                color: destaque ? TcgTheme.fundo : Colors.white70,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: TcgTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Torneio não iniciado
// ============================================================

class _CardTorneioNaoIniciado extends StatelessWidget {
  final VoidCallback onIniciar;

  const _CardTorneioNaoIniciado({required this.onIniciar});

  @override
  Widget build(BuildContext context) {
    return TcgGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 42,
            color: TcgTheme.verde,
          ),
          const SizedBox(height: 12),
          const Text(
            'O torneio ainda não foi iniciado.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aprove os jogadores e inicie quando estiver tudo pronto.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          TcgGradientButton(
            texto: 'Iniciar torneio',
            icone: Icons.play_arrow,
            onPressed: onIniciar,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Rodada atual
// ============================================================

class _CardRodadaAtual extends StatelessWidget {
  final TorneioModel torneio;
  final String? statusRodada;
  final VoidCallback onVerClassificacao;

  const _CardRodadaAtual({
    required this.torneio,
    required this.statusRodada,
    required this.onVerClassificacao,
  });

  bool get _ultimaRodadaSwiss =>
      torneio.rodadaAtual == torneio.quantidadeRodadas;
  bool get _faseTopCut => torneio.rodadaAtual > torneio.quantidadeRodadas;
  bool get _topCutConcluido => torneio.topcutConcluido;
  bool get _podeFinalizar =>
      (torneio.tamanhoTopCut == 0 && _ultimaRodadaSwiss) ||
      (torneio.tamanhoTopCut > 0 && _topCutConcluido);

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

  String _dica() {
    switch (statusRodada) {
      case 'configuracao':
        return 'Revise os confrontos antes de iniciar.';

      case 'finalizada':
        return 'Todas as partidas foram concluídas.';

      case 'em_andamento':
        return 'Abra a rodada para acompanhar as partidas.';

      default:
        return 'Abra a rodada atual.';
    }
  }

  Future<void> _gerarProximaRodada(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Gerar Rodada ${torneio.rodadaAtual + 1}'),
          content: const Text(
            'O sistema irá sugerir os próximos confrontos com base na classificação e no histórico de partidas. '
            'Você poderá revisar e alterar os confrontos antes de iniciar a rodada.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Gerar rodada'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final resultado = await RodadaService().gerarProximaRodada(
        torneioId: torneio.id,
        rodadaAtual: torneio.rodadaAtual,
      );

      if (!context.mounted) return;

      switch (resultado) {
        case 'ok':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Rodada ${torneio.rodadaAtual + 1} gerada. Revise os confrontos antes de iniciar.',
              ),
            ),
          );

          break;

        case 'ultima_rodada':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('O torneio já chegou à última rodada.'),
            ),
          );

          break;

        case 'rodada_ja_existe':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A próxima rodada já existe.')),
          );

          break;

        case 'rodada_nao_finalizada':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Finalize a rodada atual antes de gerar a próxima.',
              ),
            ),
          );

          break;

        case 'sem_pareamento_valido':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível parear sem repetir adversários. Revise os pods e o histórico.',
              ),
            ),
          );
          break;

        case 'jogadores_insuficientes':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não existem jogadores suficientes para gerar a próxima rodada.',
              ),
            ),
          );

          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível gerar a próxima rodada.'),
            ),
          );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível gerar a próxima rodada.'),
        ),
      );
    }
  }

  Future<void> _gerarTopCut(BuildContext context) async {
    try {
      final resultado = _faseTopCut
          ? await TopCutService().gerarProximaRodada(torneioId: torneio.id)
          : await TopCutService().iniciarTopCut(torneioId: torneio.id);
      if (!context.mounted) return;
      final mensagem = resultado == 'ok'
          ? 'Chave de eliminação criada. Revise e inicie a rodada.'
          : 'Não foi possível gerar Top Cut: $resultado';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar Top Cut: $e')),
      );
    }
  }

  Future<void> _finalizarTorneio(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Finalizar torneio'),
          content: const Text(
            'Todas as rodadas foram concluídas. Deseja finalizar o torneio?\n\n'
            'Após a finalização, novas rodadas não poderão ser geradas.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Finalizar torneio'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final resultado = await TorneioService().finalizarTorneio(
        torneioId: torneio.id,
      );

      if (!context.mounted) return;

      switch (resultado) {
        case 'ok':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Torneio finalizado com sucesso.')),
          );

          break;

        case 'torneio_finalizado':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este torneio já foi finalizado.')),
          );

          break;

        case 'rodadas_pendentes':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ainda existem rodadas pendentes.')),
          );

          break;

        case 'rodada_nao_finalizada':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A última rodada ainda não foi finalizada.'),
            ),
          );

          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível finalizar o torneio.'),
            ),
          );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível finalizar o torneio.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TcgGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x1F3DDC84),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.sports_esports,
                  color: TcgTheme.verde,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titulo(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dica(),
                      style: const TextStyle(
                        color: TcgTheme.muted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GerenciarRodadaPage(
                    torneioId: torneio.id,
                    nomeTorneio: torneio.nome,
                    rodada: torneio.rodadaAtual,
                    formato: torneio.formato,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.table_rows),
            label: Text(
              statusRodada == 'configuracao'
                  ? 'Revisar rodada'
                  : 'Abrir rodada atual',
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: onVerClassificacao,
            icon: const Icon(Icons.leaderboard),
            label: const Text('Ver classificação'),
          ),

          if (statusRodada == 'finalizada' &&
              torneio.rodadaAtual < torneio.quantidadeRodadas) ...[
            const SizedBox(height: 12),
            TcgGradientButton(
              texto: 'Gerar Rodada ${torneio.rodadaAtual + 1}',
              icone: Icons.next_plan,
              onPressed: () => _gerarProximaRodada(context),
            ),
          ],

          if (statusRodada == 'finalizada' &&
              ((torneio.tamanhoTopCut > 0 && !_podeFinalizar) ||
                  (_faseTopCut && !_topCutConcluido))) ...[
            const SizedBox(height: 12),
            TcgGradientButton(
              texto: _faseTopCut
                  ? 'Gerar próxima fase eliminatória'
                  : 'Iniciar Top Cut',
              icone: Icons.account_tree_rounded,
              onPressed: () => _gerarTopCut(context),
            ),
          ],

          if (statusRodada == 'finalizada' && _podeFinalizar) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Todas as rodadas foram concluídas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TcgGradientButton(
              texto: 'Finalizar torneio',
              icone: Icons.emoji_events,
              onPressed: () => _finalizarTorneio(context),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Torneio finalizado
// ============================================================

class _CardTorneioFinalizado extends StatelessWidget {
  final VoidCallback onVerClassificacao;

  const _CardTorneioFinalizado({required this.onVerClassificacao});

  @override
  Widget build(BuildContext context) {
    return TcgGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x1F3DDC84),
            ),
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: TcgTheme.gradient,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x663DDC84),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Torneio finalizado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Todas as rodadas foram concluídas e a classificação final está disponível.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          TcgGradientButton(
            texto: 'Ver classificação',
            icone: Icons.leaderboard,
            onPressed: onVerClassificacao,
          ),
        ],
      ),
    );
  }
}