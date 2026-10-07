import 'package:cloud_firestore/cloud_firestore.dart';

import '../../jogador/models/jogador_torneio_model.dart';
import '../../torneio/models/classificacao_jogador_model.dart';

import '../models/partida_model.dart';

class RodadaService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<String> iniciarTorneio({
    required String torneioId,
  }) async {
    final torneioRef =
        _firestore
            .collection('tournaments')
            .doc(torneioId);

    final jogadoresSnapshot =
        await torneioRef
            .collection('players')
            .where(
              'status',
              isEqualTo: 'aprovado',
            )
            .where(
              'ativo',
              isEqualTo: true,
            )
            .get();

    if (jogadoresSnapshot.docs.length < 2) {
      return 'jogadores_insuficientes';
    }

    await torneioRef.update({
      'status': 'em_andamento',
      'rodadaAtual': 1,
    });

    final rodadaRef =
        torneioRef
            .collection('rounds')
            .doc('1');

    await rodadaRef.set({
      'numero': 1,
      'status': 'configuracao',
      'criadaEm': Timestamp.now(),
    });

    return 'ok';
  }

  Future<List<JogadorTorneioModel>>
      listarJogadoresAprovados(
    String torneioId,
  ) async {
    final snapshot =
        await _firestore
            .collection('tournaments')
            .doc(torneioId)
            .collection('players')
            .where(
              'status',
              isEqualTo: 'aprovado',
            )
            .where(
              'ativo',
              isEqualTo: true,
            )
            .get();

    final jogadores =
        snapshot.docs
            .map(
              (doc) =>
                  JogadorTorneioModel.fromMap(
                doc.id,
                doc.data(),
              ),
            )
            .toList();

    jogadores.sort(
      (a, b) =>
          a.nome.compareTo(b.nome),
    );

    return jogadores;
  }

  Future<void> salvarPrimeiraRodada({
    required String torneioId,
    required List<PartidaModel> partidas,
  }) async {
    final rodadaRef =
        _firestore
            .collection('tournaments')
            .doc(torneioId)
            .collection('rounds')
            .doc('1');

    final partidasAtuais =
        await rodadaRef
            .collection('matches')
            .get();

    final batch =
        _firestore.batch();

    for (final doc
        in partidasAtuais.docs) {
      batch.delete(
        doc.reference,
      );
    }

    for (final partida in partidas) {
      final partidaRef =
          rodadaRef
              .collection('matches')
              .doc();

      batch.set(
        partidaRef,
        PartidaModel(
          id: partidaRef.id,
          mesa: partida.mesa,
          jogador1Uid:
              partida.jogador1Uid,
          jogador1Nome:
              partida.jogador1Nome,
          jogador2Uid:
              partida.jogador2Uid,
          jogador2Nome:
              partida.jogador2Nome,
          status: 'aguardando',
          placarJogador1: 0,
          placarJogador2: 0,
          resultadoInformadoPor: null,
          bye: partida.bye,
        ).toMap(),
      );
    }

    batch.update(
      rodadaRef,
      {
        'status': 'configuracao',
      },
    );

    await batch.commit();
  }

  Stream<String?> observarStatusRodada({
    required String torneioId,
    required int rodada,
  }) {
    return _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('rounds')
        .doc(rodada.toString())
        .snapshots()
        .map(
          (doc) {
            if (!doc.exists) {
              return null;
            }

            return doc.data()?['status'];
          },
        );
  }

  Future<String> iniciarRodada({
    required String torneioId,
    required int rodada,
  }) async {
    final rodadaRef =
        _firestore
            .collection('tournaments')
            .doc(torneioId)
            .collection('rounds')
            .doc(rodada.toString());

    final rodadaSnapshot =
        await rodadaRef.get();

    if (!rodadaSnapshot.exists) {
      return 'rodada_nao_encontrada';
    }

    final dadosRodada =
        rodadaSnapshot.data();

    final status =
        dadosRodada?['status'];

    if (status == 'em_andamento') {
      return 'rodada_ja_iniciada';
    }

    if (status == 'finalizada') {
      return 'rodada_finalizada';
    }

    if (status != 'configuracao') {
      return 'status_invalido';
    }

    final partidasSnapshot =
        await rodadaRef
            .collection('matches')
            .get();

    if (partidasSnapshot.docs.isEmpty) {
      return 'nenhuma_partida';
    }

    final batch =
        _firestore.batch();

    for (final doc
        in partidasSnapshot.docs) {
      final dados =
          doc.data();

      final bool bye =
          dados['bye'] ?? false;

      batch.update(
        doc.reference,
        {
          'status':
              bye
                  ? 'finalizada'
                  : 'em_andamento',
          'placarJogador1': 0,
          'placarJogador2': 0,
          'resultadoInformadoPor': null,
        },
      );
    }

    batch.update(
      rodadaRef,
      {
        'status': 'em_andamento',
        'iniciadaEm': Timestamp.now(),
      },
    );

    await batch.commit();

    return 'ok';
  }

  Future<String> encerrarRodada({
    required String torneioId,
    required int rodada,
  }) async {
    final torneioRef =
        _firestore
            .collection('tournaments')
            .doc(torneioId);

    final rodadaRef =
        torneioRef
            .collection('rounds')
            .doc(rodada.toString());

    final partidasSnapshot =
        await rodadaRef
            .collection('matches')
            .get();

    if (partidasSnapshot.docs.isEmpty) {
      return 'nenhuma_partida';
    }

    final partidasRefs =
        partidasSnapshot.docs
            .map(
              (doc) => doc.reference,
            )
            .toList();

    return _firestore
        .runTransaction<String>(
      (transaction) async {
        final rodadaSnapshot =
            await transaction.get(
          rodadaRef,
        );

        if (!rodadaSnapshot.exists) {
          return 'rodada_nao_encontrada';
        }

        final dadosRodada =
            rodadaSnapshot.data();

        if (dadosRodada?['status'] ==
            'finalizada') {
          return 'rodada_finalizada';
        }

        final List<PartidaModel>
            partidas = [];

        for (final partidaRef
            in partidasRefs) {
          final partidaSnapshot =
              await transaction.get(
            partidaRef,
          );

          if (!partidaSnapshot.exists) {
            continue;
          }

          final dados =
              partidaSnapshot.data();

          if (dados == null) {
            continue;
          }

          partidas.add(
            PartidaModel.fromMap(
              partidaSnapshot.id,
              dados,
            ),
          );
        }

        if (partidas.isEmpty) {
          return 'nenhuma_partida';
        }

        final possuiPartidaPendente =
            partidas.any(
          (partida) =>
              partida.status !=
              'finalizada',
        );

        if (possuiPartidaPendente) {
          return 'partida_pendente';
        }

        final Map<String, int>
            pontosPorJogador = {};

        final Set<String>
            jogadoresComBye = {};

        for (final partida in partidas) {
          if (partida.bye) {
            pontosPorJogador[
                    partida
                        .jogador1Uid] =
                (pontosPorJogador[
                            partida
                                .jogador1Uid] ??
                        0) +
                    3;

            jogadoresComBye.add(
              partida.jogador1Uid,
            );

            continue;
          }

          final jogador2Uid =
              partida.jogador2Uid;

          if (jogador2Uid == null) {
            continue;
          }

          if (partida.placarJogador1 >
              partida.placarJogador2) {
            pontosPorJogador[
                    partida
                        .jogador1Uid] =
                (pontosPorJogador[
                            partida
                                .jogador1Uid] ??
                        0) +
                    3;

            pontosPorJogador.putIfAbsent(
              jogador2Uid,
              () => 0,
            );
          } else if (partida
                  .placarJogador2 >
              partida.placarJogador1) {
            pontosPorJogador[
                    jogador2Uid] =
                (pontosPorJogador[
                            jogador2Uid] ??
                        0) +
                    3;

            pontosPorJogador.putIfAbsent(
              partida.jogador1Uid,
              () => 0,
            );
          } else {
            pontosPorJogador[
                    partida
                        .jogador1Uid] =
                (pontosPorJogador[
                            partida
                                .jogador1Uid] ??
                        0) +
                    1;

            pontosPorJogador[
                    jogador2Uid] =
                (pontosPorJogador[
                            jogador2Uid] ??
                        0) +
                    1;
          }
        }

        for (final entry
            in pontosPorJogador.entries) {
          final jogadorRef =
              torneioRef
                  .collection('players')
                  .doc(entry.key);

          final jogadorSnapshot =
              await transaction.get(
            jogadorRef,
          );

          if (!jogadorSnapshot.exists) {
            continue;
          }

          final dadosJogador =
              jogadorSnapshot.data();

          final pontosAtuais =
              dadosJogador?['pontos'] ?? 0;

          final quantidadeByesAtual =
              dadosJogador?[
                      'quantidadeByes'] ??
                  0;

          transaction.update(
            jogadorRef,
            {
              'pontos':
                  pontosAtuais +
                  entry.value,
              if (jogadoresComBye
                  .contains(entry.key))
                'quantidadeByes':
                    quantidadeByesAtual +
                    1,
            },
          );
        }

        transaction.update(
          rodadaRef,
          {
            'status': 'finalizada',
            'finalizadaEm':
                Timestamp.now(),
          },
        );

        return 'ok';
      },
    );
  }

  Future<List<ClassificacaoJogadorModel>>
      buscarClassificacao({
    required String torneioId,
  }) async {
    final torneioRef =
        _firestore
            .collection('tournaments')
            .doc(torneioId);

    final torneioSnapshot =
        await torneioRef.get();

    if (!torneioSnapshot.exists) {
      return [];
    }

    final dadosTorneio =
        torneioSnapshot.data();

    if (dadosTorneio == null) {
      return [];
    }

    final rodadaAtual =
        dadosTorneio['rodadaAtual'] ?? 0;

    final jogadoresSnapshot =
        await torneioRef
            .collection('players')
            .where(
              'status',
              isEqualTo: 'aprovado',
            )
            .get();

    final Map<String, _EstatisticaJogador>
        estatisticas = {};

    for (final doc
        in jogadoresSnapshot.docs) {
      final jogador =
          JogadorTorneioModel.fromMap(
        doc.id,
        doc.data(),
      );

      estatisticas[jogador.uid] =
          _EstatisticaJogador(
        uid: jogador.uid,
        nome: jogador.nome,
        ativo: jogador.ativo,
        quantidadeByes:
            jogador.quantidadeByes,
      );
    }

    final Map<String, Map<String, int>>
        confrontoDireto = {};

    for (int numeroRodada = 1;
        numeroRodada <= rodadaAtual;
        numeroRodada++) {
      final rodadaRef =
          torneioRef
              .collection('rounds')
              .doc(
                numeroRodada.toString(),
              );

      final rodadaSnapshot =
          await rodadaRef.get();

      if (!rodadaSnapshot.exists) {
        continue;
      }

      final dadosRodada =
          rodadaSnapshot.data();

      if (dadosRodada?['status'] !=
          'finalizada') {
        continue;
      }

      final partidasSnapshot =
          await rodadaRef
              .collection('matches')
              .get();

      for (final doc
          in partidasSnapshot.docs) {
        final partida =
            PartidaModel.fromMap(
          doc.id,
          doc.data(),
        );

        if (partida.status !=
            'finalizada') {
          continue;
        }

        final jogador1 =
            estatisticas[
                partida.jogador1Uid];

        if (jogador1 == null) {
          continue;
        }

        if (partida.bye) {
          jogador1.pontos += 3;
          jogador1.byes++;

          continue;
        }

        final jogador2Uid =
            partida.jogador2Uid;

        if (jogador2Uid == null) {
          continue;
        }

        final jogador2 =
            estatisticas[
                jogador2Uid];

        if (jogador2 == null) {
          continue;
        }

        jogador1
            .adversarios
            .add(
              jogador2.uid,
            );

        jogador2
            .adversarios
            .add(
              jogador1.uid,
            );

        jogador1.partidasConsideradas++;
        jogador2.partidasConsideradas++;

        if (partida.placarJogador1 >
            partida.placarJogador2) {
          jogador1.vitorias++;
          jogador2.derrotas++;

          jogador1.pontos += 3;

          confrontoDireto
              .putIfAbsent(
                jogador1.uid,
                () => {},
              )[jogador2.uid] = 1;

          confrontoDireto
              .putIfAbsent(
                jogador2.uid,
                () => {},
              )[jogador1.uid] = -1;
        } else if (partida
                .placarJogador2 >
            partida.placarJogador1) {
          jogador2.vitorias++;
          jogador1.derrotas++;

          jogador2.pontos += 3;

          confrontoDireto
              .putIfAbsent(
                jogador2.uid,
                () => {},
              )[jogador1.uid] = 1;

          confrontoDireto
              .putIfAbsent(
                jogador1.uid,
                () => {},
              )[jogador2.uid] = -1;
        } else {
          jogador1.empates++;
          jogador2.empates++;

          jogador1.pontos++;
          jogador2.pontos++;

          confrontoDireto
              .putIfAbsent(
                jogador1.uid,
                () => {},
              )[jogador2.uid] = 0;

          confrontoDireto
              .putIfAbsent(
                jogador2.uid,
                () => {},
              )[jogador1.uid] = 0;
        }
      }
    }

    //
    // Primeiro calculamos o Win Percentage
    // de cada jogador.
    //
    for (final estatistica
        in estatisticas.values) {
      estatistica.winPercentage =
          _calcularWinPercentage(
        vitorias:
            estatistica.vitorias,
        partidasConsideradas:
            estatistica
                .partidasConsideradas,
        ativo:
            estatistica.ativo,
      );
    }

    //
    // Depois calculamos o Opponents'
    // Win Percentage.
    //
    for (final estatistica
        in estatisticas.values) {
      if (estatistica
          .adversarios.isEmpty) {
        estatistica
                .opponentWinPercentage =
            0;

        continue;
      }

      double total = 0;
      int quantidade = 0;

      for (final adversarioUid
          in estatistica.adversarios) {
        final adversario =
            estatisticas[
                adversarioUid];

        if (adversario == null) {
          continue;
        }

        total +=
            adversario.winPercentage;

        quantidade++;
      }

      estatistica
              .opponentWinPercentage =
          quantidade == 0
              ? 0
              : total / quantidade;
    }

    //
    // Depois calculamos o Opponents'
    // Opponents' Win Percentage.
    //
    for (final estatistica
        in estatisticas.values) {
      if (estatistica
          .adversarios.isEmpty) {
        estatistica
                .opponentOpponentWinPercentage =
            0;

        continue;
      }

      double total = 0;
      int quantidade = 0;

      for (final adversarioUid
          in estatistica.adversarios) {
        final adversario =
            estatisticas[
                adversarioUid];

        if (adversario == null) {
          continue;
        }

        total += adversario
            .opponentWinPercentage;

        quantidade++;
      }

      estatistica
              .opponentOpponentWinPercentage =
          quantidade == 0
              ? 0
              : total / quantidade;
    }

    final classificacao =
        estatisticas.values
            .map(
              (estatistica) =>
                  ClassificacaoJogadorModel(
                uid:
                    estatistica.uid,
                nome:
                    estatistica.nome,
                pontos:
                    estatistica.pontos,
                vitorias:
                    estatistica.vitorias,
                derrotas:
                    estatistica.derrotas,
                empates:
                    estatistica.empates,
                winPercentage:
                    estatistica
                        .winPercentage,
                opponentWinPercentage:
                    estatistica
                        .opponentWinPercentage,
                opponentOpponentWinPercentage:
                    estatistica
                        .opponentOpponentWinPercentage,
                ativo:
                    estatistica.ativo,
                quantidadeByes:
                    estatistica.byes,
              ),
            )
            .toList();

    //
    // Primeira ordenação:
    //
    // 1. Pontos
    // 2. Op Win %
    // 3. Op Op Win %
    //
    classificacao.sort(
      (a, b) {
        final pontos =
            b.pontos.compareTo(
          a.pontos,
        );

        if (pontos != 0) {
          return pontos;
        }

        final opWin =
            b.opponentWinPercentage
                .compareTo(
          a.opponentWinPercentage,
        );

        if (opWin != 0) {
          return opWin;
        }

        final opOpWin =
            b.opponentOpponentWinPercentage
                .compareTo(
          a.opponentOpponentWinPercentage,
        );

        if (opOpWin != 0) {
          return opOpWin;
        }

        return 0;
      },
    );

    //
    // Agora tratamos grupos que continuam
    // completamente empatados.
    //
    int inicio = 0;

    while (inicio <
        classificacao.length) {
      int fim =
          inicio + 1;

      while (fim <
              classificacao.length &&
          _mesmosDesempates(
            classificacao[inicio],
            classificacao[fim],
          )) {
        fim++;
      }

      final quantidadeEmpatados =
          fim - inicio;

      if (quantidadeEmpatados == 2) {
        final jogador1 =
            classificacao[inicio];

        final jogador2 =
            classificacao[
                inicio + 1];

        final resultadoConfronto =
            confrontoDireto[
                    jogador1.uid]
                ?[jogador2.uid];

        if (resultadoConfronto ==
            -1) {
          classificacao[inicio] =
              jogador2;

          classificacao[
              inicio + 1] = jogador1;
        } else if (resultadoConfronto ==
                null ||
            resultadoConfronto == 0) {
          _ordenarFallback(
            classificacao,
            inicio,
            fim,
            torneioId,
          );
        }
      } else if (quantidadeEmpatados >
          1) {
        _ordenarFallback(
          classificacao,
          inicio,
          fim,
          torneioId,
        );
      }

      inicio = fim;
    }

    return classificacao;
  }

  double _calcularWinPercentage({
    required int vitorias,
    required int partidasConsideradas,
    required bool ativo,
  }) {
    //
    // BYE não entra nas partidas consideradas.
    //
    if (partidasConsideradas == 0) {
      return 0.25;
    }

    double percentual =
        vitorias /
        partidasConsideradas;

    //
    // Play! Pokémon:
    // mínimo 25%.
    //
    if (percentual < 0.25) {
      percentual = 0.25;
    }

    //
    // Jogador que saiu antes de terminar:
    // máximo 75%.
    //
    // No nosso sistema usamos ativo = false
    // para representar drop/desistência.
    //
    if (!ativo &&
        percentual > 0.75) {
      percentual = 0.75;
    }

    //
    // Jogador que segue no torneio:
    // máximo 100%.
    //
    if (ativo &&
        percentual > 1) {
      percentual = 1;
    }

    return percentual;
  }

  bool _mesmosDesempates(
    ClassificacaoJogadorModel a,
    ClassificacaoJogadorModel b,
  ) {
    const tolerancia =
        0.0000001;

    return a.pontos == b.pontos &&
        (a.opponentWinPercentage -
                    b.opponentWinPercentage)
                .abs() <
            tolerancia &&
        (a.opponentOpponentWinPercentage -
                    b.opponentOpponentWinPercentage)
                .abs() <
            tolerancia;
  }

  void _ordenarFallback(
    List<ClassificacaoJogadorModel>
        classificacao,
    int inicio,
    int fim,
    String torneioId,
  ) {
    final grupo =
        classificacao
            .sublist(
              inicio,
              fim,
            );

    //
    // O regulamento prevê ordem aleatória
    // quando os demais critérios não resolvem.
    //
    // Para a classificação não ficar mudando
    // cada vez que a tela atualizar, geramos
    // uma ordem pseudoaleatória estável baseada
    // no torneio + UID do jogador.
    //
    grupo.sort(
      (a, b) {
        final valorA =
            _valorDesempateAleatorio(
          '$torneioId:${a.uid}',
        );

        final valorB =
            _valorDesempateAleatorio(
          '$torneioId:${b.uid}',
        );

        return valorA.compareTo(
          valorB,
        );
      },
    );

    for (int i = 0;
        i < grupo.length;
        i++) {
      classificacao[
          inicio + i] = grupo[i];
    }
  }

  int _valorDesempateAleatorio(
    String valor,
  ) {
    int hash = 17;

    for (final codigo
        in valor.codeUnits) {
      hash =
          (hash * 31 + codigo) &
          0x7fffffff;
    }

    return hash;
  }

  Future<Map<String, Set<String>>>
      _buscarHistoricoConfrontos({
    required String torneioId,
    required int rodadaAtual,
  }) async {
    final Map<String, Set<String>>
        historico = {};

    final torneioRef =
        _firestore
            .collection('tournaments')
            .doc(torneioId);

    for (int numeroRodada = 1;
        numeroRodada <= rodadaAtual;
        numeroRodada++) {
      final partidasSnapshot =
          await torneioRef
              .collection('rounds')
              .doc(
                numeroRodada.toString(),
              )
              .collection('matches')
              .get();

      for (final doc
          in partidasSnapshot.docs) {
        final partida =
            PartidaModel.fromMap(
          doc.id,
          doc.data(),
        );

        if (partida.bye ||
            partida.jogador2Uid == null) {
          continue;
        }

        historico
            .putIfAbsent(
              partida.jogador1Uid,
              () => <String>{},
            )
            .add(
              partida.jogador2Uid!,
            );

        historico
            .putIfAbsent(
              partida.jogador2Uid!,
              () => <String>{},
            )
            .add(
              partida.jogador1Uid,
            );
      }
    }

    return historico;
  }

  Future<String> gerarProximaRodada({
    required String torneioId,
    required int rodadaAtual,
  }) async {
    final torneioRef =
        _firestore
            .collection('tournaments')
            .doc(torneioId);

    final torneioSnapshot =
        await torneioRef.get();

    if (!torneioSnapshot.exists) {
      return 'torneio_nao_encontrado';
    }

    final dadosTorneio =
        torneioSnapshot.data();

    if (dadosTorneio == null) {
      return 'torneio_nao_encontrado';
    }

    final quantidadeRodadas =
        dadosTorneio[
                'quantidadeRodadas'] ??
            0;

    if (rodadaAtual >=
        quantidadeRodadas) {
      return 'ultima_rodada';
    }

    final rodadaAtualRef =
        torneioRef
            .collection('rounds')
            .doc(
              rodadaAtual.toString(),
            );

    final rodadaAtualSnapshot =
        await rodadaAtualRef.get();

    if (!rodadaAtualSnapshot.exists) {
      return 'rodada_nao_encontrada';
    }

    if (rodadaAtualSnapshot
            .data()?['status'] !=
        'finalizada') {
      return 'rodada_nao_finalizada';
    }

    final proximaRodada =
        rodadaAtual + 1;

    final proximaRodadaRef =
        torneioRef
            .collection('rounds')
            .doc(
              proximaRodada.toString(),
            );

    final proximaRodadaSnapshot =
        await proximaRodadaRef.get();

    if (proximaRodadaSnapshot.exists) {
      return 'rodada_ja_existe';
    }

    //
    // Aqui a geração Swiss passa a usar
    // a nova classificação oficial.
    //
    final classificacao =
        await buscarClassificacao(
      torneioId: torneioId,
    );

    final jogadoresAtivos =
        classificacao
            .where(
              (jogador) =>
                  jogador.ativo,
            )
            .toList();

    if (jogadoresAtivos.length < 2) {
      return 'jogadores_insuficientes';
    }

    final historico =
        await _buscarHistoricoConfrontos(
      torneioId: torneioId,
      rodadaAtual: rodadaAtual,
    );

    ClassificacaoJogadorModel?
        jogadorBye;

    if (jogadoresAtivos.length.isOdd) {
      //
      // Começamos do final da classificação,
      // procurando alguém que ainda não
      // recebeu BYE.
      //
      for (int i =
              jogadoresAtivos.length -
                  1;
          i >= 0;
          i--) {
        if (jogadoresAtivos[i]
                .quantidadeByes ==
            0) {
          jogadorBye =
              jogadoresAtivos[i];

          break;
        }
      }

      jogadorBye ??=
          jogadoresAtivos.last;

      jogadoresAtivos.removeWhere(
        (jogador) =>
            jogador.uid ==
            jogadorBye!.uid,
      );
    }

    final restantes =
        List<ClassificacaoJogadorModel>
            .from(
      jogadoresAtivos,
    );

    final List<_Pareamento>
        pareamentos = [];

    while (restantes.length >= 2) {
      final jogador1 =
          restantes.removeAt(0);

      int adversarioIndex = -1;

      //
      // Como a lista está ordenada
      // pela classificação, procuramos
      // o primeiro adversário ainda
      // não enfrentado.
      //
      for (int i = 0;
          i < restantes.length;
          i++) {
        final candidato =
            restantes[i];

        final jaJogaram =
            historico[jogador1.uid]
                    ?.contains(
                      candidato.uid,
                    ) ??
                false;

        if (!jaJogaram) {
          adversarioIndex = i;

          break;
        }
      }

      //
      // Se não existir alternativa,
      // permitimos rematch.
      //
      if (adversarioIndex == -1) {
        adversarioIndex = 0;
      }

      final jogador2 =
          restantes.removeAt(
        adversarioIndex,
      );

      pareamentos.add(
        _Pareamento(
          jogador1: jogador1,
          jogador2: jogador2,
        ),
      );
    }

    final batch =
        _firestore.batch();

    batch.set(
      proximaRodadaRef,
      {
        'numero': proximaRodada,
        'status': 'configuracao',
        'criadaEm': Timestamp.now(),
      },
    );

    for (int i = 0;
        i < pareamentos.length;
        i++) {
      final pareamento =
          pareamentos[i];

      final partidaRef =
          proximaRodadaRef
              .collection('matches')
              .doc();

      batch.set(
        partidaRef,
        PartidaModel(
          id: partidaRef.id,
          mesa: i + 1,
          jogador1Uid:
              pareamento.jogador1.uid,
          jogador1Nome:
              pareamento.jogador1.nome,
          jogador2Uid:
              pareamento.jogador2.uid,
          jogador2Nome:
              pareamento.jogador2.nome,
          status: 'aguardando',
          placarJogador1: 0,
          placarJogador2: 0,
          resultadoInformadoPor: null,
          bye: false,
        ).toMap(),
      );
    }

    if (jogadorBye != null) {
      final partidaByeRef =
          proximaRodadaRef
              .collection('matches')
              .doc();

      batch.set(
        partidaByeRef,
        PartidaModel(
          id: partidaByeRef.id,
          mesa:
              pareamentos.length + 1,
          jogador1Uid:
              jogadorBye.uid,
          jogador1Nome:
              jogadorBye.nome,
          jogador2Uid: null,
          jogador2Nome: null,
          status: 'aguardando',
          placarJogador1: 0,
          placarJogador2: 0,
          resultadoInformadoPor: null,
          bye: true,
        ).toMap(),
      );
    }

    batch.update(
      torneioRef,
      {
        'rodadaAtual':
            proximaRodada,
      },
    );

    await batch.commit();

    return 'ok';
  }

  Future<String> editarRodada({
    required String torneioId,
    required int rodada,
    required List<PartidaModel> novasPartidas,
  }) async {
    final torneioRef =
        _firestore
            .collection('tournaments')
            .doc(torneioId);

    final rodadaRef =
        torneioRef
            .collection('rounds')
            .doc(rodada.toString());

    final rodadaSnapshot =
        await rodadaRef.get();

    if (!rodadaSnapshot.exists) {
      return 'rodada_nao_encontrada';
    }

    final statusRodada =
        rodadaSnapshot
            .data()?['status'];

    if (statusRodada ==
        'finalizada') {
      return 'rodada_finalizada';
    }

    final jogadoresSnapshot =
        await torneioRef
            .collection('players')
            .where(
              'status',
              isEqualTo: 'aprovado',
            )
            .where(
              'ativo',
              isEqualTo: true,
            )
            .get();

    final jogadoresValidos =
        jogadoresSnapshot.docs
            .map(
              (doc) => doc.id,
            )
            .toSet();

    final jogadoresUtilizados =
        <String>{};

    int quantidadeByes = 0;

    for (final partida
        in novasPartidas) {
      if (!jogadoresValidos.contains(
        partida.jogador1Uid,
      )) {
        return 'jogador_invalido';
      }

      if (!jogadoresUtilizados.add(
        partida.jogador1Uid,
      )) {
        return 'jogador_duplicado';
      }

      if (partida.bye) {
        quantidadeByes++;

        continue;
      }

      final jogador2Uid =
          partida.jogador2Uid;

      if (jogador2Uid == null ||
          jogador2Uid.isEmpty) {
        return 'jogador_invalido';
      }

      if (jogador2Uid ==
          partida.jogador1Uid) {
        return 'mesmo_jogador';
      }

      if (!jogadoresValidos.contains(
        jogador2Uid,
      )) {
        return 'jogador_invalido';
      }

      if (!jogadoresUtilizados.add(
        jogador2Uid,
      )) {
        return 'jogador_duplicado';
      }
    }

    if (jogadoresUtilizados.length !=
        jogadoresValidos.length) {
      return 'jogadores_sem_partida';
    }

    if (jogadoresValidos.length.isEven &&
        quantidadeByes > 0) {
      return 'bye_invalido';
    }

    if (jogadoresValidos.length.isOdd &&
        quantidadeByes != 1) {
      return 'bye_obrigatorio';
    }

    final partidasAtuaisSnapshot =
        await rodadaRef
            .collection('matches')
            .get();

    final partidasAtuais =
        partidasAtuaisSnapshot.docs
            .map(
              (doc) =>
                  PartidaModel.fromMap(
                doc.id,
                doc.data(),
              ),
            )
            .toList();

    final batch =
        _firestore.batch();

    for (final documento
        in partidasAtuaisSnapshot.docs) {
      batch.delete(
        documento.reference,
      );
    }

    for (int i = 0;
        i < novasPartidas.length;
        i++) {
      final novaPartida =
          novasPartidas[i];

      final partidaAnterior =
          _buscarPartidaIgual(
        partidasAtuais,
        novaPartida,
      );

      final partidaRef =
          rodadaRef
              .collection('matches')
              .doc();

      if (partidaAnterior != null) {
        batch.set(
          partidaRef,
          PartidaModel(
            id: partidaRef.id,
            mesa: i + 1,
            jogador1Uid:
                partidaAnterior
                    .jogador1Uid,
            jogador1Nome:
                partidaAnterior
                    .jogador1Nome,
            jogador2Uid:
                partidaAnterior
                    .jogador2Uid,
            jogador2Nome:
                partidaAnterior
                    .jogador2Nome,
            status:
                partidaAnterior.status,
            placarJogador1:
                partidaAnterior
                    .placarJogador1,
            placarJogador2:
                partidaAnterior
                    .placarJogador2,
            resultadoInformadoPor:
                partidaAnterior
                    .resultadoInformadoPor,
            bye:
                partidaAnterior.bye,
          ).toMap(),
        );
      } else {
        batch.set(
          partidaRef,
          PartidaModel(
            id: partidaRef.id,
            mesa: i + 1,
            jogador1Uid:
                novaPartida
                    .jogador1Uid,
            jogador1Nome:
                novaPartida
                    .jogador1Nome,
            jogador2Uid:
                novaPartida
                    .jogador2Uid,
            jogador2Nome:
                novaPartida
                    .jogador2Nome,
            status:
                statusRodada ==
                        'configuracao'
                    ? 'aguardando'
                    : novaPartida.bye
                        ? 'finalizada'
                        : 'em_andamento',
            placarJogador1: 0,
            placarJogador2: 0,
            resultadoInformadoPor: null,
            bye: novaPartida.bye,
          ).toMap(),
        );
      }
    }

    await batch.commit();

    return 'ok';
  }

  PartidaModel? _buscarPartidaIgual(
    List<PartidaModel> partidas,
    PartidaModel novaPartida,
  ) {
    for (final partida in partidas) {
      final mesmaOrdem =
          partida.jogador1Uid ==
                  novaPartida
                      .jogador1Uid &&
              partida.jogador2Uid ==
                  novaPartida
                      .jogador2Uid;

      final ordemInvertida =
          !partida.bye &&
              !novaPartida.bye &&
              partida.jogador1Uid ==
                  novaPartida
                      .jogador2Uid &&
              partida.jogador2Uid ==
                  novaPartida
                      .jogador1Uid;

      if ((mesmaOrdem ||
              ordemInvertida) &&
          partida.bye ==
              novaPartida.bye) {
        return partida;
      }
    }

    return null;
  }
}

class _EstatisticaJogador {
  final String uid;
  final String nome;
  final bool ativo;
  final int quantidadeByes;

  int pontos = 0;

  int vitorias = 0;
  int derrotas = 0;
  int empates = 0;
  int byes = 0;

  int partidasConsideradas = 0;

  double winPercentage = 0;
  double opponentWinPercentage = 0;
  double opponentOpponentWinPercentage = 0;

  final List<String> adversarios = [];

  _EstatisticaJogador({
    required this.uid,
    required this.nome,
    required this.ativo,
    required this.quantidadeByes,
  }) {
    byes = quantidadeByes;
  }
}

class _Pareamento {
  final ClassificacaoJogadorModel jogador1;
  final ClassificacaoJogadorModel jogador2;

  _Pareamento({
    required this.jogador1,
    required this.jogador2,
  });
}