import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/torneio_model.dart';
import '../rules/pokemon_rulebook.dart';

class TorneioService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<TorneioModel> criarTorneio({
    required String nome,
    required DateTime dataHora,
    required String formato,
    required int quantidadeRodadas,
    required String criadoPor,
    String? sanctionId,
    String organizadorNome = '',
    String? organizadorPlayerId,
    String tipoEvento = 'custom',
    String formatoJogo = 'standard',
    String sistemaPareamento = 'swiss',
    int temporada = PokemonRulebook.temporadaAtual,
    String agrupamentoEtario = 'combinado',
    int tamanhoTopCut = 0,
  }) async {
    if (PokemonRulebook.eventoSancionado(tipoEvento) &&
        (sanctionId == null || sanctionId.trim().isEmpty)) {
      throw ArgumentError('Informe o Sanction ID para evento sancionado.');
    }
    if (PokemonRulebook.eventoSancionado(tipoEvento) &&
        PokemonRulebook.validarIdentificador(organizadorPlayerId) != null) {
      throw ArgumentError('Informe o Player ID do organizador.');
    }
    if (quantidadeRodadas < 1) throw ArgumentError('Quantidade de rodadas inválida.');
    if (tamanhoTopCut != 0 && tamanhoTopCut != 2 &&
        tamanhoTopCut != 4 && tamanhoTopCut != 8) {
      throw ArgumentError('Top Cut deve ser 0, 2, 4 ou 8.');
    }
  
    final codigo =
        await _gerarCodigoUnico();

    final torneioRef =
        _firestore
            .collection('tournaments')
            .doc();

    final torneio =
        TorneioModel(
      id: torneioRef.id,
      nome: nome,
      codigo: codigo,
      dataHora: dataHora,
      formato: formato,
      quantidadeRodadas:
          quantidadeRodadas,
      rodadaAtual: 0,
      status: 'inscricoes',
      criadoPor: criadoPor,
      criadoEm: DateTime.now(),
      sanctionId: sanctionId?.trim(),
      organizadorNome: organizadorNome.trim(),
      organizadorPlayerId: organizadorPlayerId?.trim(),
      tipoEvento: tipoEvento,
      formatoJogo: formatoJogo,
      sistemaPareamento: sistemaPareamento,
      temporada: temporada,
      agrupamentoEtario: agrupamentoEtario,
      tamanhoTopCut: tamanhoTopCut,
      versaoRegras: 'play-pokemon-$temporada',
    );

    await torneioRef.set(
      torneio.toMap(),
    );

    return torneio;
  }

  Future<String>
      _gerarCodigoUnico() async {
    final random = Random();

    while (true) {
      final numero =
          random.nextInt(9000) + 1000;

      final codigo =
          'TCG$numero';

      final snapshot =
          await _firestore
              .collection('tournaments')
              .where(
                'codigo',
                isEqualTo: codigo,
              )
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return codigo;
      }
    }
  }

  Stream<List<TorneioModel>>
      listarTorneiosDoAdm(
    String uid,
  ) {
    return _firestore
        .collection('tournaments')
        .where(
          'criadoPor',
          isEqualTo: uid,
        )
        .snapshots()
        .map(
          (snapshot) {
            final torneios =
                snapshot.docs
                    .map(
                      (doc) =>
                          TorneioModel
                              .fromMap(
                        doc.id,
                        doc.data(),
                      ),
                    )
                    .toList();

            torneios.sort(
              (a, b) =>
                  b.dataHora.compareTo(
                a.dataHora,
              ),
            );

            return torneios;
          },
        );
  }

  Stream<TorneioModel?>
      observarTorneio(
    String torneioId,
  ) {
    return _firestore
        .collection('tournaments')
        .doc(torneioId)
        .snapshots()
        .map(
          (doc) {
            if (!doc.exists) {
              return null;
            }

            final dados =
                doc.data();

            if (dados == null) {
              return null;
            }

            return TorneioModel.fromMap(
              doc.id,
              dados,
            );
          },
        );
  }

  Future<String> finalizarTorneio({
    required String torneioId,
  }) async {
    final torneioRef =
        _firestore
            .collection('tournaments')
            .doc(torneioId);

    return _firestore
        .runTransaction<String>(
      (transaction) async {
        final torneioSnapshot =
            await transaction.get(
          torneioRef,
        );

        if (!torneioSnapshot.exists) {
          return 'torneio_nao_encontrado';
        }

        final dadosTorneio =
            torneioSnapshot.data();

        if (dadosTorneio == null) {
          return 'torneio_nao_encontrado';
        }

        final status =
            dadosTorneio['status'];

        if (status == 'finalizado') {
          return 'torneio_finalizado';
        }

        if (status !=
            'em_andamento') {
          return 'status_invalido';
        }

        final rodadaAtual =
            dadosTorneio[
                    'rodadaAtual'] ??
                0;

        final quantidadeRodadas =
            dadosTorneio[
                    'quantidadeRodadas'] ??
                0;

        if (rodadaAtual <= 0) {
          return 'rodada_invalida';
        }

        if (rodadaAtual <
            quantidadeRodadas) {
          return 'rodadas_pendentes';
        }

        if ((dadosTorneio['tamanhoTopCut'] ?? 0) > 0 &&
            dadosTorneio['topcutConcluido'] != true) {
          return 'topcut_pendente';
        }

        final rodadaRef =
            torneioRef
                .collection('rounds')
                .doc(
                  rodadaAtual
                      .toString(),
                );

        final rodadaSnapshot =
            await transaction.get(
          rodadaRef,
        );

        if (!rodadaSnapshot.exists) {
          return 'rodada_nao_encontrada';
        }

        final dadosRodada =
            rodadaSnapshot.data();

        if (dadosRodada?['status'] !=
            'finalizada') {
          return 'rodada_nao_finalizada';
        }

        transaction.update(
          torneioRef,
          {
            'status':
                'finalizado',
            'finalizadoEm':
                Timestamp.now(),
          },
        );

        return 'ok';
      },
    );
  }
}