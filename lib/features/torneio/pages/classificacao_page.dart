import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';

import '../models/classificacao_jogador_model.dart';
import '../../partida/services/rodada_service.dart';

class ClassificacaoPage extends StatefulWidget {
  final String torneioId;
  final String nomeTorneio;
  final bool classificacaoFinal;

  const ClassificacaoPage({
    super.key,
    required this.torneioId,
    required this.nomeTorneio,
    this.classificacaoFinal = false,
  });

  @override
  State<ClassificacaoPage> createState() => _ClassificacaoPageState();
}

class _ClassificacaoPageState extends State<ClassificacaoPage> {
  late Future<List<ClassificacaoJogadorModel>> _classificacao;

  @override
  void initState() {
    super.initState();

    _carregarClassificacao();
  }

  void _carregarClassificacao() {
    _classificacao = RodadaService().buscarClassificacao(
      torneioId: widget.torneioId,
    );
  }

  Future<void> _atualizar() async {
    setState(() {
      _carregarClassificacao();
    });

    await _classificacao;
  }

  String _formatarPercentual(double valor) {
    return '${(valor * 100).toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  // ============================================================
  // Painéis
  // ============================================================

  void _abrirCriterios() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: TcgTheme.card,
      builder: (_) => Theme(
        data: TcgTheme.data(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Critérios de classificação',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'A ordem em que os jogadores são desempatados.',
                  style: TextStyle(color: TcgTheme.muted, height: 1.4),
                ),
                SizedBox(height: 18),
                _CriterioLinha(numero: 1, texto: 'Pontos'),
                SizedBox(height: 10),
                _CriterioLinha(numero: 2, texto: 'Op Win %'),
                SizedBox(height: 10),
                _CriterioLinha(numero: 3, texto: 'Op Op Win %'),
                SizedBox(height: 10),
                _CriterioLinha(numero: 4, texto: 'Confronto direto'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirDetalhes(ClassificacaoJogadorModel jogador, int posicao) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: TcgTheme.card,
      builder: (_) => Theme(
        data: TcgTheme.data(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AvatarClassificacao(
                  nome: jogador.nome,
                  tamanho: 72,
                  cor: _corPosicao(posicao),
                ),
                const SizedBox(height: 14),
                Text(
                  jogador.nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$posicaoº lugar  •  ${jogador.pontos} pts',
                  style: TextStyle(
                    color: _corPosicao(posicao),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _LinhaEstatistica(
                  titulo: 'Retrospecto',
                  valor: jogador.retrospecto,
                ),
                _LinhaEstatistica(
                  titulo: 'Win %',
                  valor: _formatarPercentual(jogador.winPercentage),
                ),
                _LinhaEstatistica(
                  titulo: 'Op Win %',
                  valor: _formatarPercentual(jogador.opponentWinPercentage),
                ),
                _LinhaEstatistica(
                  titulo: 'Op Op Win %',
                  valor: _formatarPercentual(
                    jogador.opponentOpponentWinPercentage,
                  ),
                ),
                if (jogador.quantidadeByes > 0)
                  _LinhaEstatistica(
                    titulo: 'BYE',
                    valor: jogador.quantidadeByes.toString(),
                  ),
                _LinhaEstatistica(
                  titulo: 'Status',
                  valor: jogador.ativo ? 'Ativo' : 'Drop',
                  ultima: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Peças de layout
  // ============================================================

  Widget _botaoPilula({
    required IconData icone,
    required String texto,
    required VoidCallback onTap,
  }) {
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

  Widget _barraTopo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Spacer(),
          _botaoPilula(
            icone: Icons.rule_rounded,
            texto: 'Critérios',
            onTap: _abrirCriterios,
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _atualizar,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.classificacaoFinal)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x26FFD54F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 14,
                    color: Color(0xFFFFD54F),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'RESULTADO FINAL',
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            widget.classificacaoFinal ? 'Classificação final' : 'Classificação',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.nomeTorneio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _estadoCentral(IconData icone, String mensagem) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
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

  /// Lista rolável com largura máxima de 560 e pull to refresh.
  Widget _lista(List<Widget> filhos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final lateral = ((constraints.maxWidth - 560) / 2).clamp(20.0, 9999.0);

        return RefreshIndicator(
          onRefresh: _atualizar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(lateral, 8, lateral, 32),
            children: filhos,
          ),
        );
      },
    );
  }

  Widget _conteudo(List<ClassificacaoJogadorModel> jogadores) {
    if (jogadores.isEmpty) {
      return _lista([
        _cabecalho(),
        _estadoCentral(Icons.groups_outlined, 'Nenhum jogador encontrado.'),
      ]);
    }

    final comPodio = jogadores.length >= 3;
    final restantes = comPodio ? jogadores.skip(3).toList() : jogadores;
    final inicio = comPodio ? 4 : 1;

    return _lista([
      _cabecalho(),
      if (comPodio) ...[
        _Podio(
          jogadores: jogadores.take(3).toList(),
          onTap: _abrirDetalhes,
        ),
        const SizedBox(height: 24),
      ],
      ...List.generate(restantes.length, (i) {
        final posicao = inicio + i;
        final jogador = restantes[i];

        return _LinhaJogador(
          posicao: posicao,
          jogador: jogador,
          onTap: () => _abrirDetalhes(jogador, posicao),
        );
      }),
    ]);
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return TcgTheme.wrap(
      Scaffold(
        backgroundColor: TcgTheme.fundo,
        body: TcgBackground(
          child: SafeArea(
            child: Column(
              children: [
                _barraTopo(),
                Expanded(
                  child: FutureBuilder<List<ClassificacaoJogadorModel>>(
                    future: _classificacao,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return _lista([
                          _cabecalho(),
                          _estadoCentral(
                            Icons.cloud_off_outlined,
                            'Não foi possível carregar a classificação.\n'
                            'Puxe para baixo para tentar de novo.',
                          ),
                        ]);
                      }

                      return _conteudo(snapshot.data ?? []);
                    },
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
// Cores e iniciais
// ============================================================

Color _corPosicao(int posicao) {
  switch (posicao) {
    case 1:
      return const Color(0xFFFFD54F); // ouro
    case 2:
      return const Color(0xFFCFD8DC); // prata
    case 3:
      return const Color(0xFFE0955B); // bronze
    default:
      return TcgTheme.verde;
  }
}

String _iniciais(String nome) {
  final partes = nome
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();

  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first[0].toUpperCase();

  return (partes.first[0] + partes.last[0]).toUpperCase();
}

// ============================================================
// Avatar com iniciais (pronto para receber foto)
// ============================================================

class _AvatarClassificacao extends StatelessWidget {
  final String nome;
  final Color cor;
  final double tamanho;

  /// Quando existir foto de perfil, é só passar a URL aqui.
  final String? fotoUrl;

  final bool apagado;

  const _AvatarClassificacao({
    required this.nome,
    required this.cor,
    this.tamanho = 48,
    this.fotoUrl,
    this.apagado = false,
  });

  Widget _texto() {
    return Text(
      _iniciais(nome),
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

    return Opacity(
      opacity: apagado ? 0.5 : 1,
      child: Container(
        width: tamanho,
        height: tamanho,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cor.withValues(alpha: 0.18),
          border: Border.all(color: cor, width: 2),
          boxShadow: [
            BoxShadow(
              color: cor.withValues(alpha: 0.35),
              blurRadius: 16,
            ),
          ],
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
      ),
    );
  }
}

// ============================================================
// Pódio
// ============================================================

class _Podio extends StatelessWidget {
  final List<ClassificacaoJogadorModel> jogadores; // 3 primeiros
  final void Function(ClassificacaoJogadorModel, int) onTap;

  const _Podio({required this.jogadores, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodioItem(
            posicao: 2,
            jogador: jogadores[1],
            alturaDegrau: 84,
            onTap: () => onTap(jogadores[1], 2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PodioItem(
            posicao: 1,
            jogador: jogadores[0],
            alturaDegrau: 116,
            onTap: () => onTap(jogadores[0], 1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PodioItem(
            posicao: 3,
            jogador: jogadores[2],
            alturaDegrau: 64,
            onTap: () => onTap(jogadores[2], 3),
          ),
        ),
      ],
    );
  }
}

class _PodioItem extends StatelessWidget {
  final int posicao;
  final ClassificacaoJogadorModel jogador;
  final double alturaDegrau;
  final VoidCallback onTap;

  const _PodioItem({
    required this.posicao,
    required this.jogador,
    required this.alturaDegrau,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = _corPosicao(posicao);
    final primeiro = posicao == 1;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (primeiro)
            Icon(Icons.emoji_events_rounded, color: cor, size: 28)
          else
            const SizedBox(height: 28),
          const SizedBox(height: 4),
          _AvatarClassificacao(
            nome: jogador.nome,
            cor: cor,
            tamanho: primeiro ? 76 : 60,
            apagado: !jogador.ativo,
          ),
          const SizedBox(height: 10),
          Text(
            jogador.nome,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${jogador.pontos} pts',
            style: TextStyle(
              color: cor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: alturaDegrau,
            width: double.infinity,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cor.withValues(alpha: 0.35),
                  cor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border.all(color: cor.withValues(alpha: 0.4)),
            ),
            child: Text(
              '$posicao',
              style: TextStyle(
                color: cor,
                fontSize: primeiro ? 34 : 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Linha da lista
// ============================================================

class _LinhaJogador extends StatelessWidget {
  final int posicao;
  final ClassificacaoJogadorModel jogador;
  final VoidCallback onTap;

  const _LinhaJogador({
    required this.posicao,
    required this.jogador,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = _corPosicao(posicao);
    final destaque = posicao <= 3;

    return TcgGlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$posicao',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: destaque ? cor : TcgTheme.muted,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _AvatarClassificacao(
            nome: jogador.nome,
            cor: destaque ? cor : TcgTheme.verde,
            tamanho: 44,
            apagado: !jogador.ativo,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        jogador.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!jogador.ativo) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x26FFB74D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Drop',
                          style: TextStyle(
                            color: Color(0xFFFFB74D),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${jogador.vitorias}V • '
                  '${jogador.derrotas}D • '
                  '${jogador.empates}E',
                  style: const TextStyle(color: TcgTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${jogador.pontos}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'pts',
                style: TextStyle(color: TcgTheme.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }
}

// ============================================================
// Componentes dos painéis
// ============================================================

class _LinhaEstatistica extends StatelessWidget {
  final String titulo;
  final String valor;
  final bool ultima;

  const _LinhaEstatistica({
    required this.titulo,
    required this.valor,
    this.ultima = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: ultima
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0x1FFFFFFF)),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(color: TcgTheme.muted),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CriterioLinha extends StatelessWidget {
  final int numero;
  final String texto;

  const _CriterioLinha({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x263DDC84),
          ),
          child: Text(
            '$numero',
            style: const TextStyle(
              color: TcgTheme.verde,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}