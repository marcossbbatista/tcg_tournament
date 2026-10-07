import 'package:cloud_firestore/cloud_firestore.dart';

class RodadaModel {
  final String id;
  final int numero;
  final String status;
  final DateTime criadaEm;

  RodadaModel({
    required this.id,
    required this.numero,
    required this.status,
    required this.criadaEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'status': status,
      'criadaEm': Timestamp.fromDate(criadaEm),
    };
  }

  factory RodadaModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return RodadaModel(
      id: id,
      numero: map['numero'] ?? 0,
      status: map['status'] ?? 'configuracao',
      criadaEm:
          (map['criadaEm'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }
}