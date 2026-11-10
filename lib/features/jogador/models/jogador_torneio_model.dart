import 'package:cloud_firestore/cloud_firestore.dart';
import '../../torneio/rules/pokemon_rulebook.dart';

class JogadorTorneioModel {
  final String uid;
  final String nome;
  final String email;
  final String status;
  final int pontos;
  final bool ativo;
  final DateTime entrouEm;
  final int quantidadeByes;
  final String? pokemonPlayerId;
  final String primeiroNome;
  final String sobrenome;
  final DateTime? dataNascimento;
  final String? divisaoEtaria;
  final String podId;
  final int? rodadaDesistencia;
  final int? rodadaEntradaTardia;

  JogadorTorneioModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.status,
    required this.pontos,
    required this.ativo,
    required this.entrouEm,
    this.quantidadeByes = 0,
    this.pokemonPlayerId,
    this.primeiroNome = '',
    this.sobrenome = '',
    this.dataNascimento,
    this.divisaoEtaria,
    this.podId = 'geral',
    this.rodadaDesistencia,
    this.rodadaEntradaTardia,
  });

  bool get possuiDadosOficiais =>
      PokemonRulebook.validarIdentificador(pokemonPlayerId) == null &&
      primeiroNome.trim().isNotEmpty && sobrenome.trim().isNotEmpty &&
      dataNascimento != null;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'nome': nome,
        'email': email,
        'status': status,
        'pontos': pontos,
        'ativo': ativo,
        'entrouEm': Timestamp.fromDate(entrouEm),
        'quantidadeByes': quantidadeByes,
        'pokemonPlayerId': pokemonPlayerId,
        'primeiroNome': primeiroNome,
        'sobrenome': sobrenome,
        'dataNascimento': dataNascimento == null ? null : Timestamp.fromDate(dataNascimento!),
        'divisaoEtaria': divisaoEtaria,
        'podId': podId,
        'rodadaDesistencia': rodadaDesistencia,
        'rodadaEntradaTardia': rodadaEntradaTardia,
      };

  factory JogadorTorneioModel.fromMap(String uid, Map<String, dynamic> map) =>
      JogadorTorneioModel(
        uid: uid,
        nome: map['nome'] as String? ?? '',
        email: map['email'] as String? ?? '',
        status: map['status'] as String? ?? 'pendente',
        pontos: (map['pontos'] as num?)?.toInt() ?? 0,
        ativo: map['ativo'] as bool? ?? true,
        entrouEm: (map['entrouEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
        quantidadeByes: (map['quantidadeByes'] as num?)?.toInt() ?? 0,
        pokemonPlayerId: map['pokemonPlayerId'] as String?,
        primeiroNome: map['primeiroNome'] as String? ?? '',
        sobrenome: map['sobrenome'] as String? ?? '',
        dataNascimento: (map['dataNascimento'] as Timestamp?)?.toDate(),
        divisaoEtaria: map['divisaoEtaria'] as String?,
        podId: map['podId'] as String? ?? 'geral',
        rodadaDesistencia: (map['rodadaDesistencia'] as num?)?.toInt(),
        rodadaEntradaTardia: (map['rodadaEntradaTardia'] as num?)?.toInt(),
      );
}
