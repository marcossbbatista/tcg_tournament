import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../torneio/rules/pokemon_rulebook.dart';
import '../models/usuario_model.dart';

class UsuarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UsuarioModel?> buscarUsuario(String uid) async {
    final documento = await _firestore
        .collection('users')
        .doc(uid)
        .get();

    if (!documento.exists || documento.data() == null) {
      return null;
    }

    return UsuarioModel.fromMap(
      documento.id,
      documento.data()!,
    );
  }

  Future<UsuarioModel> buscarOuCriarUsuarioGoogle(
    User usuarioFirebase,
  ) async {
    final usuarioRef = _firestore
        .collection('users')
        .doc(usuarioFirebase.uid);

    return await _firestore.runTransaction<UsuarioModel>(
      (transaction) async {
        final documento = await transaction.get(usuarioRef);

        // Preserva os dados e o tipo de usuários já cadastrados.
        if (documento.exists && documento.data() != null) {
          return UsuarioModel.fromMap(
            documento.id,
            documento.data()!,
          );
        }

        // Usuários Google completam o Player ID e nascimento em Meu perfil.
        final novoUsuario = UsuarioModel(
          uid: usuarioFirebase.uid,
          nome: usuarioFirebase.displayName?.trim().isNotEmpty == true
              ? usuarioFirebase.displayName!.trim()
              : 'Jogador',
          email: usuarioFirebase.email ?? '',
          tipo: 'jogador',
        );

        transaction.set(usuarioRef, novoUsuario.toMap());

        return novoUsuario;
      },
    );
  }

  Future<void> criarUsuario(UsuarioModel usuario) async {
    await _firestore
        .collection('users')
        .doc(usuario.uid)
        .set(usuario.toMap());
  }

  /// Atualiza os snapshots das inscrições já existentes para que o TOM
  /// continue usando os dados atuais quando o organizador não puder ler
  /// diretamente o documento users do jogador.
  Future<void> sincronizarInscricoes(UsuarioModel usuario) async {
    final autenticado = FirebaseAuth.instance.currentUser;
    if (autenticado == null || autenticado.uid != usuario.uid) {
      throw StateError('Sessão inválida para sincronizar inscrições.');
    }
    if (!usuario.possuiDadosOficiais) return;

    final torneios = await _firestore.collection('tournaments').get();
    for (var indice = 0; indice < torneios.docs.length; indice += 20) {
      final lote = torneios.docs.skip(indice).take(20).toList();
      final inscricoes = await Future.wait(lote.map((torneio) =>
          torneio.reference.collection('players').doc(usuario.uid).get()));
      final atualizacoes = <Future<void>>[];
      for (var posicao = 0; posicao < lote.length; posicao++) {
        final inscricao = inscricoes[posicao];
        if (!inscricao.exists) continue;

        // Preserva o status, resultados, desistências e demais dados do torneio.
        // Em torneios de temporadas antigas a divisão depende da regra vigente.
        final temporada = (lote[posicao].data()['temporada'] as num?)?.toInt()
            ?? PokemonRulebook.temporadaAtual;
        String? divisao;
        try {
          divisao = PokemonRulebook.divisaoEtaria(
            usuario.dataNascimento!, temporada,
          );
        } on StateError {
          // Não altera a divisão original se a temporada não estiver mapeada.
        }
        atualizacoes.add(inscricao.reference.update({
          'nome': usuario.nome,
          'primeiroNome': usuario.primeiroNome,
          'sobrenome': usuario.sobrenome,
          'pokemonPlayerId': usuario.pokemonPlayerId,
          'dataNascimento': Timestamp.fromDate(usuario.dataNascimento!),
          if (divisao != null) 'divisaoEtaria': divisao,
        }));
      }
      await Future.wait(atualizacoes);
    }
  }

  /// Edita somente dados de perfil: nunca modifica e-mail ou permissões.
  Future<UsuarioModel> atualizarPerfil({
    required UsuarioModel usuarioAtual,
    required String primeiroNome,
    required String sobrenome,
    required String pokemonPlayerId,
    required DateTime dataNascimento,
  }) async {
    final autenticado = FirebaseAuth.instance.currentUser;
    if (autenticado == null || autenticado.uid != usuarioAtual.uid) {
      throw StateError('Sessão inválida para alterar o perfil.');
    }

    if (primeiroNome.trim().isEmpty || sobrenome.trim().isEmpty) {
      throw ArgumentError('Informe o primeiro nome e o sobrenome.');
    }
    final erroId = PokemonRulebook.validarIdentificador(pokemonPlayerId);
    if (erroId != null) throw ArgumentError(erroId);
    if (dataNascimento.isAfter(DateTime.now()) || dataNascimento.year < 1920) {
      throw ArgumentError('Informe uma data de nascimento válida.');
    }

    final atualizado = usuarioAtual.copiarComDadosOficiais(
      primeiroNome: primeiroNome,
      sobrenome: sobrenome,
      pokemonPlayerId: pokemonPlayerId,
      dataNascimento: dataNascimento,
    );

    await _firestore.collection('users').doc(usuarioAtual.uid).update({
      'nome': atualizado.nome,
      'primeiroNome': atualizado.primeiroNome,
      'sobrenome': atualizado.sobrenome,
      'pokemonPlayerId': atualizado.pokemonPlayerId,
      'dataNascimento': Timestamp.fromDate(dataNascimento),
    });

    // O Firestore é a fonte oficial dos dados; falha no nome do Auth não
    // deve reverter uma atualização de perfil que já foi salva.
    try {
      await autenticado.updateDisplayName(atualizado.nome);
    } on FirebaseAuthException {
      // O nome usado no aplicativo continua vindo do Firestore.
    }

    return atualizado;
  }
}
