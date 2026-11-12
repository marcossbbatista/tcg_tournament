import 'package:cloud_firestore/cloud_firestore.dart';

import '../../torneio/rules/pokemon_rulebook.dart';

class UsuarioModel {
  final String uid;
  final String nome;
  final String email;
  final String tipo;
  final String primeiroNome;
  final String sobrenome;
  final String? pokemonPlayerId;
  final DateTime? dataNascimento;

  UsuarioModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.tipo,
    this.primeiroNome = '',
    this.sobrenome = '',
    this.pokemonPlayerId,
    this.dataNascimento,
  });

  /// Campos usados no bloco <player> do arquivo TOM / TDF.
  bool get possuiDadosOficiais =>
      primeiroNome.trim().isNotEmpty &&
      sobrenome.trim().isNotEmpty &&
      PokemonRulebook.validarIdentificador(pokemonPlayerId) == null &&
      dataNascimento != null &&
      !dataNascimento!.isAfter(DateTime.now());

  UsuarioModel copiarComDadosOficiais({
    required String primeiroNome,
    required String sobrenome,
    required String pokemonPlayerId,
    required DateTime dataNascimento,
  }) {
    final primeiro = primeiroNome.trim();
    final ultimo = sobrenome.trim();
    return UsuarioModel(
      uid: uid,
      nome: '$primeiro $ultimo',
      email: email,
      tipo: tipo,
      primeiroNome: primeiro,
      sobrenome: ultimo,
      pokemonPlayerId: pokemonPlayerId.trim(),
      dataNascimento: dataNascimento,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'tipo': tipo,
      'primeiroNome': primeiroNome,
      'sobrenome': sobrenome,
      'pokemonPlayerId': pokemonPlayerId,
      'dataNascimento': dataNascimento == null
          ? null
          : Timestamp.fromDate(dataNascimento!),
    };
  }

  factory UsuarioModel.fromMap(
    String uid,
    Map<String, dynamic> map,
  ) {
    final nome = (map['nome'] as String? ?? '').trim();
    final partesNome = nome.isEmpty ? <String>[] : nome.split(RegExp(r'\s+'));
    final nascimento = map['dataNascimento'];

    return UsuarioModel(
      uid: uid,
      nome: nome,
      email: map['email'] as String? ?? '',
      tipo: map['tipo'] as String? ?? 'jogador',
      // Compatibilidade com usuários anteriores à criação do perfil TOM.
      primeiroNome: map['primeiroNome'] as String? ??
          (partesNome.isEmpty ? '' : partesNome.first),
      sobrenome: map['sobrenome'] as String? ??
          (partesNome.length < 2 ? '' : partesNome.skip(1).join(' ')),
      pokemonPlayerId: map['pokemonPlayerId']?.toString(),
      dataNascimento: nascimento is Timestamp
          ? nascimento.toDate()
          : nascimento is DateTime
              ? nascimento
              : null,
    );
  }
}
