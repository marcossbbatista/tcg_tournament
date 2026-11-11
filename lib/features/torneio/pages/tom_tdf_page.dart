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
  final _service = TomTdfService();
  TomTdfDocumento? _importacao;
  TomTdfExportacao? _exportacao;
  bool _ocupado = false;
  String? _erro;

  bool get _modoImportacao => widget.torneioId == null;

  Future<void> _selecionarArquivo() async {
    setState(() { _ocupado = true; _erro = null; _importacao = null; });
    try {
      final arquivos = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['tdf', 'xml'],
        withData: true,
      );
      if (arquivos == null || arquivos.files.isEmpty) return;
      final bytes = arquivos.files.single.bytes;
      if (bytes == null) throw StateError('Não foi possível ler o arquivo selecionado.');
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
      builder: (c) => AlertDialog(
        title: const Text('Importar torneio?'),
        content: const Text('Será criado um NOVO torneio com os jogadores, '
            'pods, rodadas e resultados do arquivo. Nenhum torneio existente será substituído.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Importar')),
        ],
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

  @override
  Widget build(BuildContext context) => TcgTheme.wrap(Scaffold(
    appBar: AppBar(title: Text(_modoImportacao ? 'Importar arquivo TOM' : 'Exportar arquivo TOM')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TcgHero(
        title: _modoImportacao ? 'Importar torneio .tdf' : 'Exportar torneio .tdf',
        subtitle: _modoImportacao
            ? 'Abra o arquivo TOM para cadastrar o torneio inteiro no aplicativo.'
            : 'Gere o XML TOM 1.70 para conferência no programa oficial.',
        icon: _modoImportacao ? Icons.file_open_outlined : Icons.file_download_outlined,
      ),
      const SizedBox(height: 16),
      if (_erro != null) Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      )),
      if (_ocupado) const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      if (_modoImportacao) ...[
        FilledButton.icon(
          onPressed: _ocupado ? null : _selecionarArquivo,
          icon: const Icon(Icons.file_open_outlined),
          label: const Text('Selecionar arquivo .tdf'),
        ),
        if (_importacao != null) ...[
          const SizedBox(height: 18),
          _resumoImportacao(_importacao!),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _ocupado ? null : _confirmarImportacao,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar importação como novo torneio'),
          ),
        ],
      ] else ...[
        FilledButton.icon(
          onPressed: _ocupado ? null : _prepararExportacao,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Preparar e validar TDF'),
        ),
        if (_exportacao != null) ...[
          const SizedBox(height: 14),
          Text('Arquivo: ${_exportacao!.nomeArquivo}',
              style: Theme.of(context).textTheme.titleMedium),
          ..._exportacao!.avisos.map((aviso) => ListTile(
            leading: const Icon(Icons.info_outline), title: Text(aviso),
          )),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _ocupado ? null : _salvarArquivo,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Salvar arquivo .tdf'),
          ),
        ],
      ],
      const SizedBox(height: 18),
      const Text('A estrutura XML segue a amostra TOM 1.70. '
          'Não é uma certificação de compatibilidade com TOM ou Play! Tools. '
          'O sistema não substitui a finalização no programa oficial.'),
    ]),
  ));

  Widget _resumoImportacao(TomTdfDocumento doc) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(doc.dados['name'] ?? '', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Sanction ID: ${doc.dados['id'] ?? 'Não informado'}'),
        Text('Organizador: ${doc.dados['organizerName'] ?? 'Não informado'}'),
        Text('Versão TOM: ${doc.atributos['version'] ?? 'Desconhecida'}'),
        Text('Jogadores: ${doc.jogadores.length}'),
        Text('Pods: ${doc.pods.length}'),
        Text('Rodadas: ${doc.totalRodadas}'),
        Text('Partidas: ${doc.totalPartidas}'),
        if (doc.avisos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Avisos', style: Theme.of(context).textTheme.titleMedium),
          ...doc.avisos.map((a) => Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('• $a'),
          )),
        ],
      ],
    )),
  );
}
