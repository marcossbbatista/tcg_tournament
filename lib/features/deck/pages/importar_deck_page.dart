import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import '../services/decklist_parser.dart';

class ImportarDeckPage extends StatefulWidget {
  final String torneioId;
  const ImportarDeckPage({super.key, required this.torneioId});
  @override
  State<ImportarDeckPage> createState() => _ImportarDeckPageState();
}

class _ImportarDeckPageState extends State<ImportarDeckPage> {
  final _nome = TextEditingController();
  final _lista = TextEditingController();
  bool _salvando = false;
  @override
  void dispose() { _nome.dispose(); _lista.dispose(); super.dispose(); }
  Future<void> _colar() async {
    final conteudo = await Clipboard.getData(Clipboard.kTextPlain);
    if (conteudo?.text != null) _lista.text = conteudo!.text!;
  }
  Future<void> _salvar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      if (_nome.text.trim().isEmpty) throw const FormatException('Informe o nome do deck ou arquétipo.');
      final cartas = DecklistParser.interpretar(_lista.text);
      setState(() => _salvando = true);
      await FirebaseFirestore.instance.collection('tournaments').doc(widget.torneioId)
          .collection('players').doc(uid).update({
        'deckNome': _nome.text.trim(),
        'decklistTexto': _lista.text.trim(),
        'decklistCartas': cartas.map((c) => {
          'quantidade': c.quantidade, 'nome': c.nome, 'colecao': c.colecao,
          'numero': c.numero, 'categoria': c.categoria,
        }).toList(),
        'deckAtualizadoEm': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is FormatException ? e.message : 'Não foi possível salvar: $e')));
    } finally { if (mounted) setState(() => _salvando = false); }
  }
  @override
  Widget build(BuildContext context) => TcgTheme.wrap(Scaffold(
    backgroundColor: TcgTheme.fundo,
    appBar: AppBar(title: const Text('Importar decklist'), backgroundColor: TcgTheme.fundo),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Copie a decklist do Pokémon TCG Live ou Limitless e cole abaixo.', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 16),
      TextField(controller: _nome, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Deck / Arquétipo')),
      const SizedBox(height: 12),
      TextField(controller: _lista, style: const TextStyle(color: Colors.white), maxLines: 14,
        decoration: const InputDecoration(labelText: 'Decklist (60 cartas)', alignLabelWithHint: true)),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _colar, icon: const Icon(Icons.content_paste), label: const Text('Colar da área de transferência')),
      const SizedBox(height: 12),
      FilledButton(onPressed: _salvando ? null : _salvar, child: Text(_salvando ? 'Salvando...' : 'Validar e salvar deck')),
    ]),
  ));
}
