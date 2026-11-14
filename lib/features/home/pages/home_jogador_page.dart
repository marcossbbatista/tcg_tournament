import 'package:tcg_tournament/core/responsive/responsive_body.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';

import 'package:flutter/material.dart';
import 'package:tcg_tournament/features/jogador/models/torneio_jogador_model.dart';
import 'package:tcg_tournament/features/jogador/pages/entrar_torneio_page.dart';
import 'package:tcg_tournament/features/jogador/pages/torneio_jogador_page.dart';
import 'package:tcg_tournament/features/jogador/service/jogador_torneio_service.dart';

import '../../../core/session/usuario_session.dart';
import '../../auth/pages/login_page.dart';
import '../../auth/pages/perfil_page.dart';
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

  Future<void> _abrirPerfil() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => const PerfilPage(),
    ));
    if (mounted) setState(() {});
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
        body: Center(child: Text('Usuário não identificado.')),
      ));
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
                        icon: const Icon(Icons.account_circle_outlined,
                            color: Colors.white),
                      ),
                      IconButton(
                        tooltip: 'Atualizar',
                        onPressed: _atualizarTorneios,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                      IconButton(
                        tooltip: 'Sair',
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ],
                  ),
                  if (!usuario.possuiDadosOficiais)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TcgGlassCard(
                        onTap: _abrirPerfil,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        child: const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.info_outline),
                          title: Text('Complete seu perfil para jogar'),
                          subtitle: Text(
                              'Informe seu Pokémon Player ID e nascimento.'),
                          trailing: Icon(Icons.chevron_right),
                        ),
                      ),
                    ),
                  Expanded(
                    child: StreamBuilder<List<TorneioJogadorModel>>(
                      stream: _torneiosStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
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
                              child: CircularProgressIndicator());
                        }

                        final torneios = snapshot.data ?? [];

                        if (torneios.isEmpty) {
                          return const Center(
                            child: Text(
                              'Você ainda não participa de nenhum torneio.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ResponsiveTournamentGrid(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
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
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _entrarTorneio,
          icon: const Icon(Icons.add),
          label: const Text('Entrar em torneio'),
        ),
      ),
    );
  }
}
