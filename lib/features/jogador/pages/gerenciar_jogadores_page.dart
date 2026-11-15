import 'dart:math' as math;

import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';
import 'package:tcg_tournament/features/jogador/service/jogador_torneio_service.dart';

import '../models/jogador_torneio_model.dart';
import 'dados_jogador_dialog.dart';

class GerenciarJogadoresPage extends StatefulWidget {
  final String torneioId;
  final String nomeTorneio;

  const GerenciarJogadoresPage({
    super.key,
    required this.torneioId,
    required this.nomeTorneio,
  });

  @override
  State<GerenciarJogadoresPage> createState() => _GerenciarJogadoresPageState();
}

class _GerenciarJogadoresPageState extends State<GerenciarJogadoresPage> {
  static const Color _amarelo = Color(0xFFFFB74D);
  static const Color _vermelho = Color(0xFFFF6B6B);
  static const Color _cinza = Color(0xFF8A8AA3);

  final JogadorTorneioService _service = JogadorTorneioService();
  final TextEditingController _buscaController = TextEditingController();

  late final Stream<List<JogadorTorneioModel>> _stream;

  bool _mostrarRecusados = false;

  @override
  void initState() {
    super.initState();
    _stream = _service.listarJogadores(widget.torneioId);
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // ============================================================
  // Ações
  // ============================================================

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _aprovar(JogadorTorneioModel jogador) async {
    try {
      await _service.aprovarJogador(
        torneioId: widget.torneioId,
        jogadorUid: jogador.uid,
      );

      _mostrarMensagem('${jogador.nome} foi aprovado.');
    } catch (e) {
      _mostrarMensagem('Não foi possível aprovar o jogador.');
    }
  }

  Future<void> _recusar(JogadorTorneioModel jogador) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recusar jogador'),
          content: Text(
            'Deseja realmente recusar a participação de ${jogador.nome}?',
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
              child: const Text('Recusar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _service.recusarJogador(
        torneioId: widget.torneioId,
        jogadorUid: jogador.uid,
      );

      _mostrarMensagem('${jogador.nome} foi recusado.');
    } catch (e) {
      _mostrarMensagem('Não foi possível recusar o jogador.');
    }
  }

  Future<void> _editarOficiais(JogadorTorneioModel jogador) async {
    final dados = await showDialog<DadosJogadorPreenchidos>(
      context: context,
      builder: (_) => DadosJogadorDialog(jogador: jogador),
    );

    if (dados == null || !mounted) return;

    try {
      await _service.atualizarDadosOficiais(
        torneioId: widget.torneioId,
        jogadorUid: jogador.uid,
        primeiroNome: dados.primeiroNome,
        sobrenome: dados.sobrenome,
        pokemonPlayerId: dados.playerId,
        dataNascimento: dados.nascimento,
      );

      _mostrarMensagem('Dados oficiais atualizados.');
    } catch (e) {
      _mostrarMensagem('Não foi possível salvar: $e');
    }
  }

  Future<void> _cadastrarPresencial() async {
    final dados = await showDialog<DadosJogadorPreenchidos>(
      context: context,
      builder: (_) => const DadosJogadorDialog(),
    );

    if (dados == null || !mounted) return;

    try {
      await _service.cadastrarJogadorPresencial(
        torneioId: widget.torneioId,
        primeiroNome: dados.primeiroNome,
        sobrenome: dados.sobrenome,
        pokemonPlayerId: dados.playerId,
        dataNascimento: dados.nascimento,
      );

      _mostrarMensagem('Jogador inscrito.');
    } catch (e) {
      _mostrarMensagem('Não foi possível cadastrar: $e');
    }
  }

  Future<void> _desistir(JogadorTorneioModel jogador) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar desistência'),
        content: Text(
          'Marcar ${jogador.nome} como desistente após a rodada atual?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirma != true || !mounted) return;

    try {
      await _service.registrarDesistencia(
        torneioId: widget.torneioId,
        jogadorUid: jogador.uid,
      );

      _mostrarMensagem('Desistência registrada.');
    } catch (e) {
      _mostrarMensagem('Não foi possível registrar: $e');
    }
  }

  // ============================================================
  // Painel de detalhes do jogador
  // ============================================================

