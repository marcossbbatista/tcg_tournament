import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/usuario_model.dart';
import '../../torneio/rules/pokemon_rulebook.dart';
import '../models/jogador_torneio_model.dart';

/// Prioriza o perfil da conta na exportação e na validação TOM.
/// Inscrições presenciais / importadas do TOM preservam os próprios dados.
class JogadorPerfilTomService {
  final FirebaseFirestore _firestore;

  JogadorPerfilTomService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Limita leituras simultâneas para torneios com muitos participantes.
  Future<List<JogadorTorneioModel>> resolverTodos({
    required List<JogadorTorneioModel> jogadores,
    required int temporada,
    List<String>? avisos,
  }) async {
    final resultados = <JogadorTorneioModel>[];
    for (var inicio = 0; inicio < jogadores.length; inicio += 20) {
      final lote = jogadores.skip(inicio).take(20);
      resultados.addAll(await Future.wait(lote.map((jogador) => resolver(
        jogador: jogador,
        temporada: temporada,
        avisos: avisos,
      ))));
    }
    return resultados;
  }

  Future<JogadorTorneioModel> resolver({
    required JogadorTorneioModel jogador,
    required int temporada,
    List<String>? avisos,
  }) async {
    if (jogador.uid.startsWith('pop_')) return jogador;

    DocumentSnapshot<Map<String, dynamic>> perfilDoc;
    try {
      perfilDoc = await _firestore.collection('users').doc(jogador.uid).get();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // A conta de organizador pode não ter permissão para ler perfis de
      // terceiros. Nesse caso, preserva o snapshot feito na inscrição.
      avisos?.add('Sem acesso ao perfil de ${jogador.nome}; '
          'serão usados os dados registrados na inscrição.');
      return jogador;
    }

    if (!perfilDoc.exists || perfilDoc.data() == null) return jogador;

    final perfil = UsuarioModel.fromMap(perfilDoc.id, perfilDoc.data()!);
    String? divisao;
    if (perfil.dataNascimento != null) {
      divisao = PokemonRulebook.divisaoEtaria(
        perfil.dataNascimento!, temporada,
      );
    }

    return JogadorTorneioModel(
      uid: jogador.uid,
      nome: perfil.nome,
      email: jogador.email,
      status: jogador.status,
      pontos: jogador.pontos,
      ativo: jogador.ativo,
      entrouEm: jogador.entrouEm,
      quantidadeByes: jogador.quantidadeByes,
      pokemonPlayerId: perfil.pokemonPlayerId,
      primeiroNome: perfil.primeiroNome,
      sobrenome: perfil.sobrenome,
      dataNascimento: perfil.dataNascimento,
      divisaoEtaria: divisao,
      podId: jogador.podId,
      rodadaDesistencia: jogador.rodadaDesistencia,
      rodadaEntradaTardia: jogador.rodadaEntradaTardia,
    );
  }
}
