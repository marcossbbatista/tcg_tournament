/// Resultado normalizado. Os códigos numéricos do TOM serão definidos somente
/// após conferir um TDF real exportado pela versão instalada do software.
enum ResultadoPartida {
  pendente,
  vitoriaJogador1,
  vitoriaJogador2,
  empate,
  bye,
  woJogador1,
  woJogador2,
  derrotaDupla,
  derrotaAutomatica,
}

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
  final String? resultadoInformadoPor;
  final bool bye;
  final ResultadoPartida resultado;
  final String fase;
  final String podId;

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
    this.resultadoInformadoPor,
    required this.bye,
    ResultadoPartida? resultado,
    this.fase = 'swiss',
    this.podId = 'geral',
  }) : resultado = resultado ??
            (bye ? ResultadoPartida.bye : _inferir(status, placarJogador1, placarJogador2));

  static ResultadoPartida _inferir(String status, int placar1, int placar2) {
    if (status != 'finalizada' && status != 'aguardando_confirmacao') {
      return ResultadoPartida.pendente;
    }
    if (placar1 > placar2) return ResultadoPartida.vitoriaJogador1;
    if (placar2 > placar1) return ResultadoPartida.vitoriaJogador2;
    return ResultadoPartida.empate;
  }

  bool get resultadoConcluido => resultado != ResultadoPartida.pendente;

  Map<String, dynamic> toMap() => {
        'mesa': mesa,
        'jogador1Uid': jogador1Uid,
        'jogador1Nome': jogador1Nome,
        'jogador2Uid': jogador2Uid,
        'jogador2Nome': jogador2Nome,
        'status': status,
        'placarJogador1': placarJogador1,
        'placarJogador2': placarJogador2,
        'resultadoInformadoPor': resultadoInformadoPor,
        'bye': bye,
        'resultado': resultado.name,
        'fase': fase,
        'podId': podId,
      };

  factory PartidaModel.fromMap(String id, Map<String, dynamic> map) {
    ResultadoPartida? resultado;
    final valor = map['resultado'] as String?;
    if (valor != null) {
      for (final opcao in ResultadoPartida.values) {
        if (opcao.name == valor) {
          resultado = opcao;
          break;
        }
      }
    }
    return PartidaModel(
      id: id,
      mesa: (map['mesa'] as num?)?.toInt() ?? 0,
      jogador1Uid: map['jogador1Uid'] as String? ?? '',
      jogador1Nome: map['jogador1Nome'] as String? ?? '',
      jogador2Uid: map['jogador2Uid'] as String?,
      jogador2Nome: map['jogador2Nome'] as String?,
      status: map['status'] as String? ?? 'em_andamento',
      placarJogador1: (map['placarJogador1'] as num?)?.toInt() ?? 0,
      placarJogador2: (map['placarJogador2'] as num?)?.toInt() ?? 0,
      resultadoInformadoPor: map['resultadoInformadoPor'] as String?,
      bye: map['bye'] as bool? ?? false,
      resultado: resultado,
      fase: map['fase'] as String? ?? 'swiss',
      podId: map['podId'] as String? ?? 'geral',
    );
  }
}