  void _abrirDetalhes(JogadorTorneioModel jogador) {
    final podeEditar = jogador.status == 'aprovado' &&
        jogador.uid.startsWith('pop_');
    final podeDesistir = jogador.status == 'aprovado' && jogador.ativo;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: TcgTheme.card,
      builder: (sheetContext) => Theme(
        data: TcgTheme.data(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AvatarJogador(
                  nome: jogador.nome,
                  tamanho: 84,
                  gradiente: _gradientePorStatus(jogador.status),
                  apagado: !jogador.ativo || jogador.status == 'recusado',
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
                const SizedBox(height: 4),
                Text(
                  jogador.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TcgTheme.muted),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChipInfo(
                      icone: Icons.circle,
                      texto: _textoStatus(jogador.status),
                      cor: _corStatus(jogador.status),
                    ),
                    if (!jogador.ativo)
                      const _ChipInfo(
                        icone: Icons.person_remove_outlined,
                        texto: 'Desistente',
                        cor: _amarelo,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _LinhaDetalhe(
                  titulo: 'Player ID',
                  valor: jogador.pokemonPlayerId ?? 'Não informado',
                ),
                _LinhaDetalhe(
                  titulo: 'Divisão',
                  valor: jogador.divisaoEtaria ?? 'Sem divisão',
                  ultima: !podeEditar && !podeDesistir,
                ),
                if (podeEditar || podeDesistir) const SizedBox(height: 18),
                if (podeEditar)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _editarOficiais(jogador);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar dados oficiais'),
                  ),
                if (podeEditar && podeDesistir) const SizedBox(height: 10),
                if (podeDesistir)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _desistir(jogador);
                    },
                    icon: const Icon(Icons.person_remove_outlined),
                    label: const Text('Registrar desistência'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Helpers de status
  // ============================================================

  String _textoStatus(String status) {
    switch (status) {
      case 'aprovado':
        return 'Aprovado';
      case 'recusado':
        return 'Recusado';
      default:
        return 'Pendente';
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'aprovado':
        return TcgTheme.verde;
      case 'recusado':
        return _vermelho;
      default:
        return _amarelo;
    }
  }

  Gradient _gradientePorStatus(String status) {
    switch (status) {
      case 'aprovado':
        return TcgTheme.gradient;

      case 'recusado':
        return const LinearGradient(
          colors: [Color(0xFF6B6B85), Color(0xFF45455C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

      default:
        return const LinearGradient(
          colors: [Color(0xFFFFCC80), Color(0xFFF5A02B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  // ============================================================
  // Peças de layout
  // ============================================================

  Widget _rotulo(String texto, {int? quantidade, Color? corQuantidade}) {
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
                color: (corQuantidade ?? TcgTheme.verde)
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$quantidade',
                style: TextStyle(
                  color: corQuantidade ?? TcgTheme.verde,
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

  Widget _barraTopo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _cadastrarPresencial,
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
                  Icon(
                    Icons.person_add_alt_1,
                    size: 18,
                    color: TcgTheme.verde,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Presencial',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jogadores',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.nomeTorneio,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: TcgTheme.muted),
          ),
        ],
      ),
    );
  }

  // ===== Resumo com anel =====

  Widget _resumo({
    required int aprovados,
    required int pendentes,
    required int recusados,
    required Map<String, int> divisoes,
  }) {
    return TcgGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 124,
                height: 124,
                child: CustomPaint(
                  painter: _AnelPainter(
                    aprovados: aprovados,
                    pendentes: pendentes,
                    recusados: recusados,
                    corAprovados: TcgTheme.verde,
                    corPendentes: _amarelo,
                    corRecusados: _cinza,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$aprovados',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'aprovados',
                          style: TextStyle(
                            color: TcgTheme.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _LegendaAnel(
                      cor: TcgTheme.verde,
                      titulo: 'Aprovados',
                      quantidade: aprovados,
                    ),
                    const SizedBox(height: 12),
                    _LegendaAnel(
                      cor: _amarelo,
                      titulo: 'Pendentes',
                      quantidade: pendentes,
                    ),
                    const SizedBox(height: 12),
                    _LegendaAnel(
                      cor: _cinza,
                      titulo: 'Recusados',
                      quantidade: recusados,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (divisoes.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 14),
            const Text(
              'POR DIVISÃO',
              style: TextStyle(
                color: TcgTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: divisoes.entries
                  .map(
                    (e) => _ChipInfo(
                      icone: Icons.cake_outlined,
                      texto: '${e.key}  ${e.value}',
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ===== Fila de aprovação =====

  Widget _filaAprovacao(List<JogadorTorneioModel> pendentes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rotulo(
          'Fila de aprovação',
          quantidade: pendentes.length,
          corQuantidade: _amarelo,
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.swipe_rounded, size: 16, color: TcgTheme.muted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Deslize para a direita para aprovar ou para a esquerda '
                  'para recusar.',
                  style: TextStyle(
                    color: TcgTheme.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...pendentes.map((jogador) => _cartaPendente(jogador)),
      ],
    );
  }

  Widget _cartaPendente(JogadorTorneioModel jogador) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Dismissible(
          key: ValueKey('pendente_${jogador.uid}'),
          // A ação é feita aqui e a lista some pelo stream.
          confirmDismiss: (direcao) async {
            if (direcao == DismissDirection.startToEnd) {
              await _aprovar(jogador);
            } else {
              await _recusar(jogador);
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            color: const Color(0x663DDC84),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Aprovar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: const Color(0x66FF6B6B),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recusar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.cancel, color: Colors.white),
              ],
            ),
          ),
          child: TcgGlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _abrirDetalhes(jogador),
                  child: Row(
                    children: [
                      _AvatarJogador(
                        nome: jogador.nome,
                        tamanho: 56,
                        gradiente: _gradientePorStatus('pendente'),
                        // fotoUrl: jogador.fotoUrl, // quando existir no model
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              jogador.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              jogador.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: TcgTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (jogador.pokemonPlayerId != null)
                                  _ChipInfo(
                                    icone: Icons.confirmation_number_outlined,
                                    texto: jogador.pokemonPlayerId!,
                                  ),
                                _ChipInfo(
                                  icone: Icons.cake_outlined,
                                  texto: jogador.divisaoEtaria ?? 'sem divisão',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _recusar(jogador),
                        child: const Text('Recusar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TcgGradientButton(
                        texto: 'Aprovar',
                        onPressed: () => _aprovar(jogador),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== Grade de cartas =====

  Widget _buscaCampo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: _buscaController,
        textInputAction: TextInputAction.search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Buscar por nome, e-mail ou Player ID',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _buscaController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _buscaController.clear();
                    setState(() {});
                  },
                ),
        ),
      ),
    );
  }

  Widget _gradeAprovados(List<JogadorTorneioModel> aprovados) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const espaco = 12.0;
        final largura = (constraints.maxWidth - espaco) / 2;

        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: aprovados
              .map(
                (j) => SizedBox(
                  width: largura,
                  child: _CartaJogador(
                    jogador: j,
                    gradiente: _gradientePorStatus('aprovado'),
                    onTap: () => _abrirDetalhes(j),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // ===== Recusados =====

  Widget _secaoRecusados(List<JogadorTorneioModel> recusados) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _mostrarRecusados = !_mostrarRecusados),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'RECUSADOS',
                        style: TextStyle(
                          color: TcgTheme.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _cinza.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${recusados.length}',
                          style: const TextStyle(
                            color: _cinza,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _mostrarRecusados
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
        if (_mostrarRecusados)
          ...recusados.map(
            (j) => TcgGlassCard(
              onTap: () => _abrirDetalhes(j),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _AvatarJogador(
                    nome: j.nome,
                    tamanho: 40,
                    gradiente: _gradientePorStatus('recusado'),
                    apagado: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          j.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          j.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
          ),
      ],
    );
  }

  Widget _vazioGeral() {
    return TcgGlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(Icons.groups_outlined, size: 48, color: Colors.white24),
          const SizedBox(height: 14),
          const Text(
            'Nenhum jogador ainda',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Compartilhe o código do torneio ou inscreva jogadores '
            'presencialmente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          TcgGradientButton(
            texto: 'Inscrever jogador',
            icone: Icons.person_add_alt_1,
            onPressed: _cadastrarPresencial,
          ),
        ],
      ),
    );
  }

  // ===== Corpo =====

  Widget _corpo(List<JogadorTorneioModel> jogadores) {
    final pendentes = jogadores.where((j) => j.status == 'pendente').toList();
    final aprovados = jogadores.where((j) => j.status == 'aprovado').toList();
    final recusados = jogadores.where((j) => j.status == 'recusado').toList();

    final divisoes = <String, int>{};
    for (final j in aprovados) {
      final chave = j.divisaoEtaria ?? 'Sem divisão';
      divisoes[chave] = (divisoes[chave] ?? 0) + 1;
    }

    final termo = _buscaController.text.trim().toLowerCase();

    final aprovadosFiltrados = termo.isEmpty
        ? aprovados
        : aprovados.where((j) {
            return j.nome.toLowerCase().contains(termo) ||
                j.email.toLowerCase().contains(termo) ||
                (j.pokemonPlayerId ?? '').toLowerCase().contains(termo);
          }).toList();

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cabecalho(),

              if (jogadores.isEmpty)
                _vazioGeral()
              else ...[
                _resumo(
                  aprovados: aprovados.length,
                  pendentes: pendentes.length,
                  recusados: recusados.length,
                  divisoes: divisoes,
                ),

                if (pendentes.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _filaAprovacao(pendentes),
                ],

                const SizedBox(height: 28),
                _rotulo('Jogadores', quantidade: aprovados.length),

                if (aprovados.length >= 8) _buscaCampo(),

                if (aprovados.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Nenhum jogador aprovado ainda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TcgTheme.muted),
                    ),
                  )
                else if (aprovadosFiltrados.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Nenhum jogador encontrado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TcgTheme.muted),
                    ),
                  )
                else
                  _gradeAprovados(aprovadosFiltrados),

                if (recusados.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  _secaoRecusados(recusados),
                ],
              ],
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
        resizeToAvoidBottomInset: true,
        body: TcgBackground(
          child: SafeArea(
            child: Column(
              children: [
                _barraTopo(),
                Expanded(
                  child: StreamBuilder<List<JogadorTorneioModel>>(
                    stream: _stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Não foi possível carregar os jogadores.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return _corpo(snapshot.data ?? []);
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
// Anel de resumo
// ============================================================

class _AnelPainter extends CustomPainter {
  final int aprovados;
  final int pendentes;
  final int recusados;
  final Color corAprovados;
  final Color corPendentes;
  final Color corRecusados;

  const _AnelPainter({
    required this.aprovados,
    required this.pendentes,
    required this.recusados,
    required this.corAprovados,
    required this.corPendentes,
    required this.corRecusados,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const espessura = 12.0;

    final centro = Offset(size.width / 2, size.height / 2);
    final raio = (math.min(size.width, size.height) - espessura) / 2;
    final rect = Rect.fromCircle(center: centro, radius: raio);

    final trilha = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      ..color = const Color(0x1FFFFFFF);

    canvas.drawCircle(centro, raio, trilha);

    final total = aprovados + pendentes + recusados;
    if (total == 0) return;

    final segmentos = <MapEntry<int, Color>>[
      MapEntry(aprovados, corAprovados),
      MapEntry(pendentes, corPendentes),
      MapEntry(recusados, corRecusados),
    ].where((s) => s.key > 0).toList();

    final folga = segmentos.length > 1 ? 0.16 : 0.0;
    var inicio = -math.pi / 2;

    for (final s in segmentos) {
      final varredura = 2 * math.pi * s.key / total;
      final desenho = math.max(varredura - folga, 0.02);

      final pincel = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura
        ..strokeCap = StrokeCap.round
        ..color = s.value;

      canvas.drawArc(rect, inicio + folga / 2, desenho, false, pincel);

      inicio += varredura;
    }
  }

  @override
  bool shouldRepaint(covariant _AnelPainter old) {
    return old.aprovados != aprovados ||
        old.pendentes != pendentes ||
        old.recusados != recusados;
  }
}

class _LegendaAnel extends StatelessWidget {
  final Color cor;
  final String titulo;
  final int quantidade;

  const _LegendaAnel({
    required this.cor,
    required this.titulo,
    required this.quantidade,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(color: TcgTheme.muted),
          ),
        ),
        Text(
          '$quantidade',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Carta de jogador
// ============================================================

class _CartaJogador extends StatelessWidget {
  final JogadorTorneioModel jogador;
  final Gradient gradiente;
  final VoidCallback onTap;

  const _CartaJogador({
    required this.jogador,
    required this.gradiente,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final desistente = !jogador.ativo;

    return TcgGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _AvatarJogador(
                nome: jogador.nome,
                tamanho: 64,
                gradiente: gradiente,
                apagado: desistente,
                // fotoUrl: jogador.fotoUrl, // quando existir no model
              ),
              if (desistente)
                Positioned(
                  right: -4,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFB74D),
                    ),
                    child: const Icon(
                      Icons.person_remove,
                      size: 12,
                      color: TcgTheme.fundo,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: Center(
              child: Text(
                jogador.nome,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: desistente ? Colors.white54 : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ChipInfo(
            icone: Icons.cake_outlined,
            texto: jogador.divisaoEtaria ?? 'sem divisão',
          ),
          const SizedBox(height: 8),
          Text(
            jogador.pokemonPlayerId ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TcgTheme.muted,
              fontSize: 11,
              letterSpacing: 0.5,
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

  /// Quando existir foto de perfil, é só passar a URL aqui.
  final String? fotoUrl;

  final double tamanho;
  final Gradient gradiente;
  final bool apagado;

  const _AvatarJogador({
    required this.nome,
    required this.gradiente,
    this.fotoUrl,
    this.tamanho = 52,
    this.apagado = false,
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

  Widget _textoIniciais() {
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

    return Opacity(
      opacity: apagado ? 0.5 : 1,
      child: Container(
        width: tamanho,
        height: tamanho,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradiente,
        ),
        child: temFoto
            ? ClipOval(
                child: Image.network(
                  fotoUrl!,
                  width: tamanho,
                  height: tamanho,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _textoIniciais(),
                ),
              )
            : _textoIniciais(),
      ),
    );
  }
}

// ============================================================
// Chip pequeno e linha de detalhe
// ============================================================

class _ChipInfo extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Color cor;

  const _ChipInfo({
    required this.icone,
    required this.texto,
    this.cor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: cor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaDetalhe extends StatelessWidget {
  final String titulo;
  final String valor;
  final bool ultima;

  const _LinhaDetalhe({
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