import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/session/usuario_session.dart';
import '../../../core/theme/tcg_theme.dart';
import '../models/torneio_model.dart';
import '../services/tom_tdf_service.dart';
import '../tdf/tom_tdf_codec.dart';
import 'gerenciar_torneio_page.dart';

/// Quando não há torneioId, permite importar um novo torneio TDF.
/// Quando informado, permite exportar um torneio já cadastrado.
class TomTdfPage extends StatefulWidget {
  final String? torneioId;
  const TomTdfPage({super.key, this.torneioId});

  @override
  State<TomTdfPage> createState() => _TomTdfPageState();
}

class _TomTdfPageState extends State<TomTdfPage> {
  static const Color _amarelo = Color(0xFFFFB74D);
  static const Color _vermelho = Color(0xFFFF6B6B);

  final _service = TomTdfService();
  TomTdfDocumento? _importacao;
  TomTdfExportacao? _exportacao;
  bool _ocupado = false;
  String? _erro;

  bool get _modoImportacao => widget.torneioId == null;

  // ============================================================
  // Lógica (igual à versão anterior)
  // ============================================================

  Future<void> _selecionarArquivo() async {
    setState(() { _ocupado = true; _erro = null; _importacao = null; });
    try {
      final arquivo = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['tdf', 'xml'],
      );
      if (arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw const FormatException('TDF maior que 5 MB.');
      }
      final xml = utf8.decode(bytes, allowMalformed: false);
      final tdf = _service.lerArquivo(xml);
      if (!mounted) return;
      setState(() { _importacao = tdf; });
    } catch (e) {
      if (mounted) setState(() { _erro = _mensagem(e); });
    } finally {
      if (mounted) setState(() { _ocupado = false; });
    }
  }

  Future<void> _confirmarImportacao() async {
    final tdf = _importacao;
    final administrador = UsuarioSession.usuario;
    if (tdf == null || administrador == null || !UsuarioSession.ehAdm) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (c) => Theme(
        data: TcgTheme.data(),
        child: AlertDialog(
          title: const Text('Importar torneio?'),
          content: const Text('Será criado um NOVO torneio com os jogadores, '
              'pods, rodadas e resultados do arquivo. Nenhum torneio existente será substituído.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Importar')),
          ],
        ),
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() { _ocupado = true; _erro = null; });
    try {
      final torneio = await _service.importar(
        documento: tdf, administradorUid: administrador.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Torneio TOM importado com sucesso.')));
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => GerenciarTorneioPage(torneio: torneio),
      ));
    } catch (e) {
      if (mounted) setState(() { _erro = _mensagem(e); });
    } finally {
      if (mounted) setState(() { _ocupado = false; });
    }
  }

  Future<void> _prepararExportacao() async {
    final id = widget.torneioId;
    if (id == null) return;
    setState(() { _ocupado = true; _erro = null; _exportacao = null; });
    try {
      final resultado = await _service.exportar(id);
      if (mounted) setState(() { _exportacao = resultado; });
    } catch (e) {
      if (mounted) setState(() { _erro = _mensagem(e); });
    } finally {
      if (mounted) setState(() { _ocupado = false; });
    }
  }

  Future<void> _salvarArquivo() async {
    final exportacao = _exportacao;
    if (exportacao == null) return;
    setState(() { _ocupado = true; _erro = null; });
    try {
      final salvo = await FilePicker.saveFile(
        dialogTitle: 'Salvar torneio TOM',
        fileName: exportacao.nomeArquivo,
        type: FileType.custom,
        allowedExtensions: ['tdf'],
        bytes: Uint8List.fromList(utf8.encode(exportacao.xml)),
      );
      if (!mounted) return;
      if (salvo != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Arquivo .tdf salvo. Valide a abertura no TOM antes de uso oficial.'),
        ));
      }
    } catch (e) {
      if (mounted) setState(() { _erro = _mensagem(e); });
    } finally {
      if (mounted) setState(() { _ocupado = false; });
    }
  }

  String _mensagem(Object e) => e.toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('FormatException: ', '')
      .replaceFirst('Invalid argument(s): ', '');

  // ============================================================
  // Peças de layout
  // ============================================================

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
            child: Icon(
              _modoImportacao
                  ? Icons.file_open_outlined
                  : Icons.file_download_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _modoImportacao ? 'Importar torneio' : 'Exportar torneio',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _modoImportacao
                ? 'Abra o arquivo .tdf do TOM para cadastrar o torneio '
                    'inteiro no aplicativo.'
                : 'Gere o XML TOM 1.70 para conferência no programa oficial.',
            style: const TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
        ],
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

  Widget _caixaAviso({
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
              style: TextStyle(color: cor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carregandoLinha(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(texto, style: const TextStyle(color: TcgTheme.muted)),
        ],
      ),
    );
  }

  // ============================================================
  // Importação
  // ============================================================

  Widget _cartaoSelecionar() {
    return TcgGlassCard(
      onTap: _ocupado ? null : _selecionarArquivo,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x1F3DDC84),
            ),
            child: const Icon(
              Icons.upload_file_rounded,
              size: 34,
              color: TcgTheme.verde,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Selecionar arquivo .tdf',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aceita .tdf ou .xml, com até 5 MB.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TcgTheme.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _linhaDado(String titulo, String valor, {bool ultima = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: ultima
            ? null
            : const Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Row(
        children: [
          Text(titulo, style: const TextStyle(color: TcgTheme.muted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numero(String titulo, int valor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Column(
          children: [
            Icon(icone, size: 18, color: TcgTheme.verde),
            const SizedBox(height: 8),
            Text(
              '$valor',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: const TextStyle(color: TcgTheme.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumoImportacao(TomTdfDocumento doc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rotulo('Conteúdo do arquivo'),
        TcgGlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0x1F3DDC84),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: TcgTheme.verde,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      doc.dados['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _numero('Jogadores', doc.jogadores.length, Icons.groups),
                  const SizedBox(width: 8),
                  _numero('Pods', doc.pods.length, Icons.view_module_rounded),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _numero('Rodadas', doc.totalRodadas, Icons.repeat),
                  const SizedBox(width: 8),
                  _numero(
                    'Partidas',
                    doc.totalPartidas,
                    Icons.sports_esports,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _linhaDado(
                'Sanction ID',
                '${doc.dados['id'] ?? 'Não informado'}',
              ),
              _linhaDado(
                'Organizador',
                '${doc.dados['organizerName'] ?? 'Não informado'}',
              ),
              _linhaDado(
                'Versão TOM',
                '${doc.atributos['version'] ?? 'Desconhecida'}',
                ultima: true,
              ),
            ],
          ),
        ),
        if (doc.avisos.isNotEmpty) ...[
          const SizedBox(height: 20),
          _rotulo('Avisos'),
          ...doc.avisos.map(
            (a) => _caixaAviso(
              icone: Icons.info_outline,
              texto: a,
              cor: _amarelo,
            ),
          ),
        ],
        const SizedBox(height: 20),
        TcgGradientButton(
          texto: 'Importar como novo torneio',
          icone: Icons.check_circle_outline,
          onPressed: _ocupado ? null : _confirmarImportacao,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _ocupado ? null : _selecionarArquivo,
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Trocar arquivo'),
        ),
      ],
    );
  }

  List<Widget> _blocoImportacao() {
    final doc = _importacao;

    if (_ocupado && doc == null) {
      return [_carregandoLinha('Lendo o arquivo...')];
    }

    if (doc == null) {
      return [_cartaoSelecionar()];
    }

    return [
      _resumoImportacao(doc),
      if (_ocupado) _carregandoLinha('Processando...'),
    ];
  }

  // ============================================================
  // Exportação
  // ============================================================

  List<Widget> _blocoExportacao() {
    final exp = _exportacao;

    if (exp == null) {
      return [
        _rotulo('Preparação'),
        TcgGlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Antes de salvar, o app valida os dados do torneio e mostra '
                'o que precisa de atenção.',
                style: TextStyle(color: TcgTheme.muted, height: 1.4),
              ),
              const SizedBox(height: 18),
              TcgGradientButton(
                texto: 'Preparar e validar',
                icone: Icons.fact_check_outlined,
                carregando: _ocupado,
                onPressed: _ocupado ? null : _prepararExportacao,
              ),
            ],
          ),
        ),
      ];
    }

    return [
      _rotulo('Arquivo pronto'),
      TcgGlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0x1F3DDC84),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: TcgTheme.verde,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nome do arquivo',
                    style: TextStyle(color: TcgTheme.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exp.nomeArquivo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (exp.avisos.isNotEmpty) ...[
        const SizedBox(height: 20),
        _rotulo('Avisos da validação'),
        ...exp.avisos.map(
          (a) => _caixaAviso(
            icone: Icons.info_outline,
            texto: a,
            cor: _amarelo,
          ),
        ),
      ] else ...[
        const SizedBox(height: 14),
        _caixaAviso(
          icone: Icons.check_circle_outline,
          texto: 'Nenhum aviso. O arquivo está pronto para salvar.',
          cor: TcgTheme.verde,
        ),
      ],
      const SizedBox(height: 10),
      TcgGradientButton(
        texto: 'Salvar arquivo .tdf',
        icone: Icons.download_rounded,
        carregando: _ocupado,
        onPressed: _ocupado ? null : _salvarArquivo,
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _ocupado ? null : _prepararExportacao,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Validar novamente'),
      ),
    ];
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

                              if (_erro != null)
                                _caixaAviso(
                                  icone: Icons.error_outline,
                                  texto: _erro!,
                                  cor: _vermelho,
                                ),

                              if (_modoImportacao)
                                ..._blocoImportacao()
                              else
                                ..._blocoExportacao(),

                              const SizedBox(height: 24),
                              const Text(
                                'A estrutura XML segue a amostra TOM 1.70. '
                                'Não é uma certificação de compatibilidade '
                                'com TOM ou Play! Tools. O sistema não '
                                'substitui a finalização no programa oficial.',
                                style: TextStyle(
                                  color: TcgTheme.muted,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
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