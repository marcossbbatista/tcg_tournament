class UsuarioModel {
  final String uid;
  final String nome;
  final String email;
  final String tipo;

  UsuarioModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'tipo': tipo,
    };
  }

  factory UsuarioModel.fromMap(
    String uid,
    Map<String, dynamic> map,
  ) {
    return UsuarioModel(
      uid: uid,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      tipo: map['tipo'] ?? 'jogador',
    );
  }
}