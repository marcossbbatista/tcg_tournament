import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import '../services/verificacao_email_service.dart';

class VerificarEmailPage extends StatefulWidget {
  const VerificarEmailPage({super.key});
  @override
  State<VerificarEmailPage> createState() => _VerificarEmailPageState();
}

class _VerificarEmailPageState extends State<VerificarEmailPage> {
  final _codigo = TextEditingController();
  final _servico = VerificacaoEmailService();
  bool _ocupado = false;
  bool _enviado = false;
  @override
  void initState() { super.initState(); _enviar(); }
  @override
  void dispose() { _codigo.dispose(); super.dispose(); }
  void _erro(Object e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Não foi possível concluir a verificação: $e')));
  }
  Future<void> _enviar() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try { await _servico.enviarCodigo(); if (mounted) setState(() => _enviado = true); }
    catch (e) { _erro(e); }
    finally { if (mounted) setState(() => _ocupado = false); }
  }
  Future<void> _confirmar() async {
    if (_ocupado || !RegExp(r'^\d{6}$').hasMatch(_codigo.text.trim())) {
      _erro('Informe o código de 6 números enviado ao seu e-mail.'); return;
    }
    setState(() => _ocupado = true);
    try { await _servico.confirmarCodigo(_codigo.text); if (mounted) Navigator.pop(context, true); }
    catch (e) { _erro(e); }
    finally { if (mounted) setState(() => _ocupado = false); }
  }
  @override
  Widget build(BuildContext context) => TcgTheme.wrap(Scaffold(
    backgroundColor: TcgTheme.fundo,
    appBar: AppBar(title: const Text('Confirmar e-mail'), backgroundColor: TcgTheme.fundo),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420),
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
        const Icon(Icons.mark_email_unread_outlined, size: 60, color: TcgTheme.verde),
        const SizedBox(height: 16),
        const Text('Verifique sua caixa de entrada', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Enviaremos um código de 6 dígitos para ${FirebaseAuth.instance.currentUser?.email ?? 'seu e-mail'}.',
          textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        if (_enviado) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Código enviado. Confira também o spam.', textAlign: TextAlign.center, style: TextStyle(color: TcgTheme.verde))),
        const SizedBox(height: 24),
        TextField(controller: _codigo, keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, letterSpacing: 8, color: Colors.white),
          decoration: const InputDecoration(labelText: 'Código de confirmação')),
        const SizedBox(height: 20),
        FilledButton(onPressed: _ocupado ? null : _confirmar, child: const Text('Confirmar e-mail')),
        TextButton(onPressed: _ocupado ? null : _enviar, child: const Text('Reenviar código')),
      ]))),
  ));
}
