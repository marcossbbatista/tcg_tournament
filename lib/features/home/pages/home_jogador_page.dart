import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../../../core/session/usuario_session.dart';

import '../../auth/pages/login_page.dart';

class HomeJogadorPage extends StatelessWidget {
  const HomeJogadorPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Área do Jogador'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Bem-vindo, jogador!',
          style: TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}