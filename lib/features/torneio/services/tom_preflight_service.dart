import 'package:cloud_firestore/cloud_firestore.dart';
import '../../jogador/models/jogador_torneio_model.dart';
import '../../jogador/service/jogador_perfil_tom_service.dart';
import '../../partida/models/partida_model.dart';
import '../models/torneio_model.dart';
import '../rules/pokemon_rulebook.dart';

/// Faz a conferência de dados; o serializador TDF é experimental e
/// depende de validação com o software TOM oficial.
class TomPreflightResult {
  final List<String> erros;
  final List<String> avisos;
  final Map<String, dynamic> snapshot;
  const TomPreflightResult(this.erros, this.avisos, this.snapshot);
  bool get dadosCompletos => erros.isEmpty;
  bool get exportacaoTdfHomologada => false;
}

class TomPreflightService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<TomPreflightResult> validar(String torneioId) async {
    final erros = <String>[];
    final avisos = <String>[];
    final ref = _db.collection('tournaments').doc(torneioId);
    final doc = await ref.get();
    if (!doc.exists) {
      return TomPreflightResult(['Torneio não encontrado.'], [], {});
    }
    final torneio = TorneioModel.fromMap(torneioId, doc.data()!);
    final oficial = PokemonRulebook.eventoSancionado(torneio.tipoEvento);
    if (torneio.status != 'finalizado') {
      avisos.add('O torneio ainda não foi finalizado. O Play! Tools pode rejeitar eventos em andamento.');
    }
    if (oficial && (torneio.sanctionId == null || torneio.sanctionId!.isEmpty)) {
      erros.add('Sanction ID não informado.');
    }
    if (torneio.organizadorNome.trim().isEmpty) {
      erros.add('Nome do organizador não informado.');
    }
    if (oficial && PokemonRulebook.validarIdentificador(torneio.organizadorPlayerId) != null) {
      erros.add('Player ID do organizador não informado ou inválido.');
    }
    if (torneio.versaoRegras == 'legacy') {
      avisos.add('Torneio antigo: conferir metadados de temporada e versão das regras.');
    }
    final jogadoresDocs = await ref.collection('players')
        .where('status', isEqualTo: 'aprovado').get();
    final perfilService = JogadorPerfilTomService(firestore: _db);
    final jogadores = await perfilService.resolverTodos(
      jogadores: [for (final doc in jogadoresDocs.docs)
        JogadorTorneioModel.fromMap(doc.id, doc.data())],
      temporada: torneio.temporada,
      avisos: avisos,
    );
    if (jogadores.isEmpty) erros.add('Nenhum jogador aprovado.');
    if (oficial && jogadores.length < 4) {
      erros.add('Evento sancionado com menos de quatro jogadores aprovados.');
    }
    if (torneio.tipoEvento == 'league_challenge') {
      if (torneio.tamanhoTopCut != 0) {
        erros.add('Desafio de Liga deve utilizar apenas Swiss, sem Top Cut.');
      }
      final referencia = PokemonRulebook.rodadasSwissOnlySugeridas(jogadores.length);
      if (referencia != null && torneio.quantidadeRodadas != referencia) {
        avisos.add('Confira a quantidade de rodadas: a referência Swiss Only para '
            '${jogadores.length} inscritos é $referencia rodadas; '
            'em pods separados ou divisões modificadas a regra pode mudar.');
      }
    }
    if (torneio.tipoEvento == 'league_cup' && torneio.tamanhoTopCut == 0) {
      avisos.add('Copa de Liga: confira no regulamento vigente se há Top Cut obrigatório '
          'para cada divisão. A configuração atual não prevê eliminação.');
    }
    if (torneio.agrupamentoEtario == 'combinado' && oficial) {
      avisos.add('Swiss combinado: a preferência de pareamento por divisão etária '
          'em grupos modificados ainda requer homologação no TOM.');
    }
    final ids = <String>{};
    for (final j in jogadores) {
      if (!j.possuiDadosOficiais) {
        erros.add('Dados oficiais incompletos: ${j.nome}.');
      }
      final id = j.pokemonPlayerId;
      if (id != null && !ids.add(id)) {
        erros.add('Player ID duplicado: $id.');
      }
      if (j.dataNascimento != null) {
        try {
          final esperado = PokemonRulebook.divisaoEtaria(j.dataNascimento!, torneio.temporada);
          if (j.divisaoEtaria != esperado) {
            erros.add('Divisão etária inconsistente: ${j.nome}.');
          }
        } on StateError {
          erros.add('Temporada ${torneio.temporada} não configurada.');
        }
      }
    }
    final rodadas = <Map<String, dynamic>>[];
    final historico = <String>{};
    for (var numero = 1; numero <= torneio.rodadaAtual; numero++) {
      final roundDoc = await ref.collection('rounds').doc('$numero').get();
      if (!roundDoc.exists) {
        erros.add('Rodada $numero ausente.');
        continue;
      }
      final dados = roundDoc.data()!;
      final fase = dados['fase'] as String? ??
          (numero > torneio.quantidadeRodadas ? 'topcut' : 'swiss');
      final partidasDocs = await roundDoc.reference.collection('matches').get();
      final partidas = partidasDocs.docs
          .map((d) => PartidaModel.fromMap(d.id, d.data())).toList();
      if (partidas.isEmpty) erros.add('Rodada $numero sem partidas.');
      final jogadoresDaRodada = <String>{};
      final mesas = <int>{};
      for (final partida in partidas) {
        if (partida.status != 'finalizada' || !partida.resultadoConcluido) {
          erros.add('Rodada $numero, mesa ${partida.mesa}: resultado pendente.');
        }
        final uid1 = partida.jogador1Uid;
        final uid2 = partida.jogador2Uid;
        if (!jogadoresDaRodada.add(uid1)) erros.add('Jogador repetido na rodada $numero: $uid1.');
        if (uid2 != null && !jogadoresDaRodada.add(uid2)) {
          erros.add('Jogador repetido na rodada $numero: $uid2.');
        }
        if (uid2 != null && uid1 == uid2) erros.add('Partida contra o mesmo jogador na rodada $numero.');
        if (partida.mesa > 0 && !mesas.add(partida.mesa)) {
          erros.add('Número de mesa duplicado na rodada $numero.');
        }
        if (fase == 'swiss' && uid2 != null && !partida.bye) {
          final par = [uid1, uid2]..sort();
          if (!historico.add(par.join(':'))) {
            erros.add('Confronto repetido em Swiss na rodada $numero.');
          }
        }
        if (fase == 'topcut' &&
            (partida.resultado == ResultadoPartida.empate ||
             partida.resultado == ResultadoPartida.derrotaDupla)) {
          erros.add('Top Cut sem vencedor na rodada $numero.');
        }
      }
      rodadas.add({
        'numero': numero, 'fase': fase, 'status': dados['status'],
        'partidas': [for (final p in partidas) p.toMap()],
      });
    }
    // Modelo neutro: não é um XML .tdf e não se passa por um arquivo oficial.
    final snapshot = <String, dynamic>{
      'torneio': torneio.toMap(),
      'jogadores': [for (final j in jogadores) j.toMap()],
      'rodadas': rodadas,
    };
    avisos.add('Exportação .tdf experimental disponível. Valide o arquivo no TOM; o Play! Tools exige conclusão no software oficial.');
    return TomPreflightResult(erros, avisos, snapshot);
  }
}
