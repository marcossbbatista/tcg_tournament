class PartidaModel {
  final String id;
  final int mesa;

  final String jogador1Uid;
  final String jogador1Nome;

  final String? jogador2Uid;
  final String? jogador2Nome;

  final String status;

  final int placarJogador1;
  final int placarJogador2;

  final bool bye;

  PartidaModel({
    required this.id,
    required this.mesa,
    required this.jogador1Uid,
    required this.jogador1Nome,
    this.jogador2Uid,
    this.jogador2Nome,
    required this.status,
    required this.placarJogador1,
    required this.placarJogador2,
    required this.bye,
  });

  Map<String, dynamic> toMap() {
    return {
      'mesa': mesa,
      'jogador1Uid': jogador1Uid,
      'jogador1Nome': jogador1Nome,
      'jogador2Uid': jogador2Uid,
      'jogador2Nome': jogador2Nome,
      'status': status,
      'placarJogador1': placarJogador1,
      'placarJogador2': placarJogador2,
      'bye': bye,
    };
  }

  factory PartidaModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return PartidaModel(
      id: id,
      mesa: map['mesa'] ?? 0,
      jogador1Uid: map['jogador1Uid'] ?? '',
      jogador1Nome: map['jogador1Nome'] ?? '',
      jogador2Uid: map['jogador2Uid'],
      jogador2Nome: map['jogador2Nome'],
      status: map['status'] ?? 'aguardando',
      placarJogador1: map['placarJogador1'] ?? 0,
      placarJogador2: map['placarJogador2'] ?? 0,
      bye: map['bye'] ?? false,
    );
  }
}