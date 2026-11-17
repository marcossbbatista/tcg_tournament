
import '../../features/auth/models/usuario_model.dart';

class UsuarioSession {
  static UsuarioModel? _usuario;

  static UsuarioModel? get usuario => _usuario;

  static bool get estaLogado => _usuario != null;

  static bool get ehAdm => _usuario?.tipo == 'adm';

  static bool get ehJogador => _usuario?.tipo == 'jogador';

  static String? get uid => _usuario?.uid;

  static void iniciar(UsuarioModel usuarioLogado) {
    _usuario = usuarioLogado;
  }

  static void atualizar(UsuarioModel usuarioAtualizado) {
    _usuario = usuarioAtualizado;
  }

  static void limpar() {
    _usuario = null;
  }
}
