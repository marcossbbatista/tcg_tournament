import 'package:flutter/material.dart';
import '../../../core/theme/tcg_theme.dart';
import '../services/tom_preflight_service.dart';

class TomPreflightPage extends StatefulWidget {
  final String torneioId;
  const TomPreflightPage({super.key, required this.torneioId});

  @override
  State<TomPreflightPage> createState() => _TomPreflightPageState();
}

class _TomPreflightPageState extends State<TomPreflightPage> {
  static const Color _amarelo = Color(0xFFFFB74D);
  static const Color _vermelho = Color(0xFFFF6B6B);

  late Future<TomPreflightResult> _resultado;

  @override
  void initState() {
    super.initState();
    _validar();
  }

  void _validar() {
    _resultado = TomPreflightService().validar(widget.torneioId);
  }

  void _validarNovamente() {
    setState(_validar);
  }

  // ============================================================
  // Peças de layout
  // ============================================================

  Widget _rotulo(String texto, {int? quantidade, Color? cor}) {
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
                color: (cor ?? TcgTheme.verde).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$quantidade',
                style: TextStyle(
                  color: cor ?? TcgTheme.verde,
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

  Widget _caixa({
    required IconData icone,
    required String texto,
    required Color cor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
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
              Icons.fact_check_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Conferência do torneio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Confira os dados antes da exportação TDF experimental.',
            style: TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _cartaoResultado(TomPreflightResult r) {
    final ok = r.dadosCompletos;
    final cor = ok ? TcgTheme.verde : _vermelho;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cor.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cor.withValues(alpha: 0.2),
            ),
            child: Icon(
              ok ? Icons.check_rounded : Icons.error_outline_rounded,
              color: cor,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'Tudo certo' : 'Precisa de atenção',
                  style: TextStyle(
                    color: cor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ok
                      ? 'Não foram encontrados erros estruturais nos dados.'
                      : '${r.erros.length} problema(s) encontrado(s).',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contador(String titulo, int valor, Color cor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Row(
          children: [
            Icon(icone, color: cor, size: 22),
            const SizedBox(width: 10),
            Text(
              '$valor',
              style: TextStyle(
                color: cor,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: TcgTheme.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo(TomPreflightResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cartaoResultado(r),
        const SizedBox(height: 12),
        Row(
          children: [
            _contador(
              'Erros',
              r.erros.length,
              r.erros.isEmpty ? TcgTheme.verde : _vermelho,
              Icons.error_outline,
            ),
            const SizedBox(width: 12),
            _contador(
              'Observações',
              r.avisos.length,
              r.avisos.isEmpty ? TcgTheme.verde : _amarelo,
              Icons.info_outline,
            ),
          ],
        ),

        if (r.erros.isNotEmpty) ...[
          const SizedBox(height: 28),
          _rotulo('Erros', quantidade: r.erros.length, cor: _vermelho),
          ...r.erros.map(
            (e) => _caixa(
              icone: Icons.error_outline,
              texto: e,
              cor: _vermelho,
            ),
          ),
        ],

        if (r.avisos.isNotEmpty) ...[
          const SizedBox(height: 28),
          _rotulo('Observações', quantidade: r.avisos.length, cor: _amarelo),
          ...r.avisos.map(
            (a) => _caixa(
              icone: Icons.info_outline,
              texto: a,
              cor: _amarelo,
            ),
          ),
        ],

        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: _validarNovamente,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Validar novamente'),
        ),

        const SizedBox(height: 24),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: TcgTheme.muted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Para gerar o arquivo, volte ao torneio e selecione '
                'Exportar torneio .tdf. A validação final deve ocorrer no '
                'TOM oficial.',
                style: TextStyle(
                  color: TcgTheme.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _estadoCarregando() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Validando os dados do torneio...',
            style: TextStyle(color: TcgTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _estadoErro(Object? erro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _caixa(
          icone: Icons.error_outline,
          texto: 'Erro na validação: $erro',
          cor: _vermelho,
        ),
        const SizedBox(height: 10),
        TcgGradientButton(
          texto: 'Tentar novamente',
          icone: Icons.refresh_rounded,
          onPressed: _validarNovamente,
        ),
      ],
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) => TcgTheme.wrap(
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

                  // Só esta área rola
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _cabecalho(),
                              const SizedBox(height: 24),
                              FutureBuilder<TomPreflightResult>(
                                future: _resultado,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState !=
                                      ConnectionState.done) {
                                    return _estadoCarregando();
                                  }

                                  if (snapshot.hasError) {
                                    return _estadoErro(snapshot.error);
                                  }

                                  return _conteudo(snapshot.data!);
                                },
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