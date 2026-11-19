import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tcg_tournament/core/session/usuario_session.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:tcg_tournament/features/auth/models/usuario_model.dart';
import 'package:tcg_tournament/features/auth/services/auth_service.dart';
import 'package:tcg_tournament/features/auth/services/usuario_service.dart';
import 'package:tcg_tournament/features/home/pages/home_adm_page.dart';
import 'package:tcg_tournament/features/home/pages/home_jogador_page.dart';

import 'login_page.dart';

/// Recupera a autenticação nativa do Firebase antes de exibir a primeira tela.
/// Login, cadastro e logout continuam utilizando as rotas já existentes.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final UsuarioService _usuarioService = UsuarioService();
  late Future<_ResultadoInicial> _inicializacao;

  @override
  void initState() {
    super.initState();
    _inicializacao = _recuperarSessao();
  }

  Future<_ResultadoInicial> _recuperarSessao() async {
    // O primeiro evento aguarda a restauração da sessão persistida pelo SDK.
    final User? firebaseUser = await FirebaseAuth.instance.authStateChanges().first;
    if (firebaseUser == null) {
      UsuarioSession.limpar();
      return const _ResultadoInicial.semLogin();
    }

    if (UsuarioSession.uid != null && UsuarioSession.uid != firebaseUser.uid) {
      UsuarioSession.limpar();
    }

    // Não cria perfis ou altera permissões durante a recuperação.
    final UsuarioModel? usuario =
        await _usuarioService.buscarUsuario(firebaseUser.uid);
    if (usuario == null) return const _ResultadoInicial.semPerfil();
    if (usuario.tipo != 'adm' && usuario.tipo != 'jogador') {
      return const _ResultadoInicial.tipoInvalido();
    }
    return _ResultadoInicial.autenticado(usuario);
  }

  void _tentarNovamente() {
    setState(() => _inicializacao = _recuperarSessao());
  }

  Future<void> _sair() async {
    try {
      await AuthService().logout();
      if (mounted) _tentarNovamente();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível sair. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ResultadoInicial>(
      future: _inicializacao,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _TelaInicial();
        }
        if (snapshot.hasError) {
          return _TelaInicial(
            mensagem: 'Não foi possível recuperar seu perfil. Verifique sua conexão e tente novamente.',
            tentarNovamente: _tentarNovamente,
            sair: _sair,
          );
        }
        final resultado = snapshot.data!;
        switch (resultado.estado) {
          case _EstadoInicial.semLogin:
            return const LoginPage();
          case _EstadoInicial.semPerfil:
            return _TelaInicial(
              mensagem: 'Sua conta está autenticada, mas o cadastro não foi encontrado. Entre em contato com o suporte.',
              tentarNovamente: _tentarNovamente,
              sair: _sair,
            );
          case _EstadoInicial.tipoInvalido:
            return _TelaInicial(
              mensagem: 'Seu perfil possui um tipo de acesso não reconhecido. Entre em contato com o suporte.',
              tentarNovamente: _tentarNovamente,
              sair: _sair,
            );
          case _EstadoInicial.autenticado:
            return resultado.usuario!.tipo == 'adm'
                ? const HomeAdmPage()
                : const HomeJogadorPage();
        }
      },
    );
  }
}

enum _EstadoInicial { semLogin, semPerfil, tipoInvalido, autenticado }

class _ResultadoInicial {
  final _EstadoInicial estado;
  final UsuarioModel? usuario;

  const _ResultadoInicial._(this.estado, [this.usuario]);
  const _ResultadoInicial.semLogin() : this._(_EstadoInicial.semLogin);
  const _ResultadoInicial.semPerfil() : this._(_EstadoInicial.semPerfil);
  const _ResultadoInicial.tipoInvalido() : this._(_EstadoInicial.tipoInvalido);
  _ResultadoInicial.autenticado(UsuarioModel usuario)
      : this._(_EstadoInicial.autenticado, usuario);
}

class _TelaInicial extends StatelessWidget {
  final String? mensagem;
  final VoidCallback? tentarNovamente;
  final VoidCallback? sair;

  const _TelaInicial({this.mensagem, this.tentarNovamente, this.sair});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TcgTheme.fundo,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/pokeduelix_logo.png', width: 84, height: 84),
                const SizedBox(height: 18),
                const Text('PokéDuelix', style: TextStyle(
                  color: TcgTheme.verde, fontSize: 28, fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 24),
                if (mensagem == null) ...[
                  const CircularProgressIndicator(color: TcgTheme.verde),
                  const SizedBox(height: 16),
                  const Text('Recuperando sua sessão...', style: TextStyle(color: TcgTheme.muted)),
                ] else ...[
                  Text(mensagem!, textAlign: TextAlign.center,
                    style: const TextStyle(color: TcgTheme.texto)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: tentarNovamente,
                    child: const Text('Tentar novamente')),
                  TextButton(onPressed: sair, child: const Text('Sair da conta')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
