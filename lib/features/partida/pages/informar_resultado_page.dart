import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';

import '../../../core/session/usuario_session.dart';
import '../models/partida_model.dart';
import '../services/partida_service.dart';

enum _Lado { esq, dir, empate }

enum _EstadoLado { neutro, vencedor, perdedor, empate, wo, derrota }

class _Placar {
  /// Pontos de quem venceu (ou de cada um, no empate).
  final int venc;
  final int perd;

  const _Placar(this.venc, this.perd);
}

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
  State<InformarResultadoPage> createState() => _InformarResultadoPageState();
}

class _InformarResultadoPageState extends State<InformarResultadoPage> {
  static const Color _amarelo = Color(0xFFFFB74D);
  static const Color _vermelho = Color(0xFFFF6B6B);
  static const Color _ouro = Color(0xFFFFD54F);

  final PartidaService _service = PartidaService();

  _Lado? _lado;
  _Placar? _placar;
  ResultadoPartida? _resultadoEspecial;

  bool _salvando = false;

  // ============================================================
  // Perspectiva (quem está à esquerda na tela)
  // ============================================================

  bool get _souJogador1 {
    final uid = UsuarioSession.usuario?.uid;

    return uid != null && uid == widget.partida.jogador1Uid;
  }

  bool get _souJogador2 {
    final uid = UsuarioSession.usuario?.uid;

    return uid != null && uid == widget.partida.jogador2Uid;
  }

  bool get _comPerspectiva => _souJogador1 || _souJogador2;

  String get _nome1 => widget.partida.jogador1Nome;

  String get _nome2 => widget.partida.jogador2Nome ?? 'Jogador 2';

  String get _nomeEsq => _souJogador2 ? _nome2 : _nome1;

  String get _nomeDir => _souJogador2 ? _nome1 : _nome2;

  bool get _topcut => widget.partida.fase == 'topcut';

  // ============================================================
  // Regras de placar
  // ============================================================

  List<_Placar> get _placaresVitoria => widget.formato == 'md1'
      ? const [_Placar(1, 0)]
      : const [_Placar(2, 0), _Placar(2, 1)];

  bool get _completo =>
      _resultadoEspecial != null || (_lado != null && _placar != null);

  int? get _esqPlacar {
    if (_lado == null || _placar == null) return null;

    switch (_lado!) {
      case _Lado.esq:
        return _placar!.venc;
      case _Lado.dir:
        return _placar!.perd;
      case _Lado.empate:
        return _placar!.venc;
    }
  }

  int? get _dirPlacar {
    if (_lado == null || _placar == null) return null;

    switch (_lado!) {
      case _Lado.esq:
        return _placar!.perd;
      case _Lado.dir:
        return _placar!.venc;
      case _Lado.empate:
        return _placar!.perd;
    }
  }

  void _escolherLado(_Lado lado) {
    HapticFeedback.selectionClick();

    setState(() {
      _resultadoEspecial = null;
      _lado = lado;

      if (lado == _Lado.empate) {
        _placar = const _Placar(1, 1);
      } else if (_placaresVitoria.length == 1) {
        _placar = _placaresVitoria.first;
      } else {
        _placar = null;
      }
    });
  }

  void _escolherPlacar(_Placar placar) {
    HapticFeedback.selectionClick();

    setState(() => _placar = placar);
  }

  void _escolherEspecial(ResultadoPartida? resultado) {
    HapticFeedback.selectionClick();

    setState(() {
      _resultadoEspecial = resultado;
      _lado = null;
      _placar = null;
    });
  }

  // ============================================================
  // Estado visual de cada lado
  // ============================================================

  _EstadoLado _estadoDe({required bool esquerda}) {
    final especial = _resultadoEspecial;

    if (especial != null) {
      // Este lado é o jogador 1?
      final ehJ1 = esquerda != _souJogador2;

      switch (especial) {
        case ResultadoPartida.woJogador1:
          return ehJ1 ? _EstadoLado.wo : _EstadoLado.vencedor;
        case ResultadoPartida.woJogador2:
          return ehJ1 ? _EstadoLado.vencedor : _EstadoLado.wo;
        case ResultadoPartida.derrotaDupla:
          return _EstadoLado.derrota;
        default:
          return _EstadoLado.neutro;
      }
    }

    switch (_lado) {
      case null:
        return _EstadoLado.neutro;
      case _Lado.empate:
        return _EstadoLado.empate;
      case _Lado.esq:
        return esquerda ? _EstadoLado.vencedor : _EstadoLado.perdedor;
      case _Lado.dir:
        return esquerda ? _EstadoLado.perdedor : _EstadoLado.vencedor;
    }
  }

