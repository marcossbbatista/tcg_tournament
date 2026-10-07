import 'package:cloud_firestore/cloud_firestore.dart';

class TorneioModel {
  final String id;
  final String nome;
  final String codigo;
  final DateTime dataHora;
  final String formato;
  final int quantidadeRodadas;
  final int rodadaAtual;
  final String status;
  final String criadoPor;
  final DateTime criadoEm;

  TorneioModel({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.dataHora,
    required this.formato,
    required this.quantidadeRodadas,
    required this.rodadaAtual,
    required this.status,
    required this.criadoPor,
    required this.criadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'codigo': codigo,
      'dataHora': Timestamp.fromDate(dataHora),
      'formato': formato,
      'quantidadeRodadas': quantidadeRodadas,
      'rodadaAtual': rodadaAtual,
      'status': status,
      'criadoPor': criadoPor,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  factory TorneioModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return TorneioModel(
      id: id,
      nome: map['nome'] ?? '',
      codigo: map['codigo'] ?? '',
      dataHora:
          (map['dataHora'] as Timestamp?)?.toDate() ?? DateTime.now(),
      formato: map['formato'] ?? 'md3',
      quantidadeRodadas: map['quantidadeRodadas'] ?? 0,
      rodadaAtual: map['rodadaAtual'] ?? 0,
      status: map['status'] ?? 'inscricoes',
      criadoPor: map['criadoPor'] ?? '',
      criadoEm:
          (map['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}