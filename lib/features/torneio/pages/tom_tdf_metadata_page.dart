import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/tcg_theme.dart';
import '../models/torneio_model.dart';

class TomTdfMetadataPage extends StatefulWidget {
  final String torneioId;
  const TomTdfMetadataPage({super.key, required this.torneioId});

  @override
  State<TomTdfMetadataPage> createState() => _TomTdfMetadataPageState();
}

class _TomTdfMetadataPageState extends State<TomTdfMetadataPage> {
  static const Color _amarelo = Color(0xFFFFB74D);
  static const Color _vermelho = Color(0xFFFF6B6B);

  final _formKey = GlobalKey<FormState>();
  final _campos = <String, TextEditingController>{};

  /// Valores como foram carregados (para detectar alterações).
  final _originais = <String, String>{};

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // Lógica
  // ============================================================

  bool get _alterado {
    if (_campos.isEmpty) return false;

    for (final entry in _campos.entries) {
      if (entry.value.text.trim() != (_originais[entry.key] ?? '').trim()) {
        return true;
      }
    }

    return false;
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.torneioId)
          .get();
      if (!doc.exists) throw StateError('Torneio não encontrado.');
      final dados = doc.data()!;
      final torneio = TorneioModel.fromMap(doc.id, dados);
      final tom = Map<String, dynamic>.from(dados['tomData'] as Map? ?? {});
      final valores = <String, String>{
        'sanctionId': torneio.sanctionId ?? '',
        'organizadorNome': torneio.organizadorNome,
        'organizadorPlayerId': torneio.organizadorPlayerId ?? '',
        'city': tom['city']?.toString() ?? '',
        'state': tom['state']?.toString() ?? '',
        'country': tom['country']?.toString() ?? 'Brazil',
        'roundtime': tom['roundtime']?.toString() ?? '50',
        'finalsroundtime': tom['finalsroundtime']?.toString() ?? '60',
      };

      for (final c in _campos.values) {
        c.dispose();
      }
      _campos.clear();
      _originais
        ..clear()
        ..addAll(valores);

      for (final entry in valores.entries) {
        final controller = TextEditingController(text: entry.value);
        controller.addListener(_atualizar);
        _campos[entry.key] = controller;
      }
    } catch (e) {
      _erro = e.toString();
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final torneioRef = FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.torneioId);
      final doc = await torneioRef.get();
      if (!doc.exists) throw StateError('Torneio não encontrado.');
      final atual =
          Map<String, dynamic>.from(doc.data()!['tomData'] as Map? ?? {});
      for (final key in [
        'city',
        'state',
        'country',
        'roundtime',
        'finalsroundtime',
      ]) {
        atual[key] = _campos[key]!.text.trim();
      }
      atual['organizerName'] = _campos['organizadorNome']!.text.trim();
      atual['organizerPopid'] = _campos['organizadorPlayerId']!.text.trim();
      atual['id'] = _campos['sanctionId']!.text.trim();
      await torneioRef.update({
        'sanctionId': atual['id'],
        'organizadorNome': atual['organizerName'],
        'organizadorPlayerId': atual['organizerPopid'],
        'tomData': atual,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metadados TOM atualizados.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<bool> _confirmarDescarte() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (_) => Theme(
        data: TcgTheme.data(),
        child: AlertDialog(
          title: const Text('Descartar alterações?'),
          content: const Text(
            'Você alterou os dados e ainda não salvou. '
            'Se sair agora, as alterações serão perdidas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuar editando'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      ),
    );

    return descartar == true;
  }

  Future<void> _voltar() async {
    if (_salvando) return;

    FocusScope.of(context).unfocus();

    if (!_alterado || await _confirmarDescarte()) {
      if (mounted) Navigator.pop(context);
    }
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

  Widget _campo(
    String chave,
    String titulo, {
    bool obrigatorio = false,
    bool numero = false,
    String? sufixo,
    String? ajuda,
    TextInputAction acao = TextInputAction.next,
    TextCapitalization capitalizacao = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: _campos[chave],
      textInputAction: acao,
      textCapitalization: capitalizacao,
      keyboardType: numero ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: titulo,
        helperText: ajuda,
        suffixText: sufixo,
      ),
      validator: (texto) {
        final valor = (texto ?? '').trim();
        if (obrigatorio && valor.isEmpty) return 'Campo obrigatório.';
        if (numero && (int.tryParse(valor) == null || int.parse(valor) < 1)) {
          return 'Informe um número inteiro positivo.';
        }
        return null;
      },
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
              Icons.edit_document,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Metadados do evento',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esses valores serão incluídos no XML .tdf exportado para o TOM.',
            style: TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _rotulo('Evento'),
          _campo('sanctionId', 'Sanction ID', ajuda: 'Código do Play! Tools.'),
          const SizedBox(height: 16),
          _campo(
            'organizadorNome',
            'Nome do organizador',
            obrigatorio: true,
            capitalizacao: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _campo('organizadorPlayerId', 'Player ID do organizador'),

          const SizedBox(height: 28),
          _rotulo('Local'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _campo(
                  'city',
                  'Cidade',
                  obrigatorio: true,
                  capitalizacao: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _campo(
                  'state',
                  'Estado / UF',
                  obrigatorio: true,
                  capitalizacao: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _campo(
            'country',
            'País',
            obrigatorio: true,
            capitalizacao: TextCapitalization.words,
          ),

          const SizedBox(height: 28),
          _rotulo('Tempo de rodada'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _campo(
                  'roundtime',
                  'Rodada',
                  numero: true,
                  sufixo: 'min',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _campo(
                  'finalsroundtime',
                  'Fase final',
                  numero: true,
                  sufixo: 'min',
                  acao: TextInputAction.done,
                ),
              ),
            ],
          ),

          if (_erro != null) ...[
            const SizedBox(height: 20),
            _caixa(
              icone: Icons.error_outline,
              texto: _erro!,
              cor: _vermelho,
            ),
          ],
        ],
      ),
    );
  }

  Widget _estadoErroCarregar() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _caixa(
                icone: Icons.error_outline,
                texto: _erro ?? 'Não foi possível carregar.',
                cor: _vermelho,
              ),
              const SizedBox(height: 14),
              TcgGradientButton(
                texto: 'Tentar novamente',
                icone: Icons.refresh_rounded,
                onPressed: _carregar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_campos.isEmpty) {
      return _estadoErroCarregar();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cabecalho(),
              const SizedBox(height: 28),
              _formulario(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rodape() {
    final alterado = _alterado;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xCC14142B),
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                alterado ? 'Alterações não salvas' : 'Nenhuma alteração ainda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: alterado ? _amarelo : TcgTheme.muted,
                  fontSize: 12,
                  fontWeight: alterado ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              TcgGradientButton(
                texto: 'Salvar dados TOM',
                icone: Icons.save_outlined,
                carregando: _salvando,
                onPressed: alterado ? _salvar : null,
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
    final mostrarRodape = !_carregando && _campos.isNotEmpty;

    return PopScope(
      canPop: !_alterado,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        if (await _confirmarDescarte() && mounted) {
          Navigator.pop(context);
        }
      },
      child: TcgTheme.wrap(
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
                        onPressed: _voltar,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Só esta área rola
                  Expanded(child: _corpo()),

                  // Barra fixa embaixo
                  if (mostrarRodape) _rodape(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}