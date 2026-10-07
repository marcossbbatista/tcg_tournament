import 'package:cloud_firestore/cloud_firestore.dart';

import '../../jogador/models/jogador_torneio_model.dart';
import '../models/partida_model.dart';

class RodadaService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<String> iniciarTorneio({
    required String torneioId,
  }) async {
    final torneioRef =
        _firestore.collection('tournaments').doc(torneioId);

    final jogadoresSnapshot = await torneioRef
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
        torneioRef.collection('rounds').doc('1');

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
    final snapshot = await _firestore
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

    final jogadores = snapshot.docs
        .map(
          (doc) => JogadorTorneioModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    jogadores.sort(
      (a, b) => a.nome.compareTo(b.nome),
    );

    return jogadores;
  }

  Future<void> salvarPrimeiraRodada({
    required String torneioId,
    required List<PartidaModel> partidas,
  }) async {
    final rodadaRef = _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('rounds')
        .doc('1');

    final batch =
        _firestore.batch();

    for (final partida in partidas) {
      final partidaRef =
          rodadaRef.collection('matches').doc();

      batch.set(
        partidaRef,
        PartidaModel(
          id: partidaRef.id,
          mesa: partida.mesa,
          jogador1Uid: partida.jogador1Uid,
          jogador1Nome: partida.jogador1Nome,
          jogador2Uid: partida.jogador2Uid,
          jogador2Nome: partida.jogador2Nome,
          status: partida.bye
              ? 'aguardando'
              : 'aguardando',
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
    final rodadaRef = _firestore
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
          'status': bye
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
    final torneioRef = _firestore
        .collection('tournaments')
        .doc(torneioId);

    final rodadaRef = torneioRef
        .collection('rounds')
        .doc(rodada.toString());

    final partidasSnapshot = await rodadaRef
        .collection('matches')
        .get();

    if (partidasSnapshot.docs.isEmpty) {
      return 'nenhuma_partida';
    }

    final partidasRefs = partidasSnapshot.docs
        .map(
          (doc) => doc.reference,
        )
        .toList();

    return _firestore.runTransaction<String>(
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

        final List<PartidaModel> partidas =
            [];

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
              partida.status != 'finalizada',
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
                    partida.jogador1Uid] =
                (pontosPorJogador[
                            partida.jogador1Uid] ??
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
                    partida.jogador1Uid] =
                (pontosPorJogador[
                            partida.jogador1Uid] ??
                        0) +
                    3;

            pontosPorJogador.putIfAbsent(
              jogador2Uid,
              () => 0,
            );
          } else if (partida.placarJogador2 >
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
                    partida.jogador1Uid] =
                (pontosPorJogador[
                            partida.jogador1Uid] ??
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
          final jogadorRef = torneioRef
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
                  pontosAtuais + entry.value,
              if (jogadoresComBye
                  .contains(entry.key))
                'quantidadeByes':
                    quantidadeByesAtual + 1,
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

  Future<List<JogadorTorneioModel>>
      buscarClassificacao({
    required String torneioId,
  }) async {
    final snapshot = await _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('players')
        .where(
          'status',
          isEqualTo: 'aprovado',
        )
        .get();

    final jogadores = snapshot.docs
        .map(
          (doc) => JogadorTorneioModel.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    jogadores.sort(
      (a, b) {
        final comparacaoPontos =
            b.pontos.compareTo(
          a.pontos,
        );

        if (comparacaoPontos != 0) {
          return comparacaoPontos;
        }

        return a.nome.compareTo(
          b.nome,
        );
      },
    );

    return jogadores;
  }

  Future<Map<String, Set<String>>>
      _buscarHistoricoConfrontos({
    required String torneioId,
    required int rodadaAtual,
  }) async {
    final Map<String, Set<String>>
        historico = {};

    final torneioRef = _firestore
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
    final torneioRef = _firestore
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
        dadosTorneio['quantidadeRodadas'] ??
            0;

    if (rodadaAtual >=
        quantidadeRodadas) {
      return 'ultima_rodada';
    }

    final rodadaAtualRef = torneioRef
        .collection('rounds')
        .doc(rodadaAtual.toString());

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

    JogadorTorneioModel? jogadorBye;

    if (jogadoresAtivos.length.isOdd) {
      for (int i =
              jogadoresAtivos.length - 1;
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
        List<JogadorTorneioModel>.from(
      jogadoresAtivos,
    );

    final List<_Pareamento>
        pareamentos = [];

    while (restantes.length >= 2) {
      final jogador1 =
          restantes.removeAt(0);

      int adversarioIndex = -1;

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
        'numero':
            proximaRodada,
        'status':
            'configuracao',
        'criadaEm':
            Timestamp.now(),
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

      final partida =
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
      );

      batch.set(
        partidaRef,
        partida.toMap(),
      );
    }

    if (jogadorBye != null) {
      final partidaByeRef =
          proximaRodadaRef
              .collection('matches')
              .doc();

      final partidaBye =
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
      );

      batch.set(
        partidaByeRef,
        partidaBye.toMap(),
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
    final torneioRef = _firestore
        .collection('tournaments')
        .doc(torneioId);

    final rodadaRef = torneioRef
        .collection('rounds')
        .doc(rodada.toString());

    final rodadaSnapshot =
        await rodadaRef.get();

    if (!rodadaSnapshot.exists) {
      return 'rodada_nao_encontrada';
    }

    final statusRodada =
        rodadaSnapshot.data()?['status'];

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
                novaPartida.jogador1Uid,
            jogador1Nome:
                novaPartida.jogador1Nome,
            jogador2Uid:
                novaPartida.jogador2Uid,
            jogador2Nome:
                novaPartida.jogador2Nome,
            status:
                statusRodada ==
                        'configuracao'
                    ? 'aguardando'
                    : novaPartida.bye
                        ? 'finalizada'
                        : 'em_andamento',
            placarJogador1: 0,
            placarJogador2: 0,
            resultadoInformadoPor:
                null,
            bye:
                novaPartida.bye,
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
                  novaPartida.jogador1Uid &&
              partida.jogador2Uid ==
                  novaPartida.jogador2Uid;

      final ordemInvertida =
          !partida.bye &&
              !novaPartida.bye &&
              partida.jogador1Uid ==
                  novaPartida.jogador2Uid &&
              partida.jogador2Uid ==
                  novaPartida.jogador1Uid;

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

class _Pareamento {
  final JogadorTorneioModel jogador1;
  final JogadorTorneioModel jogador2;

  _Pareamento({
    required this.jogador1,
    required this.jogador2,
  });
}