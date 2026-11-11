import '../../jogador/models/jogador_torneio_model.dart';
import '../../partida/models/partida_model.dart';
import '../models/classificacao_jogador_model.dart';
import 'pokemon_rulebook.dart';

/// Calcula a classificação a partir de partidas finalizadas, nunca do saldo
/// persistido em `players.pontos` (evita duplicação após reprocessamento).
class ClassificacaoEngine {
  const ClassificacaoEngine();

  List<ClassificacaoJogadorModel> calcular({
    required List<JogadorTorneioModel> jogadores,
    required List<PartidaModel> partidas,
    required String torneioId,
  }) {
    final dados = <String, _Stats>{
      for (final j in jogadores.where((j) => j.status == 'aprovado'))
        j.uid: _Stats(j),
    };
    final confrontos = <String, Map<String, int>>{};

    for (final partida in partidas) {
      if (partida.status != 'finalizada' || partida.fase != 'swiss') continue;
      final a = dados[partida.jogador1Uid];
      if (a == null) continue;
      final resultado = partida.resultado;
      if (partida.bye || resultado == ResultadoPartida.bye) {
        a.pontos += 3;
        a.vitorias++;
        a.byes++;
        continue;
      }
      if (resultado == ResultadoPartida.derrotaAutomatica) {
        a.derrotas++;
        continue;
      }
      final uid2 = partida.jogador2Uid;
      if (uid2 == null) continue;
      final b = dados[uid2];
      if (b == null) continue;

      // Byes, W.O. e derrotas duplas não criam adversários artificiais
      // para o cálculo de OMW/OOMW. Validar regra de W.O. com o TOM real.
      final confrontoRegular = resultado == ResultadoPartida.vitoriaJogador1 ||
          resultado == ResultadoPartida.vitoriaJogador2 ||
          resultado == ResultadoPartida.empate;
      if (confrontoRegular) {
        a.oponentes.add(b.jogador.uid);
        b.oponentes.add(a.jogador.uid);
        a.rodadasConsideradas++;
        b.rodadasConsideradas++;
      }
      switch (resultado) {
        case ResultadoPartida.vitoriaJogador1:
          a.vitorias++;
          a.vitoriasDesempate++;
          a.pontos += 3;
          b.derrotas++;
          confrontos.putIfAbsent(a.jogador.uid, () => {})[b.jogador.uid] = 1;
          confrontos.putIfAbsent(b.jogador.uid, () => {})[a.jogador.uid] = -1;
          break;
        case ResultadoPartida.vitoriaJogador2:
          b.vitorias++;
          b.vitoriasDesempate++;
          b.pontos += 3;
          a.derrotas++;
          confrontos.putIfAbsent(a.jogador.uid, () => {})[b.jogador.uid] = -1;
          confrontos.putIfAbsent(b.jogador.uid, () => {})[a.jogador.uid] = 1;
          break;
        case ResultadoPartida.empate:
          a.empates++;
          b.empates++;
          a.pontos++;
          b.pontos++;
          confrontos.putIfAbsent(a.jogador.uid, () => {})[b.jogador.uid] = 0;
          confrontos.putIfAbsent(b.jogador.uid, () => {})[a.jogador.uid] = 0;
          break;
        case ResultadoPartida.woJogador1:
          a.derrotas++;
          b.vitorias++;
          b.pontos += 3;
          break;
        case ResultadoPartida.woJogador2:
          b.derrotas++;
          a.vitorias++;
          a.pontos += 3;
          break;
        case ResultadoPartida.derrotaDupla:
          a.derrotas++;
          b.derrotas++;
          break;
        case ResultadoPartida.derrotaAutomatica:
          a.derrotas++;
          break;
        case ResultadoPartida.pendente:
        case ResultadoPartida.bye:
          break;
      }
    }

    // Média da porcentagem de vitórias dos oponentes, piso 25%.
    // O numerador exclui byes, mas pontos de bye permanecem no ranking.
    for (final s in dados.values) {
      final denominador = s.rodadasConsideradas;
      final bruto = denominador == 0 ? 0.0 : s.vitoriasDesempate / denominador;
      final maximo = s.jogador.ativo ? 1.0 : PokemonRulebook.tetoDropWinPercentage;
      s.wp = bruto.clamp(PokemonRulebook.pisoWinPercentage, maximo).toDouble();
    }
    for (final s in dados.values) {
      s.omw = _media(s.oponentes.map((id) => dados[id]?.wp));
    }
    for (final s in dados.values) {
      s.oomw = _media(s.oponentes.map((id) => dados[id]?.omw));
    }

    final resultado = dados.values.map((s) => ClassificacaoJogadorModel(
          uid: s.jogador.uid,
          nome: s.jogador.nome,
          pontos: s.pontos,
          vitorias: s.vitorias,
          derrotas: s.derrotas,
          empates: s.empates,
          winPercentage: s.wp,
          opponentWinPercentage: s.omw,
          opponentOpponentWinPercentage: s.oomw,
          ativo: s.jogador.ativo,
          quantidadeByes: s.byes,
          divisaoEtaria: s.jogador.divisaoEtaria ?? 'nao_informada',
          podId: s.jogador.podId,
          entradaTardia: s.jogador.rodadaEntradaTardia != null,
        )).toList();

    resultado.sort((a, b) {
      final pontos = b.pontos.compareTo(a.pontos);
      if (pontos != 0) return pontos;
      // O critério de pontualidade precede OMW e OOMW.
      if (a.entradaTardia != b.entradaTardia) return a.entradaTardia ? 1 : -1;
      final omw = b.opponentWinPercentage.compareTo(a.opponentWinPercentage);
      if (omw != 0) return omw;
      final oomw = b.opponentOpponentWinPercentage.compareTo(a.opponentOpponentWinPercentage);
      if (oomw != 0) return oomw;
      return 0;
    });

    // Confronto direto só se *exatamente dois* empatarem em todos os critérios.
    var inicio = 0;
    while (inicio < resultado.length) {
      var fim = inicio + 1;
      while (fim < resultado.length && _mesmoEmpate(resultado[inicio], resultado[fim])) {
        fim++;
      }
      if (fim - inicio == 2) {
        final a = resultado[inicio];
        final b = resultado[inicio + 1];
        final confronto = confrontos[a.uid]?[b.uid];
        if (confronto == -1) {
          resultado[inicio] = b;
          resultado[inicio + 1] = a;
        } else if (confronto == null || confronto == 0) {
          _ordemEstavel(resultado, inicio, fim, torneioId);
        }
      } else if (fim - inicio > 1) {
        _ordemEstavel(resultado, inicio, fim, torneioId);
      }
      inicio = fim;
    }
    return resultado;
  }

