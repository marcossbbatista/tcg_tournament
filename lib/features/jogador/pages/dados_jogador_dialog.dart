import 'package:flutter/material.dart';
import '../models/jogador_torneio_model.dart';

class DadosJogadorDialog extends StatefulWidget {
  final JogadorTorneioModel? jogador;
  const DadosJogadorDialog({super.key, this.jogador});

  @override
  State<DadosJogadorDialog> createState() => _DadosJogadorDialogState();
}

class DadosJogadorPreenchidos {
  final String primeiroNome;
  final String sobrenome;
  final String playerId;
  final DateTime nascimento;
  const DadosJogadorPreenchidos(this.primeiroNome, this.sobrenome, this.playerId, this.nascimento);
}

class _DadosJogadorDialogState extends State<DadosJogadorDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _primeiroNome;
  late final TextEditingController _sobrenome;
  late final TextEditingController _playerId;
  DateTime? _nascimento;

  @override
  void initState() {
    super.initState();
    final jogador = widget.jogador;
    final partes = jogador?.nome.trim().split(RegExp(r'\s+')) ?? [];
    _primeiroNome = TextEditingController(text: jogador?.primeiroNome.isNotEmpty == true
        ? jogador!.primeiroNome : (partes.isEmpty ? '' : partes.first));
    _sobrenome = TextEditingController(text: jogador?.sobrenome.isNotEmpty == true
        ? jogador!.sobrenome : (partes.length < 2 ? '' : partes.skip(1).join(' ')));
    _playerId = TextEditingController(text: jogador?.pokemonPlayerId ?? '');
    _nascimento = jogador?.dataNascimento;
  }

  @override
  void dispose() {
    _primeiroNome.dispose();
    _sobrenome.dispose();
    _playerId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.jogador == null ? 'Inscrição presencial' : 'Dados oficiais do jogador'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _primeiroNome,
              decoration: const InputDecoration(labelText: 'Primeiro nome'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            TextFormField(
              controller: _sobrenome,
              decoration: const InputDecoration(labelText: 'Sobrenome'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            TextFormField(
              controller: _playerId,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Player ID (POP ID)'),
              validator: (v) => v == null || !RegExp(r'^\d{5,12}$').hasMatch(v.trim())
                  ? 'Informe um Player ID numérico válido' : null,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.cake_outlined),
              label: Text(_nascimento == null ? 'Selecionar nascimento' :
                  '${_nascimento!.day.toString().padLeft(2, '0')}/'
                  '${_nascimento!.month.toString().padLeft(2, '0')}/${_nascimento!.year}'),
              onPressed: () async {
                final data = await showDatePicker(
                  context: context, initialDate: _nascimento ?? DateTime(2008),
                  firstDate: DateTime(1920), lastDate: DateTime.now());
                if (data != null) setState(() => _nascimento = data);
              },
            ),
          ]),
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(onPressed: () {
        if (!_form.currentState!.validate()) return;
        if (_nascimento == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Informe a data de nascimento.')));
          return;
        }
        Navigator.pop(context, DadosJogadorPreenchidos(
            _primeiroNome.text.trim(), _sobrenome.text.trim(),
            _playerId.text.trim(), _nascimento!));
      }, child: const Text('Salvar')),
    ],
  );
}
