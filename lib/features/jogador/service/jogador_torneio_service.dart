import 'package:cloud_firestore/cloud_firestore.dart';

import '../../torneio/models/torneio_model.dart';
import '../../auth/models/usuario_model.dart';
import '../models/jogador_torneio_model.dart';
import '../models/torneio_jogador_model.dart';
import 'package:flutter/foundation.dart';
import '../../torneio/rules/pokemon_rulebook.dart';

class JogadorTorneioService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<TorneioModel?> buscarTorneioPorCodigo(
    String codigo,
  ) async {
    final resultado = await _firestore
        .collection('tournaments')
        .where(
          'codigo',
          isEqualTo: codigo.trim().toUpperCase(),
        )
        .limit(1)
        .get();

    if (resultado.docs.isEmpty) {
      return null;
    }

    final documento = resultado.docs.first;

    return TorneioModel.fromMap(
      documento.id,
      documento.data(),
    );
  }

  Future<String> solicitarParticipacao({
    required TorneioModel torneio,
    required UsuarioModel usuario,
  }) async {
    if (torneio.status != 'inscricoes') {
      return 'inscricoes_encerradas';
    }

    if (!usuario.possuiDadosOficiais) {
      throw StateError('Complete os dados oficiais em Meu perfil antes de participar.');
    }

    final documento = _firestore
        .collection('tournaments')
        .doc(torneio.id)
        .collection('players')
        .doc(usuario.uid);

    final existente = await documento.get();

    if (existente.exists) {
      final dados = existente.data();

      return dados?['status'] ?? 'pendente';
    }

    // Impede inscrições com Player ID repetido no mesmo torneio.
    final iguais = await documento.parent
        .where('pokemonPlayerId', isEqualTo: usuario.pokemonPlayerId)
        .limit(1).get();
    if (iguais.docs.isNotEmpty) {
      throw StateError('Este Player ID já está inscrito no torneio.');
    }

    final jogador = JogadorTorneioModel(
      uid: usuario.uid,
      nome: usuario.nome,
      email: usuario.email,
      status: 'pendente',
      pontos: 0,
      ativo: true,
      entrouEm: DateTime.now(),
      primeiroNome: usuario.primeiroNome,
      sobrenome: usuario.sobrenome,
      pokemonPlayerId: usuario.pokemonPlayerId,
      dataNascimento: usuario.dataNascimento,
      divisaoEtaria: PokemonRulebook.divisaoEtaria(
        usuario.dataNascimento!, torneio.temporada,
      ),
    );

    await documento.set(
      jogador.toMap(),
    );

    return 'pendente';
  }

  /// Cadastro de participante sem conta Firebase (inscrição presencial).
  /// Usa um identificador previsível por POP ID para evitar duplicações manuais.
  Future<void> cadastrarJogadorPresencial({
    required String torneioId,
    required String primeiroNome,
    required String sobrenome,
    required String pokemonPlayerId,
    required DateTime dataNascimento,
    String email = '',
  }) async {
    final torneioRef = _firestore.collection('tournaments').doc(torneioId);
    final snapshot = await torneioRef.get();
    if (!snapshot.exists) throw StateError('Torneio não encontrado.');
    final torneio = TorneioModel.fromMap(torneioId, snapshot.data()!);
    if (torneio.status == 'finalizado') throw StateError('Torneio finalizado.');
    if (PokemonRulebook.validarIdentificador(pokemonPlayerId) != null) {
      throw ArgumentError('Player ID inválido.');
    }
    if (torneio.status == 'em_andamento' &&
        PokemonRulebook.eventoSancionado(torneio.tipoEvento) &&
        torneio.rodadaAtual > 3) {
      throw StateError('Inscrição tardia após a terceira rodada não permitida neste evento.');
    }
    final duplicados = await torneioRef.collection('players')
        .where('pokemonPlayerId', isEqualTo: pokemonPlayerId.trim()).limit(1).get();
    if (duplicados.docs.isNotEmpty) throw StateError('Player ID já inscrito.');
    final uid = 'pop_${pokemonPlayerId.trim()}';
    final doc = torneioRef.collection('players').doc(uid);
    await _firestore.runTransaction((tx) async {
      if ((await tx.get(doc)).exists) throw StateError('Jogador já inscrito.');
      final lateEntry = torneio.status == 'em_andamento' ? torneio.rodadaAtual + 1 : null;
      final jogador = JogadorTorneioModel(
        uid: uid,
        nome: '${primeiroNome.trim()} ${sobrenome.trim()}',
        email: email.trim(),
        status: 'aprovado',
        pontos: 0,
        ativo: true,
        entrouEm: DateTime.now(),
        primeiroNome: primeiroNome.trim(),
        sobrenome: sobrenome.trim(),
        pokemonPlayerId: pokemonPlayerId.trim(),
        dataNascimento: dataNascimento,
        divisaoEtaria: PokemonRulebook.divisaoEtaria(dataNascimento, torneio.temporada),
        rodadaEntradaTardia: lateEntry,
      );
      tx.set(doc, jogador.toMap());
    });
  }

  Future<void> atualizarDadosOficiais({
    required String torneioId,
    required String jogadorUid,
    required String primeiroNome,
    required String sobrenome,
    required String pokemonPlayerId,
    required DateTime dataNascimento,
  }) async {
    if (primeiroNome.trim().isEmpty || sobrenome.trim().isEmpty ||
        PokemonRulebook.validarIdentificador(pokemonPlayerId) != null) {
      throw ArgumentError('Preencha nome, sobrenome e Player ID válidos.');
    }
    final torneioRef = _firestore.collection('tournaments').doc(torneioId);
    final torneioSnap = await torneioRef.get();
    if (!torneioSnap.exists) throw StateError('Torneio não encontrado.');
    final torneio = TorneioModel.fromMap(torneioId, torneioSnap.data()!);
    if (torneio.status == 'finalizado') throw StateError('Torneio finalizado.');
    final iguais = await torneioRef.collection('players')
        .where('pokemonPlayerId', isEqualTo: pokemonPlayerId.trim()).get();
    if (iguais.docs.any((d) => d.id != jogadorUid)) {
      throw StateError('Player ID em uso por outro jogador.');
    }
    await torneioRef.collection('players').doc(jogadorUid).update({
      'pokemonPlayerId': pokemonPlayerId.trim(),
      'primeiroNome': primeiroNome.trim(),
      'sobrenome': sobrenome.trim(),
      'dataNascimento': Timestamp.fromDate(dataNascimento),
      'divisaoEtaria': PokemonRulebook.divisaoEtaria(dataNascimento, torneio.temporada),
    });
  }

  /// Drop somente entre rodadas, nunca durante uma rodada em andamento.
  Future<void> registrarDesistencia({
    required String torneioId,
    required String jogadorUid,
  }) async {
    final torneioRef = _firestore.collection('tournaments').doc(torneioId);
    final snapshot = await torneioRef.get();
    if (!snapshot.exists) throw StateError('Torneio não encontrado.');
    final torneio = TorneioModel.fromMap(torneioId, snapshot.data()!);
    if (torneio.status != 'em_andamento') throw StateError('Torneio não está em andamento.');
    final rodada = await torneioRef.collection('rounds')
        .doc('${torneio.rodadaAtual}').get();
    if (rodada.data()?['status'] != 'finalizada') {
      throw StateError('Finalize a rodada atual antes de registrar uma desistência.');
    }
    await torneioRef.collection('players').doc(jogadorUid).update({
      'ativo': false,
      'rodadaDesistencia': torneio.rodadaAtual,
      'desistiuEm': Timestamp.now(),
    });
  }

  Stream<List<JogadorTorneioModel>>
      listarJogadores(
    String torneioId,
  ) {
    return _firestore
        .collection('tournaments')
        .doc(torneioId)
        .collection('players')
        .snapshots()
        .map(
          (snapshot) {
            final jogadores = snapshot.docs
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
          },
        );
  }

  Future<void> atualizarStatusJogador({
  required String torneioId,
  required String jogadorUid,
  required String status,
}) async {
  await _firestore
      .collection('tournaments')
      .doc(torneioId)
      .collection('players')
      .doc(jogadorUid)
      .update({
        'status': status,
      });
}

