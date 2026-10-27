import 'package:tcg_tournament/core/theme/tcg_theme.dart';

import 'package:flutter/material.dart';
import 'package:tcg_tournament/features/jogador/models/torneio_jogador_model.dart';
import 'package:tcg_tournament/features/jogador/pages/entrar_torneio_page.dart';
import 'package:tcg_tournament/features/jogador/pages/torneio_jogador_page.dart';
import 'package:tcg_tournament/features/jogador/service/jogador_torneio_service.dart';

import '../../../core/session/usuario_session.dart';
import '../../auth/pages/login_page.dart';
import '../../auth/services/auth_service.dart';

class HomeJogadorPage extends StatefulWidget {
  const HomeJogadorPage({super.key});

  @override
  State<HomeJogadorPage> createState() => _HomeJogadorPageState();
}

class _HomeJogadorPageState extends State<HomeJogadorPage> {
  final JogadorTorneioService _service = JogadorTorneioService();

  Stream<List<TorneioJogadorModel>>? _torneiosStream;

  @override
  void initState() {
    super.initState();
    _carregarTorneios();
  }

  void _carregarTorneios() {
    final usuario = UsuarioSession.usuario;

    if (usuario == null) return;

    _torneiosStream = _service.listarTorneiosDoJogador(
      usuario.uid,
    );
  }

  void _atualizarTorneios() {
    setState(() {
      _carregarTorneios();
    });
  }

  Future<void> _logout() async {
    await AuthService().logout();

    UsuarioSession.limpar();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  Future<void> _entrarTorneio() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EntrarTorneioPage(),
      ),
    );

    if (!mounted) return;

    _atualizarTorneios();
  }

  Future<void> _abrirTorneio(
    TorneioJogadorModel item,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TorneioJogadorPage(item: item),
      ),
    );

    if (!mounted) return;

    _atualizarTorneios();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = UsuarioSession.usuario;

    if (usuario == null) {
      return TcgTheme.wrap(const Scaffold(
        body: Center(
          child: Text('Usuário não identificado.'),
        ),
      ));
    }

    return TcgTheme.wrap(Scaffold(
      appBar: AppBar(
        title: const Text('Meus torneios'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _atualizarTorneios,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TcgHero(title: 'Olá, ${usuario.nome}', subtitle: 'Acompanhe seus torneios e partidas.', icon: Icons.style_rounded),
            const SizedBox(height: 4),
            Expanded(
              child: StreamBuilder<List<TorneioJogadorModel>>(
                stream: _torneiosStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint(
                      'Erro ao carregar torneios: ${snapshot.error}',
                    );

                    debugPrint(
                      'StackTrace: ${snapshot.stackTrace}',
                    );

                    return Center(
                      child: Text(
                        'Erro ao carregar torneios:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final torneios = snapshot.data ?? [];

                  debugPrint(
                    'Quantidade de torneios: ${torneios.length}',
                  );

                  if (torneios.isEmpty) {
                    return const Center(
                      child: Text(
                        'Você ainda não participa de nenhum torneio.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: torneios.length,
                    itemBuilder: (context, index) {
                      final item = torneios[index];

                      return TcgTournamentTile(
                        nome: item.torneio.nome,
                        data: item.torneio.dataHora,
                        formato: item.torneio.formato,
                        status: item.status,
                        pontos: item.pontos,
                        onTap: () => _abrirTorneio(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _entrarTorneio,
        icon: const Icon(Icons.add),
        label: const Text('Entrar em torneio'),
      ),
    ));
  }
}
