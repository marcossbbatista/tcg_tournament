import 'dart:math';
import '../models/classificacao_jogador_model.dart';

class ConfrontoSwiss {
  final String jogador1Uid;
  final String? jogador2Uid;
  final String podId;
  const ConfrontoSwiss(this.jogador1Uid, this.jogador2Uid, this.podId);
  bool get bye => jogador2Uid == null;
}

/// Swiss com busca retroativa. Nunca cria um rematch silencioso.
/// Em cenários sem solução, solicita intervenção do organizador.
class PareamentoSwissEngine {
  const PareamentoSwissEngine();

  List<ConfrontoSwiss> gerar({
    required List<ClassificacaoJogadorModel> classificacao,
    required Map<String, Set<String>> historico,
    required int rodada,
    required String torneioId,
    bool separarDivisoes = false,
  }) {
    final grupos = <String, List<ClassificacaoJogadorModel>>{};
    for (final j in classificacao.where((j) => j.ativo)) {
      final pod = j.podId != 'geral' ? j.podId :
          (separarDivisoes ? j.divisaoEtaria : 'geral');
      grupos.putIfAbsent(pod, () => []).add(j);
    }
    final retorno = <ConfrontoSwiss>[];
    final random = Random(_seed(torneioId, rodada));
    for (final item in grupos.entries) {
      final jogadores = [...item.value];
      if (rodada == 1) jogadores.shuffle(random);
      if (jogadores.length == 1) {
        // Um grupo unitário recebe bye; um evento oficial deve ser validado.
        retorno.add(ConfrontoSwiss(jogadores.first.uid, null, item.key));
        continue;
      }
      if (jogadores.length.isOdd) {
        // Prioriza jogadores pior colocados que ainda não receberam bye.
        final candidatos = jogadores.reversed.toList()
          ..sort((a, b) {
            final byes = a.quantidadeByes.compareTo(b.quantidadeByes);
            return byes != 0 ? byes : a.pontos.compareTo(b.pontos);
          });
        List<ConfrontoSwiss>? encontrado;
        for (final bye in candidatos) {
          final restantes = jogadores.where((j) => j.uid != bye.uid).toList();
          final pares = _parear(restantes, historico, item.key);
          if (pares != null) {
            encontrado = [...pares, ConfrontoSwiss(bye.uid, null, item.key)];
            break;
          }
        }
        if (encontrado == null) {
          throw StateError('Sem pareamento Swiss válido no grupo ${item.key}: confrontos repetidos seriam necessários.');
        }
        retorno.addAll(encontrado);
      } else {
        final pares = _parear(jogadores, historico, item.key);
        if (pares == null) {
          throw StateError('Sem pareamento Swiss válido no grupo ${item.key}: revise os pods ou intervenha manualmente.');
        }
        retorno.addAll(pares);
      }
    }
    return retorno;
  }

  List<ConfrontoSwiss>? _parear(
    List<ClassificacaoJogadorModel> participantes,
    Map<String, Set<String>> historico,
    String podId,
  ) {
    var tentativas = 0;
    List<ConfrontoSwiss>? buscar(List<ClassificacaoJogadorModel> restantes) {
      if (restantes.isEmpty) return <ConfrontoSwiss>[];
      if (++tentativas > 200000) return null;
      // Primeiro o jogador que tem menos rivais possíveis, para evitar becos sem saída.
      var candidato = restantes.first;
      var menorOpcoes = restantes.length;
      for (final j in restantes) {
        final opcoes = restantes.where((x) => x.uid != j.uid &&
            !(historico[j.uid]?.contains(x.uid) ?? false)).length;
        if (opcoes < menorOpcoes) {
          menorOpcoes = opcoes;
          candidato = j;
        }
      }
      final demais = restantes.where((j) => j.uid != candidato.uid).toList();
      demais.sort((a, b) {
        final distanciaA = (a.pontos - candidato.pontos).abs();
        final distanciaB = (b.pontos - candidato.pontos).abs();
        final cmp = distanciaA.compareTo(distanciaB);
        return cmp != 0 ? cmp : restantes.indexOf(a).compareTo(restantes.indexOf(b));
      });
      for (final adversario in demais) {
        if (historico[candidato.uid]?.contains(adversario.uid) ?? false) continue;
        final proximos = restantes.where((j) =>
            j.uid != candidato.uid && j.uid != adversario.uid).toList();
        final sequencia = buscar(proximos);
        if (sequencia != null) {
          return [ConfrontoSwiss(candidato.uid, adversario.uid, podId), ...sequencia];
        }
      }
      return null;
    }
    return buscar(participantes);
  }

  int _seed(String torneioId, int rodada) {
    var hash = rodada;
    for (final c in torneioId.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return hash;
  }
}