Future<void> aprovarJogador({
  required String torneioId,
  required String jogadorUid,
}) async {
  await atualizarStatusJogador(
    torneioId: torneioId,
    jogadorUid: jogadorUid,
    status: 'aprovado',
  );
}

Future<void> recusarJogador({
  required String torneioId,
  required String jogadorUid,
}) async {
  await atualizarStatusJogador(
    torneioId: torneioId,
    jogadorUid: jogadorUid,
    status: 'recusado',
  );
}


Stream<List<TorneioJogadorModel>> listarTorneiosDoJogador(
  String uid,
) async* {
  await for (final snapshot in _firestore
      .collection('tournaments')
      .snapshots()) {
    final List<TorneioJogadorModel> resultado = [];

    for (final torneioDoc in snapshot.docs) {
      try {
        final jogadorDoc = await torneioDoc.reference
            .collection('players')
            .doc(uid)
            .get();

        if (!jogadorDoc.exists) {
          continue;
        }

        final dadosJogador = jogadorDoc.data();

        if (dadosJogador == null) {
          continue;
        }

        final torneio = TorneioModel.fromMap(
          torneioDoc.id,
          torneioDoc.data(),
        );

        resultado.add(
          TorneioJogadorModel(
            torneio: torneio,
            status: dadosJogador['status'] ?? 'pendente',
            pontos: (dadosJogador['pontos'] as num?)?.toInt() ?? 0,
            ativo: dadosJogador['ativo'] ?? true,
          ),
        );
      } catch (e, stackTrace) {
        debugPrint(
          'Erro ao carregar participação no torneio '
          '${torneioDoc.id}: $e',
        );
        debugPrint('$stackTrace');
        rethrow;
      }
    }

    resultado.sort(
      (a, b) => a.torneio.dataHora.compareTo(
        b.torneio.dataHora,
      ),
    );

    yield resultado;
  }
}
}