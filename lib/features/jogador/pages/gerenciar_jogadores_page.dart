import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';
import 'package:tcg_tournament/features/jogador/service/jogador_torneio_service.dart';

import '../models/jogador_torneio_model.dart';
import 'dados_jogador_dialog.dart';

class GerenciarJogadoresPage extends StatelessWidget {
  final String torneioId;
  final String nomeTorneio;

  const GerenciarJogadoresPage({
    super.key,
    required this.torneioId,
    required this.nomeTorneio,
  });

  Future<void> _aprovar(
    BuildContext context,
    JogadorTorneioModel jogador,
  ) async {
    try {
      await JogadorTorneioService().aprovarJogador(
        torneioId: torneioId,
        jogadorUid: jogador.uid,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${jogador.nome} foi aprovado.')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível aprovar o jogador.')),
      );
    }
  }

  Future<void> _recusar(
    BuildContext context,
    JogadorTorneioModel jogador,
  ) async {
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

    if (confirmar != true) {
      return;
    }

    try {
      await JogadorTorneioService().recusarJogador(
        torneioId: torneioId,
        jogadorUid: jogador.uid,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${jogador.nome} foi recusado.')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível recusar o jogador.')),
      );
    }
  }

  Future<void> _editarOficiais(BuildContext context, JogadorTorneioModel jogador) async {
    final dados = await showDialog<DadosJogadorPreenchidos>(
      context: context, builder: (_) => DadosJogadorDialog(jogador: jogador));
    if (dados == null || !context.mounted) return;
    try {
      await JogadorTorneioService().atualizarDadosOficiais(
        torneioId: torneioId, jogadorUid: jogador.uid,
        primeiroNome: dados.primeiroNome, sobrenome: dados.sobrenome,
        pokemonPlayerId: dados.playerId, dataNascimento: dados.nascimento,
      );
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados oficiais atualizados.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar: $e')));
    }
  }

  Future<void> _cadastrarPresencial(BuildContext context) async {
    final dados = await showDialog<DadosJogadorPreenchidos>(
      context: context, builder: (_) => const DadosJogadorDialog());
    if (dados == null || !context.mounted) return;
    try {
      await JogadorTorneioService().cadastrarJogadorPresencial(
        torneioId: torneioId, primeiroNome: dados.primeiroNome,
        sobrenome: dados.sobrenome, pokemonPlayerId: dados.playerId,
        dataNascimento: dados.nascimento,
      );
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jogador inscrito.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível cadastrar: $e')));
    }
  }

  Future<void> _desistir(BuildContext context, JogadorTorneioModel jogador) async {
    final confirma = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Registrar desistência'),
      content: Text('Marcar ${jogador.nome} como desistente após a rodada atual?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
      ],
    ));
    if (confirma != true || !context.mounted) return;
    try {
      await JogadorTorneioService().registrarDesistencia(
          torneioId: torneioId, jogadorUid: jogador.uid);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desistência registrada.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível registrar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final JogadorTorneioService service = JogadorTorneioService();

    return TcgTheme.wrap(Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar jogadores'),
        actions: [IconButton(
          tooltip: 'Inscrição presencial', icon: const Icon(Icons.person_add_alt_1),
          onPressed: () => _cadastrarPresencial(context),
        )],
      ),
      body: StreamBuilder<List<JogadorTorneioModel>>(
        stream: service.listarJogadores(torneioId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Não foi possível carregar os jogadores.'),
            );
          }

          final jogadores = snapshot.data ?? [];

          final pendentes = jogadores
              .where((jogador) => jogador.status == 'pendente')
              .toList();

          final aprovados = jogadores
              .where((jogador) => jogador.status == 'aprovado')
              .toList();

          final recusados = jogadores
              .where((jogador) => jogador.status == 'recusado')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(nomeTorneio, style: Theme.of(context).textTheme.titleLarge),

              const SizedBox(height: 24),

              _TituloSecao(titulo: 'Pendentes', quantidade: pendentes.length),

              const SizedBox(height: 8),

              if (pendentes.isEmpty)
                const _ListaVazia(
                  mensagem: 'Nenhum jogador aguardando aprovação.',
                )
              else
                ...pendentes.map(
                  (jogador) => _JogadorCard(
                    jogador: jogador,
                    mostrarAcoes: true,
                    onAprovar: () => _aprovar(context, jogador),
                    onRecusar: () => _recusar(context, jogador),
                  ),
                ),

              const SizedBox(height: 24),

              _TituloSecao(titulo: 'Aprovados', quantidade: aprovados.length),

              const SizedBox(height: 8),

              if (aprovados.isEmpty)
                const _ListaVazia(mensagem: 'Nenhum jogador aprovado.')
              else
                ...aprovados.map((jogador) => _JogadorCard(
                  jogador: jogador,
                  // Contas registradas editam estes campos em Meu perfil.
                  // Inscritos presenciais não possuem conta: mantêm edição aqui.
                  onEditar: jogador.uid.startsWith('pop_')
                      ? () => _editarOficiais(context, jogador) : null,
                  onDesistir: jogador.ativo ? () => _desistir(context, jogador) : null,
                )),

              if (recusados.isNotEmpty) ...[
                const SizedBox(height: 24),

                _TituloSecao(titulo: 'Recusados', quantidade: recusados.length),

                const SizedBox(height: 8),

                ...recusados.map((jogador) => _JogadorCard(jogador: jogador)),
              ],
            ],
          );
        },
      ),
    ));
  }
}

class _TituloSecao extends StatelessWidget {
  final String titulo;
  final int quantidade;

  const _TituloSecao({required this.titulo, required this.quantidade});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(width: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(quantidade.toString()),
        ),
      ],
    );
  }
}

class _JogadorCard extends StatelessWidget {
  final JogadorTorneioModel jogador;
  final bool mostrarAcoes;

  final VoidCallback? onAprovar;
  final VoidCallback? onRecusar;
  final VoidCallback? onEditar;
  final VoidCallback? onDesistir;

  const _JogadorCard({
    required this.jogador,
    this.mostrarAcoes = false,
    this.onAprovar,
    this.onRecusar,
    this.onEditar,
    this.onDesistir,
  });

  String _statusFormatado() {
    switch (jogador.status) {
      case 'aprovado':
        return 'Aprovado';

      case 'recusado':
        return 'Recusado';

      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    jogador.nome.isNotEmpty
                        ? jogador.nome[0].toUpperCase()
                        : '?',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jogador.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 2),

                      Text(jogador.email),
                    ],
                  ),
                ),
              ],
            ),

            if (!mostrarAcoes) ...[
              const SizedBox(height: 12),

              Text(
                _statusFormatado(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],

            if (jogador.pokemonPlayerId != null) ...[
              const SizedBox(height: 6),
              Text('Player ID: ${jogador.pokemonPlayerId} • ${jogador.divisaoEtaria ?? 'sem divisão'}'),
            ],
            if (!jogador.ativo) const Text('Desistente'),
            if (onEditar != null || onDesistir != null) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                if (onEditar != null)
                  OutlinedButton.icon(onPressed: onEditar,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Dados oficiais')),
                if (onDesistir != null)
                  OutlinedButton.icon(onPressed: onDesistir,
                      icon: const Icon(Icons.person_remove_outlined),
                      label: const Text('Desistência')),
              ]),
            ],
            if (mostrarAcoes) ...[
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRecusar,
                      child: const Text('Recusar'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAprovar,
                      child: const Text('Aprovar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  final String mensagem;

  const _ListaVazia({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(mensagem, textAlign: TextAlign.center),
      ),
    );
  }
}
