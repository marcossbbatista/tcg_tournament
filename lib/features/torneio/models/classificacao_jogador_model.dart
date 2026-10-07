class ClassificacaoJogadorModel {
  final String uid;
  final String nome;

  final int pontos;

  final int vitorias;
  final int derrotas;
  final int empates;

  final double winPercentage;
  final double opponentWinPercentage;
  final double opponentOpponentWinPercentage;

  final bool ativo;
  final int quantidadeByes;

  ClassificacaoJogadorModel({
    required this.uid,
    required this.nome,
    required this.pontos,
    required this.vitorias,
    required this.derrotas,
    required this.empates,
    required this.winPercentage,
    required this.opponentWinPercentage,
    required this.opponentOpponentWinPercentage,
    required this.ativo,
    required this.quantidadeByes,
  });

  int get partidas =>
      vitorias +
      derrotas +
      empates;

  String get retrospecto =>
      '$vitorias-$derrotas-$empates';
}