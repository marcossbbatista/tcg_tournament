import '../../torneio/models/torneio_model.dart';

class TorneioJogadorModel {
  final TorneioModel torneio;
  final String status;
  final int pontos;
  final bool ativo;

  TorneioJogadorModel({
    required this.torneio,
    required this.status,
    required this.pontos,
    required this.ativo,
  });
}