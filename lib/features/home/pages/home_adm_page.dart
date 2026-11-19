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

  // ============================================================
  // Ações
  // ============================================================

  Future<void> _abrirPerfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilPage()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _confirmarSair() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => Theme(
        data: TcgTheme.data(),
        child: AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Deseja realmente sair do aplicativo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sair'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) return;

    await _logout();
  }

  Future<void> _logout() async {
    await AuthService().logout();

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

  // ============================================================
  // Menu da conta
  // ============================================================

  String _iniciais(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();

    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  void _abrirMenuConta() {
  final usuario = UsuarioSession.usuario;
  if (usuario == null) return;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: TcgTheme.card,
    builder: (sheetContext) => Theme(
      data: TcgTheme.data(),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===== Identidade =====
              _AvatarConta(
                iniciais: _iniciais(usuario.nome),
                tamanho: 64,
              ),
              const SizedBox(height: 12),
              Text(
                usuario.nome,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                usuario.email,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: TcgTheme.muted),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x263DDC84),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 15,
                      color: TcgTheme.verde,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Organizador',
                      style: TextStyle(
                        color: TcgTheme.verde,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ===== Opções =====
              _OpcaoMenu(
                icone: Icons.account_circle_outlined,
                titulo: 'Meu perfil',
                subtitulo: 'Dados oficiais e Player ID',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _abrirPerfil();
                },
              ),
              const SizedBox(height: 10),
              _OpcaoMenu(
                icone: Icons.logout_rounded,
                titulo: 'Sair',
                subtitulo: 'Encerrar a sessão neste aparelho',
                perigo: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmarSair();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // ============================================================
  // Build
  // ============================================================

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
                        padding: const EdgeInsets.only(right: 12),
                        child: Image.asset(
                          'assets/images/pokeduelix_logo.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Tooltip(
                          message: 'Minha conta',
                          child: GestureDetector(
                            onTap: _abrirMenuConta,
                            child: _AvatarConta(
                              iniciais: _iniciais(usuario.nome),
                              tamanho: 40,
                              borda: true,
                            ),
                          ),
                        ),
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

// ============================================================
// Avatar da conta (iniciais)
// ============================================================

class _AvatarConta extends StatelessWidget {
  final String iniciais;
  final double tamanho;
  final bool borda;

  /// Quando existir foto de perfil, é só passar a URL aqui.
  final String? fotoUrl;

  const _AvatarConta({
    required this.iniciais,
    required this.tamanho,
    this.borda = false,
    this.fotoUrl,
  });

  Widget _texto() {
    return Text(
      iniciais,
      style: TextStyle(
        color: Colors.white,
        fontSize: tamanho * 0.36,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoUrl != null && fotoUrl!.isNotEmpty;

    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: TcgTheme.gradient,
        border: borda
            ? Border.all(color: const Color(0x99FFFFFF), width: 1.5)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x553DDC84),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: temFoto
          ? ClipOval(
              child: Image.network(
                fotoUrl!,
                width: tamanho,
                height: tamanho,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _texto(),
              ),
            )
          : _texto(),
    );
  }
}

// ============================================================
// Opção do menu
// ============================================================

class _OpcaoMenu extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final bool perigo;

  const _OpcaoMenu({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.perigo = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = perigo ? const Color(0xFFFF6B6B) : TcgTheme.verde;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: perigo ? const Color(0x14FF6B6B) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: perigo ? const Color(0x33FF6B6B) : const Color(0x26FFFFFF),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: cor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      color: perigo ? cor : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: TcgTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}