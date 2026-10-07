import 'package:flutter/material.dart';

import '../../../core/session/usuario_session.dart';
import '../../auth/pages/login_page.dart';
import '../../auth/services/auth_service.dart';
import '../models/torneio_jogador_model.dart';
import '../pages/entrar_torneio_page.dart';
import '../services/jogador_torneio_service.dart';
import '../widgets/torneio_jogador_card.dart';
import '../pages/torneio_jogador_page.dart';

class HomeJogadorPage extends StatelessWidget {
  const HomeJogadorPage({
    super.key,
  });

  Future<void> _logout(
    BuildContext context,
  ) async {
    await AuthService().logout();

    UsuarioSession.limpar();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginPage(),
      ),
      (route) => false,
    );
  }

  Future<void> _entrarTorneio(
    BuildContext context,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const EntrarTorneioPage(),
      ),
    );
  }

  Future<void> _abrirTorneio(
  BuildContext context,
  TorneioJogadorModel item,
) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          TorneioJogadorPage(
        item: item,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final usuario =
        UsuarioSession.usuario;

    if (usuario == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Usuário não identificado.',
          ),
        ),
      );
    }

    final service =
        JogadorTorneioService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus torneios',
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () =>
                _logout(context),
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              'Olá, ${usuario.nome}',
              style:
                  Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),

            const Text(
              'Acompanhe seus torneios e partidas.',
            ),

            const SizedBox(height: 24),

            Expanded(
              child: StreamBuilder<
                  List<
                      TorneioJogadorModel>>(
                stream: service
                    .listarTorneiosDoJogador(
                  usuario.uid,
                ),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot
                          .connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Não foi possível carregar seus torneios.',
                      ),
                    );
                  }

                  final torneios =
                      snapshot.data ?? [];

                  if (torneios.isEmpty) {
                    return const Center(
                      child: Text(
                        'Você ainda não participa de nenhum torneio.',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount:
                        torneios.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final item =
                          torneios[index];

                      return TorneioJogadorCard(
                        item: item,
                        onAbrir: () =>
                            _abrirTorneio(
                          context,
                          item,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () =>
            _entrarTorneio(context),
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Entrar em torneio',
        ),
      ),
    );
  }
}