  // ============================================================
  // Textos
  // ============================================================

  String _textoCentro() {
    final especial = _resultadoEspecial;

    if (especial != null) {
      return especial == ResultadoPartida.derrotaDupla ? 'DD' : 'W.O.';
    }

    if (_esqPlacar == null || _dirPlacar == null) return 'VS';

    return '$_esqPlacar – $_dirPlacar';
  }

  String? _resumoEscolha() {
    final especial = _resultadoEspecial;

    if (especial != null) {
      switch (especial) {
        case ResultadoPartida.woJogador1:
          return 'W.O. de $_nome1';
        case ResultadoPartida.woJogador2:
          return 'W.O. de $_nome2';
        case ResultadoPartida.derrotaDupla:
          return 'Derrota dupla';
        default:
          return 'Decisão administrativa';
      }
    }

    if (!_completo) return null;

    final esq = _esqPlacar!;
    final dir = _dirPlacar!;

    if (esq > dir) {
      return _comPerspectiva
          ? 'Você venceu por $esq x $dir'
          : '$_nomeEsq venceu por $esq x $dir';
    }

    if (esq < dir) {
      return _comPerspectiva
          ? 'Seu adversário venceu por $dir x $esq'
          : '$_nomeDir venceu por $dir x $esq';
    }

    return 'Empate por $esq x $dir';
  }

  // ============================================================
  // Salvar
  // ============================================================

