import 'package:flutter/material.dart';

import '../../../core/session/usuario_session.dart';
import '../services/torneio_service.dart';

class CriarTorneioPage extends StatefulWidget {
  const CriarTorneioPage({super.key});

  @override
  State<CriarTorneioPage> createState() => _CriarTorneioPageState();
}

class _CriarTorneioPageState extends State<CriarTorneioPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _quantidadeRodadasController =
      TextEditingController();

  final TorneioService _torneioService = TorneioService();

  DateTime? _dataSelecionada;
  TimeOfDay? _horarioSelecionado;

  String _formatoSelecionado = 'md3';

  bool _salvando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeRodadasController.dispose();

    super.dispose();
  }

  Future<void> _selecionarData() async {
    final DateTime agora = DateTime.now();

    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: agora,
      firstDate: agora,
      lastDate: DateTime(
        agora.year + 5,
      ),
    );

    if (data == null) return;

    setState(() {
      _dataSelecionada = data;
    });
  }

  Future<void> _selecionarHorario() async {
    final TimeOfDay? horario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (horario == null) return;

    setState(() {
      _horarioSelecionado = horario;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dataSelecionada == null) {
      _mostrarMensagem('Selecione a data do torneio.');

      return;
    }

    if (_horarioSelecionado == null) {
      _mostrarMensagem('Selecione o horário do torneio.');

      return;
    }

    final usuario = UsuarioSession.usuario;

    if (usuario == null) {
      _mostrarMensagem('Usuário não identificado.');

      return;
    }

    final DateTime dataHora = DateTime(
      _dataSelecionada!.year,
      _dataSelecionada!.month,
      _dataSelecionada!.day,
      _horarioSelecionado!.hour,
      _horarioSelecionado!.minute,
    );

    setState(() {
      _salvando = true;
    });

    try {
      final torneio = await _torneioService.criarTorneio(
        nome: _nomeController.text.trim(),
        dataHora: dataHora,
        formato: _formatoSelecionado,
        quantidadeRodadas: int.parse(
          _quantidadeRodadasController.text,
        ),
        criadoPor: usuario.uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Torneio criado com sucesso. Código: ${torneio.codigo}',
          ),
        ),
      );

      Navigator.pop(
        context,
        torneio,
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível criar o torneio.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar torneio'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do torneio',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe o nome do torneio.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _formatoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Formato',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'md1',
                      child: Text('MD1'),
                    ),
                    DropdownMenuItem(
                      value: 'md3',
                      child: Text('MD3'),
                    ),
                  ],
                  onChanged: (valor) {
                    if (valor == null) return;

                    setState(() {
                      _formatoSelecionado = valor;
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _quantidadeRodadasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de rodadas',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe a quantidade de rodadas.';
                    }

                    final quantidade = int.tryParse(valor);

                    if (quantidade == null || quantidade <= 0) {
                      return 'Informe uma quantidade válida.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _selecionarData,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    _dataSelecionada == null
                        ? 'Selecionar data'
                        : '${_dataSelecionada!.day.toString().padLeft(2, '0')}/'
                            '${_dataSelecionada!.month.toString().padLeft(2, '0')}/'
                            '${_dataSelecionada!.year}',
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _selecionarHorario,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    _horarioSelecionado == null
                        ? 'Selecionar horário'
                        : _horarioSelecionado!.format(context),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  child: _salvando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Criar torneio',
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