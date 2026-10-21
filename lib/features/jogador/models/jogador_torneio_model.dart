import 'package:cloud_firestore/cloud_firestore.dart';

class JogadorTorneioModel {
  final String uid;
  final String nome;
  final String email;
  final String status;
  final int pontos;
  final bool ativo;
  final DateTime entrouEm;
  final int quantidadeByes;

  JogadorTorneioModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.status,
    required this.pontos,
    required this.ativo,
    required this.entrouEm,
    this.quantidadeByes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'status': status,
      'pontos': pontos,
      'ativo': ativo,
      'entrouEm': Timestamp.fromDate(entrouEm),
      'quantidadeByes': quantidadeByes,
    };
  }

  factory JogadorTorneioModel.fromMap(
    String uid,
    Map<String, dynamic> map,
  ) {
    return JogadorTorneioModel(
      uid: uid,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      status: map['status'] ?? 'pendente',
      pontos: map['pontos'] ?? 0,
      ativo: map['ativo'] ?? true,
      entrouEm:
          (map['entrouEm'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      quantidadeByes: map['quantidadeByes'] ?? 0,
    );
  }
}