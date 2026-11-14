import 'package:tcg_tournament/core/responsive/responsive_body.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';

import '../../auth/pages/login_page.dart';
import '../../auth/pages/perfil_page.dart';
import '../../auth/services/auth_service.dart';
import '../../torneio/models/torneio_model.dart';
import '../../torneio/pages/criar_torneio_page.dart';
import '../../torneio/services/torneio_service.dart';
import '../../../core/session/usuario_session.dart';
import '../../torneio/pages/gerenciar_torneio_page.dart';
import '../../torneio/pages/tom_tdf_page.dart';

class HomeAdmPage extends StatefulWidget {
  const HomeAdmPage({super.key});

  @override
  State<HomeAdmPage> createState() => _HomeAdmPageState();
}

class _HomeAdmPageState extends State<HomeAdmPage> {
  final TorneioService _torneioService = TorneioService();

  Future<void> _abrirPerfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilPage()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await AuthService().logout();

    UsuarioSession.limpar();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _criarTorneio() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CriarTorneioPage()),
    );
  }

  Future<void> _gerenciarTorneio(TorneioModel torneio) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GerenciarTorneioPage(torneio: torneio),
      ),
    );
  }

  void _importarTdf() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TomTdfPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = UsuarioSession.usuario;

    if (usuario == null) {
      return TcgTheme.wrap(
        const Scaffold(
          body: Center(child: Text('Usuário não identificado.')),
        ),
      );
    }

    return TcgTheme.wrap(
      Scaffold(
        backgroundColor: TcgTheme.fundo,
        body: TcgBackground(
          child: SafeArea(
            bottom: false,
            child: ResponsiveBody(
              maxWidth: 1080,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TcgCurvedHeader(
                    saudacao: 'Olá, ${usuario.nome}',
                    titulo: 'Meus torneios',
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Image.asset(
                          'assets/images/pokeduelix_logo.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Meu perfil',
                        onPressed: _abrirPerfil,
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sair',
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ],
                  ),

                  // Importar .tdf
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TcgGlassCard(
                      onTap: _importarTdf,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.file_open_outlined,
                              color: TcgTheme.verde),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Importar torneio do TOM (.tdf)',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),

                  // Lista de torneios
                  Expanded(
                    child: StreamBuilder<List<TorneioModel>>(
                      stream: _torneioService.listarTorneiosDoAdm(usuario.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Não foi possível carregar os torneios.',
                            ),
                          );
                        }

                        final torneios = snapshot.data ?? [];

                        if (torneios.isEmpty) {
                          return const Center(
                            child: Text('Você ainda não possui torneios.'),
                          );
                        }

                        return ResponsiveTournamentGrid(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                          itemCount: torneios.length,
                          itemBuilder: (context, index) {
                            final torneio = torneios[index];

                            return TcgTournamentTile(
                              nome: torneio.nome,
                              data: torneio.dataHora,
                              formato: torneio.formato,
                              status: torneio.status,
                              buttonText: 'Gerenciar',
                              onTap: () => _gerenciarTorneio(torneio),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _criarTorneio,
          icon: const Icon(Icons.add),
          label: const Text('Criar torneio'),
        ),
      ),
    );
  }
}