  Future<void> _salvar() async {
    if (_salvando) return;

    if (!_completo) {
      _mostrarMensagem('Selecione o resultado da partida.');

      return;
    }

    final usuario = UsuarioSession.usuario;

    if (usuario == null) {
      _mostrarMensagem('Usuário não identificado.');

      return;
    }

    // Placar gravado como no banco: jogador 1 e jogador 2.
    int p1 = 0;
    int p2 = 0;

    if (_resultadoEspecial == null) {
      final esq = _esqPlacar!;
      final dir = _dirPlacar!;

      p1 = _souJogador2 ? dir : esq;
      p2 = _souJogador2 ? esq : dir;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await _service.informarResultado(
        torneioId: widget.torneioId,
        rodada: widget.rodada,
        partidaId: widget.partida.id,
        placarJogador1: p1,
        placarJogador2: p2,
        informadoPor: usuario.uid,
        resultado: _resultadoEspecial,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem('Não foi possível informar o resultado.');
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  // ============================================================
  // Painel administrativo
  // ============================================================

  void _abrirAdmin() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: TcgTheme.card,
      builder: (sheetContext) {
        void escolher(ResultadoPartida? r) {
          Navigator.pop(sheetContext);
          _escolherEspecial(r);
        }

        return Theme(
          data: TcgTheme.data(),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Decisão administrativa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Use quando um jogador não comparecer ou a partida não '
                    'puder ser jogada.',
                    style: TextStyle(color: TcgTheme.muted, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  _TileAdmin(
                    icone: Icons.person_off_outlined,
                    titulo: 'W.O. de $_nome1',
                    subtitulo: 'Vitória de $_nome2',
                    selecionado:
                        _resultadoEspecial == ResultadoPartida.woJogador1,
                    onTap: () => escolher(ResultadoPartida.woJogador1),
                  ),
                  const SizedBox(height: 10),
                  _TileAdmin(
                    icone: Icons.person_off_outlined,
                    titulo: 'W.O. de $_nome2',
                    subtitulo: 'Vitória de $_nome1',
                    selecionado:
                        _resultadoEspecial == ResultadoPartida.woJogador2,
                    onTap: () => escolher(ResultadoPartida.woJogador2),
                  ),
                  if (!_topcut) ...[
                    const SizedBox(height: 10),
                    _TileAdmin(
                      icone: Icons.close_rounded,
                      titulo: 'Derrota dupla',
                      subtitulo: 'Os dois jogadores perdem a partida',
                      selecionado:
                          _resultadoEspecial == ResultadoPartida.derrotaDupla,
                      onTap: () => escolher(ResultadoPartida.derrotaDupla),
                    ),
                  ],
                  if (_resultadoEspecial != null) ...[
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () => escolher(null),
                        child: const Text('Remover decisão administrativa'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // Peças de layout
  // ============================================================

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

  Widget _barraTopo() {
    final especialAtivo = _resultadoEspecial != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: _salvando ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Spacer(),
          if (UsuarioSession.ehAdm)
            GestureDetector(
              onTap: _abrirAdmin,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: especialAtivo
                      ? _amarelo.withValues(alpha: 0.18)
                      : const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: especialAtivo ? _amarelo : const Color(0x33FFFFFF),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.gavel,
                      size: 18,
                      color: especialAtivo ? _amarelo : TcgTheme.verde,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Admin',
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
    );
  }

  Widget _cabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Selo(texto: 'MESA ${widget.partida.mesa}', cor: TcgTheme.verde),
            _Selo(texto: 'RODADA ${widget.rodada}', cor: TcgTheme.verde),
            if (_topcut) const _Selo(texto: 'ELIMINATÓRIA', cor: _amarelo),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Quem venceu?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _resultadoEspecial != null
              ? 'Decisão administrativa selecionada.'
              : 'Toque no jogador que venceu a partida.',
          style: const TextStyle(color: TcgTheme.muted, height: 1.4),
        ),
      ],
    );
  }

  Widget _centro() {
    final temEscolha = _completo;

    return Padding(
      padding: const EdgeInsets.only(top: 30, left: 8, right: 8),
      child: SizedBox(
        width: 64,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animacao) => ScaleTransition(
            scale: animacao,
            child: FadeTransition(opacity: animacao, child: child),
          ),
          child: Container(
            key: ValueKey(_textoCentro()),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: temEscolha
                  ? const Color(0x263DDC84)
                  : const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: temEscolha ? TcgTheme.verde : const Color(0x26FFFFFF),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _textoCentro(),
                style: TextStyle(
                  color: temEscolha ? TcgTheme.verde : Colors.white54,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _arena() {
    final empate = _lado == _Lado.empate;

    return TcgGlassCard(
      padding: const EdgeInsets.fromLTRB(12, 22, 12, 18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CartaLado(
                  nome: _nomeEsq,
                  legenda: _comPerspectiva ? 'Você' : 'Jogador 1',
                  estado: _estadoDe(esquerda: true),
                  onTap: _resultadoEspecial != null || _salvando
                      ? () => _escolherLado(_Lado.esq)
                      : () => _escolherLado(_Lado.esq),
                ),
              ),
              _centro(),
              Expanded(
                child: _CartaLado(
                  nome: _nomeDir,
                  legenda: _comPerspectiva ? 'Adversário' : 'Jogador 2',
                  estado: _estadoDe(esquerda: false),
                  onTap: () => _escolherLado(_Lado.dir),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_topcut)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 15, color: _amarelo),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Fase eliminatória: não existe empate.',
                    style: TextStyle(color: _amarelo, fontSize: 12),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () => _escolherLado(_Lado.empate),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: empate
                      ? _amarelo.withValues(alpha: 0.18)
                      : const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: empate ? _amarelo : const Color(0x26FFFFFF),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.compare_arrows_rounded,
                      size: 18,
                      color: empate ? _amarelo : Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Empate',
                      style: TextStyle(
                        color: empate ? _amarelo : Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _passoPlacar() {
    final mostrar = _resultadoEspecial == null &&
        (_lado == _Lado.esq || _lado == _Lado.dir) &&
        _placaresVitoria.length > 1;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: !mostrar
          ? const SizedBox(width: double.infinity)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),
                _rotulo('Por qual placar?'),
                Row(
                  children: [
                    for (var i = 0; i < _placaresVitoria.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _BotaoPlacar(
                          placar: _placaresVitoria[i],
                          selecionado: _placar?.venc == _placaresVitoria[i].venc &&
                              _placar?.perd == _placaresVitoria[i].perd,
                          legenda: _placaresVitoria[i].perd == 0
                              ? 'Sem perder jogo'
                              : 'Foi ao terceiro jogo',
                          onTap: () => _escolherPlacar(_placaresVitoria[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
    );
  }

  Widget _rodape() {
    final resumo = _resumoEscolha();
    final temEscolha = resumo != null;

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
              Text(
                resumo ?? 'Selecione o resultado da partida.',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: temEscolha ? Colors.white : TcgTheme.muted,
                  fontSize: 13,
                  fontWeight: temEscolha ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              TcgGradientButton(
                texto: 'Enviar resultado',
                icone: Icons.check,
                carregando: _salvando,
                onPressed: temEscolha ? _salvar : null,
              ),
            ],
          ),
        ),
      ),
    );
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
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _cabecalho(),
                            const SizedBox(height: 22),
                            _arena(),
                            _passoPlacar(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _rodape(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Carta de jogador (toque para escolher o vencedor)
// ============================================================

class _CartaLado extends StatelessWidget {
  final String nome;
  final String legenda;
  final _EstadoLado estado;
  final VoidCallback onTap;

  const _CartaLado({
    required this.nome,
    required this.legenda,
    required this.estado,
    required this.onTap,
  });

  static const Color _amarelo = Color(0xFFFFB74D);
  static const Color _vermelho = Color(0xFFFF6B6B);
  static const Color _ouro = Color(0xFFFFD54F);

  Color get _cor {
    switch (estado) {
      case _EstadoLado.vencedor:
        return TcgTheme.verde;
      case _EstadoLado.empate:
        return _amarelo;
      case _EstadoLado.wo:
      case _EstadoLado.derrota:
        return _vermelho;
      case _EstadoLado.perdedor:
        return Colors.white38;
      case _EstadoLado.neutro:
        return Colors.white54;
    }
  }

  String? get _selo {
    switch (estado) {
      case _EstadoLado.vencedor:
        return 'VENCEU';
      case _EstadoLado.empate:
        return 'EMPATE';
      case _EstadoLado.wo:
        return 'W.O.';
      case _EstadoLado.derrota:
        return 'DERROTA';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vencedor = estado == _EstadoLado.vencedor;
    final apagado = estado == _EstadoLado.perdedor ||
        estado == _EstadoLado.wo ||
        estado == _EstadoLado.derrota;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: apagado ? 0.5 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
          decoration: BoxDecoration(
            color: vencedor
                ? TcgTheme.verde.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: vencedor
                  ? TcgTheme.verde
                  : (estado == _EstadoLado.empate
                      ? _amarelo.withValues(alpha: 0.6)
                      : Colors.transparent),
              width: 1.5,
            ),
            boxShadow: vencedor
                ? const [
                    BoxShadow(
                      color: Color(0x553DDC84),
                      blurRadius: 22,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 24,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: vencedor
                      ? const Icon(
                          Icons.emoji_events_rounded,
                          key: ValueKey('coroa'),
                          color: _ouro,
                          size: 22,
                        )
                      : const SizedBox.shrink(key: ValueKey('vazio')),
                ),
              ),
              const SizedBox(height: 4),
              _AvatarJogador(nome: nome, tamanho: 64, cor: _cor),
              const SizedBox(height: 10),
              Text(
                nome,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: vencedor ? FontWeight.w800 : FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                legenda,
                style: const TextStyle(color: TcgTheme.muted, fontSize: 11),
              ),
              SizedBox(
                height: 28,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _selo == null
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _cor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selo!,
                            style: TextStyle(
                              color: _cor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Botão de placar (2 – 0 / 2 – 1)
// ============================================================

class _BotaoPlacar extends StatelessWidget {
  final _Placar placar;
  final bool selecionado;
  final String legenda;
  final VoidCallback onTap;

  const _BotaoPlacar({
    required this.placar,
    required this.selecionado,
    required this.legenda,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: selecionado
              ? const Color(0x263DDC84)
              : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selecionado ? TcgTheme.verde : const Color(0x26FFFFFF),
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '${placar.venc} – ${placar.perd}',
              style: TextStyle(
                color: selecionado ? TcgTheme.verde : Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              legenda,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TcgTheme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Opção do painel administrativo
// ============================================================

class _TileAdmin extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final bool selecionado;
  final VoidCallback onTap;

  const _TileAdmin({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.selecionado,
    required this.onTap,
  });

  static const Color _amarelo = Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selecionado
              ? _amarelo.withValues(alpha: 0.14)
              : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selecionado ? _amarelo : const Color(0x26FFFFFF),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _amarelo.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: _amarelo),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TcgTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selecionado)
              const Icon(Icons.check_circle, color: _amarelo),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Componentes comuns
// ============================================================

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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