  bool _mesmoEmpate(ClassificacaoJogadorModel a, ClassificacaoJogadorModel b) =>
      a.pontos == b.pontos && a.entradaTardia == b.entradaTardia &&
      (a.opponentWinPercentage - b.opponentWinPercentage).abs() < 1e-9 &&
      (a.opponentOpponentWinPercentage - b.opponentOpponentWinPercentage).abs() < 1e-9;

  void _ordemEstavel(List<ClassificacaoJogadorModel> dados, int inicio, int fim, String id) {
    final grupo = dados.sublist(inicio, fim);
    // Desempate pseudoaleatório reproduzível; não é sorteio auditável do TOM.
    grupo.sort((a,b) => _hash('$id:${a.uid}').compareTo(_hash('$id:${b.uid}')));
    dados.setRange(inicio, fim, grupo);
  }

  int _hash(String value) {
    var code = 17;
    for (final unit in value.codeUnits) {
      code = (31 * code + unit) & 0x7fffffff;
    }
    return code;
  }

  double _media(Iterable<double?> valores) {
    var soma = 0.0;
    var quantidade = 0;
    for (final valor in valores) {
      if (valor == null) continue;
      soma += valor;
      quantidade++;
    }
    return quantidade == 0 ? 0.0 : soma / quantidade;
  }
}

class _Stats {
  final JogadorTorneioModel jogador;
  _Stats(this.jogador) {
    final rodada = jogador.rodadaEntradaTardia;
    if (rodada != null && rodada > 1) derrotas = rodada - 1;
  }
  int pontos = 0;
  int vitorias = 0;
  int vitoriasDesempate = 0;
  int derrotas = 0;
  int empates = 0;
  int byes = 0;
  int rodadasConsideradas = 0;
  final List<String> oponentes = [];
  double wp = 0;
  double omw = 0;
  double oomw = 0;
}
