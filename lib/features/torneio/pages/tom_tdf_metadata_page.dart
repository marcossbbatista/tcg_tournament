import 'package:tcg_tournament/core/responsive/responsive_body.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _campos = <String, TextEditingController>{};
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
    for (final c in _campos.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('tournaments')
          .doc(widget.torneioId).get();
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
      for (final entry in valores.entries) {
        _campos[entry.key] = TextEditingController(text: entry.value);
      }
    } catch (e) {
      _erro = e.toString();
    } finally {
      if (mounted) setState(() { _carregando = false; });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _salvando = true; _erro = null; });
    try {
      final torneioRef = FirebaseFirestore.instance.collection('tournaments')
          .doc(widget.torneioId);
      final doc = await torneioRef.get();
      if (!doc.exists) throw StateError('Torneio não encontrado.');
      final atual = Map<String, dynamic>.from(doc.data()!['tomData'] as Map? ?? {});
      for (final key in ['city', 'state', 'country', 'roundtime', 'finalsroundtime']) {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Metadados TOM atualizados.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); });
    } finally {
      if (mounted) setState(() { _salvando = false; });
    }
  }

  Widget _campo(String chave, String titulo, {bool obrigatorio = false, bool numero = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: TextFormField(
        controller: _campos[chave],
        decoration: InputDecoration(labelText: titulo, border: const OutlineInputBorder()),
        keyboardType: numero ? TextInputType.number : TextInputType.text,
        validator: (texto) {
          final valor = (texto ?? '').trim();
          if (obrigatorio && valor.isEmpty) return 'Campo obrigatório.';
          if (numero && (int.tryParse(valor) == null || int.parse(valor) < 1)) {
            return 'Informe um número inteiro positivo.';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => TcgTheme.wrap(Scaffold(
    appBar: AppBar(title: const Text('Dados oficiais TOM')),
    body: ResponsiveBody(maxWidth: 720, child: _carregando ? const Center(child: CircularProgressIndicator()) :
      _campos.isEmpty ? Center(child: Text(_erro ?? 'Não foi possível carregar.')) :
      Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
        const TcgHero(title: 'Metadados do evento',
          subtitle: 'Esses valores serão incluídos no XML .tdf.',
          icon: Icons.edit_document),
        const SizedBox(height: 14),
        _campo('sanctionId', 'Sanction ID'),
        _campo('organizadorNome', 'Nome do organizador', obrigatorio: true),
        _campo('organizadorPlayerId', 'Player ID do organizador'),
        _campo('city', 'Cidade', obrigatorio: true),
        _campo('state', 'Estado / UF', obrigatorio: true),
        _campo('country', 'País', obrigatorio: true),
        _campo('roundtime', 'Duração da rodada (min)', numero: true),
        _campo('finalsroundtime', 'Duração da fase final (min)', numero: true),
        if (_erro != null) Text(_erro!,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _salvando ? null : _salvar,
          icon: const Icon(Icons.save_outlined), label: const Text('Salvar dados TOM')),
      ]))),
  ));
}
