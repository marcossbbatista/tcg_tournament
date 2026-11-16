import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';

import '../../../core/session/usuario_session.dart';
import '../../partida/models/partida_model.dart';
import '../../partida/pages/informar_resultado_page.dart';
import '../../partida/services/partida_service.dart';
import '../../partida/services/rodada_service.dart';
import '../../torneio/models/classificacao_jogador_model.dart';
import '../../torneio/models/torneio_model.dart';
import '../../torneio/pages/classificacao_page.dart';
import '../../torneio/services/torneio_service.dart';
import '../models/torneio_jogador_model.dart';

const Color _amarelo = Color(0xFFFFB74D);
const Color _vermelho = Color(0xFFFF6B6B);
const Color _ouro = Color(0xFFFFD54F);
const Color _prata = Color(0xFFCFD8DC);
const Color _bronze = Color(0xFFE0955B);

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

  late final Stream<TorneioModel?> _torneioStream;
  late Future<List<ClassificacaoJogadorModel>> _classificacao;

  @override
  void initState() {
    super.initState();

    _torneioStream = TorneioService().observarTorneio(widget.item.torneio.id);
    _carregarClassificacao();
  }

  void _carregarClassificacao() {
    _classificacao = RodadaService().buscarClassificacao(
      torneioId: widget.item.torneio.id,
    );
  }

  void _atualizar() {
    setState(_carregarClassificacao);
  }

  // ============================================================
  // Formatação
  // ============================================================

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  String _formatarHorario(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';

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

  Widget _estrutura(Widget corpo, {bool mostrarAtualizar = false}) {
    return TcgTheme.wrap(
      Scaffold(
        backgroundColor: TcgTheme.fundo,
        body: TcgBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Barra fixa no topo
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
                      if (mostrarAtualizar)
                        GestureDetector(
                          onTap: _atualizar,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0x33FFFFFF),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  size: 18,
                                  color: TcgTheme.verde,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Atualizar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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
  // Cabeçalho
  // ============================================================

  Widget _cabecalho(TorneioModel torneio) {
    final cor = _corInscricao();

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
                icone: Icons.calendar_month,
                texto: _formatarData(torneio.dataHora),
              ),
              _InfoChip(
                icone: Icons.access_time,
                texto: _formatarHorario(torneio.dataHora),
              ),
              _InfoChip(
                icone: Icons.sports_esports,
                texto: torneio.formato.toUpperCase(),
              ),
              _InfoChip(
                icone: Icons.repeat,
                texto:
                    '${torneio.quantidadeRodadas} ${torneio.quantidadeRodadas == 1 ? 'rodada' : 'rodadas'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Sua partida
  // ============================================================

  Widget _conteudoPartida(
    TorneioJogadorModel item,
    TorneioModel torneio,
    dynamic usuario,
  ) {
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

    if (torneio.status == 'finalizado') {
      return _EstadoCard(
        icone: Icons.emoji_events_rounded,
        mensagem: 'Torneio finalizado. Confira a classificação final abaixo.',
        cor: TcgTheme.verde,
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

  // ============================================================
  // Build
  // ============================================================

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

    return StreamBuilder<TorneioModel?>(
      stream: _torneioStream,
      builder: (context, snapshot) {
        // Enquanto não chega o torneio ao vivo, usa o que veio da Home.
        final torneio = snapshot.data ?? widget.item.torneio;

        final aprovado = widget.item.status == 'aprovado';
        final iniciado = torneio.status != 'inscricoes';
        final emAndamento = torneio.status == 'em_andamento';

        return _estrutura(
          mostrarAtualizar: aprovado && iniciado,
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cabecalho(torneio),

                    const SizedBox(height: 28),
                    _rotulo('Progresso'),
                    _CardProgresso(torneio: torneio),

                    const SizedBox(height: 28),
                    _rotulo('Sua partida'),
                    _conteudoPartida(widget.item, torneio, usuario),

                    if (aprovado && emAndamento) ...[
                      const SizedBox(height: 28),
                      _OutrasMesas(
                        torneioId: torneio.id,
                        rodada: torneio.rodadaAtual,
                        meuUid: usuario.uid,
                      ),
                    ],

                    if (aprovado && iniciado) ...[
                      const SizedBox(height: 28),
                      _rotulo('Classificação'),
                      _CardClassificacao(
                        futuro: _classificacao,
                        meuNome: usuario.nome,
                        onVerCompleta: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassificacaoPage(
                                torneioId: torneio.id,
                                nomeTorneio: torneio.nome,
                                classificacaoFinal:
                                    torneio.status == 'finalizado',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
// Outras mesas da rodada
// ============================================================

class _OutrasMesas extends StatefulWidget {
  final String torneioId;
  final int rodada;
  final String meuUid;

  const _OutrasMesas({
    required this.torneioId,
    required this.rodada,
    required this.meuUid,
  });

  @override
  State<_OutrasMesas> createState() => _OutrasMesasState();
}

class _OutrasMesasState extends State<_OutrasMesas> {
  static const int _limite = 4;

  late Stream<List<PartidaModel>> _stream;
  bool _todas = false;

  @override
  void initState() {
    super.initState();
    _assinar();
  }

  @override
  void didUpdateWidget(covariant _OutrasMesas antigo) {
    super.didUpdateWidget(antigo);

    if (antigo.rodada != widget.rodada ||
        antigo.torneioId != widget.torneioId) {
      _assinar();
    }
  }

  void _assinar() {
    _stream = PartidaService().observarPartidasDaRodada(
      torneioId: widget.torneioId,
      rodada: widget.rodada,
    );
  }

  Widget _rotuloComContador(int quantidade) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Text(
            'OUTRAS MESAS',
            style: TextStyle(
              color: TcgTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PartidaModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        // Sem permissão ou sem dados: a seção simplesmente não aparece.
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final outras = snapshot.data!
            .where(
              (p) =>
                  p.jogador1Uid != widget.meuUid &&
                  p.jogador2Uid != widget.meuUid,
            )
            .toList()
          ..sort((a, b) => a.mesa.compareTo(b.mesa));

        if (outras.isEmpty) return const SizedBox.shrink();

        final visiveis =
            _todas || outras.length <= _limite ? outras : outras.take(_limite);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _rotuloComContador(outras.length),
            ...visiveis.map((p) => _MesaCompacta(partida: p)),
            if (outras.length > _limite)
              TextButton.icon(
                onPressed: () => setState(() => _todas = !_todas),
                icon: Icon(
                  _todas
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                label: Text(
                  _todas ? 'Mostrar menos' : 'Ver todas (${outras.length})',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MesaCompacta extends StatelessWidget {
  final PartidaModel partida;

  const _MesaCompacta({required this.partida});

  String get _statusTexto {
    switch (partida.status) {
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
        return partida.status;
    }
  }

  Color get _statusCor {
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

  @override
  Widget build(BuildContext context) {
    final cor = _statusCor;

    // ===== BYE =====
    if (partida.bye) {
      return TcgGlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _Selo(texto: 'MESA ${partida.mesa}', cor: _amarelo),
            const SizedBox(width: 12),
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
      );
    }

    return TcgGlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              _Selo(texto: 'MESA ${partida.mesa}', cor: TcgTheme.verde),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusTexto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  partida.jogador1Nome,
                  maxLines: 2,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x26FFFFFF)),
                ),
                child: Text(
                  '${partida.placarJogador1} – ${partida.placarJogador2}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  partida.jogador2Nome ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Classificação (resumo)
// ============================================================

class _CardClassificacao extends StatelessWidget {
  final Future<List<ClassificacaoJogadorModel>> futuro;
  final String meuNome;
  final VoidCallback onVerCompleta;

  const _CardClassificacao({
    required this.futuro,
    required this.meuNome,
    required this.onVerCompleta,
  });

  Color _corPosicao(int pos) {
    switch (pos) {
      case 1:
        return _ouro;
      case 2:
        return _prata;
      case 3:
        return _bronze;
      default:
        return TcgTheme.verde;
    }
  }

  String _normalizar(String s) => s.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ClassificacaoJogadorModel>>(
      future: futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const TcgGlassCard(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final lista = snapshot.data ?? [];

        if (snapshot.hasError || lista.isEmpty) {
          return TcgGlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(
                  Icons.leaderboard_outlined,
                  size: 36,
                  color: Colors.white24,
                ),
                const SizedBox(height: 10),
                Text(
                  snapshot.hasError
                      ? 'Não foi possível carregar a classificação.'
                      : 'A classificação aparece depois da primeira rodada.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TcgTheme.muted, height: 1.4),
                ),
              ],
            ),
          );
        }

        // Minha posição (procura pelo nome).
        final indice = lista.indexWhere(
          (j) => _normalizar(j.nome) == _normalizar(meuNome),
        );

        final minhaPosicao = indice >= 0 ? indice + 1 : null;
        final eu = indice >= 0 ? lista[indice] : null;

        final top = lista.take(3).toList();

        return TcgGlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (eu != null && minhaPosicao != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x1F3DDC84),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: TcgTheme.verde.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _corPosicao(minhaPosicao)
                              .withValues(alpha: 0.18),
                          border: Border.all(
                            color: _corPosicao(minhaPosicao),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '$minhaPosicaoº',
                          style: TextStyle(
                            color: _corPosicao(minhaPosicao),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sua posição',
                              style: TextStyle(
                                color: TcgTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${eu.vitorias}V • ${eu.derrotas}D • ${eu.empates}E',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${eu.pontos}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const Text(
                            'pts',
                            style: TextStyle(
                              color: TcgTheme.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'TOP 3',
                style: TextStyle(
                  color: TcgTheme.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(top.length, (i) {
                final j = top[i];
                final cor = _corPosicao(i + 1);
                final souEu = i + 1 == minhaPosicao;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${i + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _AvatarJogador(nome: j.nome, tamanho: 36, cor: cor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          j.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                souEu ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${j.pontos} pts',
                        style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onVerCompleta,
                icon: const Icon(Icons.leaderboard),
                label: const Text('Ver classificação completa'),
              ),
            ],
          ),
        );
      },
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