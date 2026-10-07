import '../../features/auth/models/usuario_model.dart';

class UsuarioSession {
  static UsuarioModel? usuario;

  static bool get estaLogado => usuario != null;

  static bool get ehAdm => usuario?.tipo == 'adm';

  static bool get ehJogador => usuario?.tipo == 'jogador';

  static void iniciar(UsuarioModel usuarioLogado) {
    usuario = usuarioLogado;
  }

  static void limpar() {
    usuario = null;
  }
}