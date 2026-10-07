import 'package:flutter/material.dart';

import '../../auth/pages/login_page.dart';
import '../../auth/services/auth_service.dart';
import '../../torneio/models/torneio_model.dart';
import '../../torneio/pages/criar_torneio_page.dart';
import '../../torneio/services/torneio_service.dart';
import '../../torneio/widgets/torneio_card.dart';
import '../../../core/session/usuario_session.dart';
import '../../torneio/pages/gerenciar_torneio_page.dart';

class HomeAdmPage extends StatelessWidget {
  const HomeAdmPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();

    UsuarioSession.limpar();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  Future<void> _criarTorneio(
    BuildContext context,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CriarTorneioPage(),
      ),
    );
  }

Future<void> _gerenciarTorneio(
  BuildContext context,
  TorneioModel torneio,
) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GerenciarTorneioPage(
        torneio: torneio,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final usuario = UsuarioSession.usuario;

    if (usuario == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Usuário não identificado.',
          ),
        ),
      );
    }

    final TorneioService torneioService =
        TorneioService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus torneios',
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => _logout(context),
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
              'Gerencie seus torneios e acompanhe as partidas.',
            ),

            const SizedBox(height: 24),

            Expanded(
              child: StreamBuilder<List<TorneioModel>>(
                stream:
                    torneioService.listarTorneiosDoAdm(
                  usuario.uid,
                ),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Não foi possível carregar os torneios.',
                      ),
                    );
                  }

                  final torneios =
                      snapshot.data ?? [];

                  if (torneios.isEmpty) {
                    return const Center(
                      child: Text(
                        'Você ainda não possui torneios.',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: torneios.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final torneio =
                          torneios[index];

                      return TorneioCard(
                        torneio: torneio,
                        onGerenciar: () =>
                            _gerenciarTorneio(
                          context,
                          torneio,
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
            _criarTorneio(context),
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Criar torneio',
        ),
      ),
    );
  }
}