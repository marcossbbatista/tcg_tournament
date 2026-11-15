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

  // ============================================================
  // Ações
  // ============================================================

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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PerfilPage(),
      ),
    );
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

    final incompleto = !usuario.possuiDadosOficiais;

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
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _Etiqueta(
                      icone: Icons.style_rounded,
                      texto: 'Jogador',
                      cor: TcgTheme.verde,
                    ),
                    if (incompleto)
                      const _Etiqueta(
                        icone: Icons.info_outline,
                        texto: 'Perfil incompleto',
                        cor: Color(0xFFFFB74D),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // ===== Opções =====
                _OpcaoMenu(
                  icone: Icons.account_circle_outlined,
                  titulo: 'Meu perfil',
                  subtitulo: incompleto
                      ? 'Complete seus dados para jogar'
                      : 'Dados oficiais e Player ID',
                  alerta: incompleto,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _abrirPerfil();
                  },
                ),
                const SizedBox(height: 10),
                _OpcaoMenu(
                  icone: Icons.refresh_rounded,
                  titulo: 'Atualizar',
                  subtitulo: 'Recarregar a lista de torneios',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _atualizarTorneios();
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
                              alerta: !usuario.possuiDadosOficiais,
                            ),
                          ),
                        ),
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

// ============================================================
// Avatar da conta (iniciais)
// ============================================================

class _AvatarConta extends StatelessWidget {
  final String iniciais;
  final double tamanho;
  final bool borda;

  /// Mostra um ponto amarelo (perfil incompleto).
  final bool alerta;

  /// Quando existir foto de perfil, é só passar a URL aqui.
  final String? fotoUrl;

  const _AvatarConta({
    required this.iniciais,
    required this.tamanho,
    this.borda = false,
    this.alerta = false,
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

    final avatar = Container(
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

    if (!alerta) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -1,
          top: -1,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFB74D),
              border: Border.all(color: TcgTheme.fundo, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Etiqueta
// ============================================================

class _Etiqueta extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Color cor;

  const _Etiqueta({
    required this.icone,
    required this.texto,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 15, color: cor),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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

  /// Destaca a opção em amarelo (precisa de atenção).
  final bool alerta;

  const _OpcaoMenu({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.perigo = false,
    this.alerta = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = perigo
        ? const Color(0xFFFF6B6B)
        : (alerta ? const Color(0xFFFFB74D) : TcgTheme.verde);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: perigo
              ? const Color(0x14FF6B6B)
              : (alerta ? const Color(0x14FFB74D) : const Color(0x14FFFFFF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: perigo
                ? const Color(0x33FF6B6B)
                : (alerta
                    ? const Color(0x55FFB74D)
                    : const Color(0x26FFFFFF)),
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
                    style: TextStyle(
                      color: alerta ? cor : TcgTheme.muted,
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