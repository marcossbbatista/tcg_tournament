import 'package:cloud_firestore/cloud_firestore.dart';
import '../rules/pokemon_rulebook.dart';

class TorneioModel {
  final String id;
  final String nome;
  final String codigo;
  final DateTime dataHora;
  /// Formato de partida: md1 ou md3 (mantido para telas existentes).
  final String formato;
  final int quantidadeRodadas;
  final int rodadaAtual;
  final String status;
  final String criadoPor;
  final DateTime criadoEm;

  // Metadados do evento oficial, mantidos separadamente do código interno.
  final String? sanctionId;
  final String organizadorNome;
  final String? organizadorPlayerId;
  final String tipoEvento;
  final String formatoJogo;
  final String sistemaPareamento;
  final int temporada;
  final String agrupamentoEtario;
  final int tamanhoTopCut;
  final String versaoRegras;
  final bool topcutConcluido;

  TorneioModel({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.dataHora,
    required this.formato,
    required this.quantidadeRodadas,
    required this.rodadaAtual,
    required this.status,
    required this.criadoPor,
    required this.criadoEm,
    this.sanctionId,
    this.organizadorNome = '',
    this.organizadorPlayerId,
    this.tipoEvento = 'custom',
    this.formatoJogo = 'standard',
    this.sistemaPareamento = 'swiss',
    this.temporada = PokemonRulebook.temporadaAtual,
    this.agrupamentoEtario = 'combinado',
    this.tamanhoTopCut = 0,
    this.versaoRegras = 'play-pokemon-2027',
    this.topcutConcluido = false,
  });

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'codigo': codigo,
        'dataHora': Timestamp.fromDate(dataHora),
        'formato': formato,
        'quantidadeRodadas': quantidadeRodadas,
        'rodadaAtual': rodadaAtual,
        'status': status,
        'criadoPor': criadoPor,
        'criadoEm': Timestamp.fromDate(criadoEm),
        'sanctionId': sanctionId,
        'organizadorNome': organizadorNome,
        'organizadorPlayerId': organizadorPlayerId,
        'tipoEvento': tipoEvento,
        'formatoJogo': formatoJogo,
        'sistemaPareamento': sistemaPareamento,
        'temporada': temporada,
        'agrupamentoEtario': agrupamentoEtario,
        'tamanhoTopCut': tamanhoTopCut,
        'versaoRegras': versaoRegras,
        'topcutConcluido': topcutConcluido,
      };

  factory TorneioModel.fromMap(String id, Map<String, dynamic> map) => TorneioModel(
        id: id,
        nome: map['nome'] as String? ?? '',
        codigo: map['codigo'] as String? ?? '',
        dataHora: (map['dataHora'] as Timestamp?)?.toDate() ?? DateTime.now(),
        formato: map['formato'] as String? ?? 'md3',
        quantidadeRodadas: (map['quantidadeRodadas'] as num?)?.toInt() ?? 0,
        rodadaAtual: (map['rodadaAtual'] as num?)?.toInt() ?? 0,
        status: map['status'] as String? ?? 'inscricoes',
        criadoPor: map['criadoPor'] as String? ?? '',
        criadoEm: (map['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
        sanctionId: map['sanctionId'] as String?,
        organizadorNome: map['organizadorNome'] as String? ?? '',
        organizadorPlayerId: map['organizadorPlayerId'] as String?,
        tipoEvento: map['tipoEvento'] as String? ?? 'custom',
        formatoJogo: map['formatoJogo'] as String? ?? 'standard',
        sistemaPareamento: map['sistemaPareamento'] as String? ?? 'swiss',
        temporada: (map['temporada'] as num?)?.toInt() ?? PokemonRulebook.temporadaAtual,
        agrupamentoEtario: map['agrupamentoEtario'] as String? ?? 'combinado',
        tamanhoTopCut: (map['tamanhoTopCut'] as num?)?.toInt() ?? 0,
        versaoRegras: map['versaoRegras'] as String? ?? 'legacy',
        topcutConcluido: map['topcutConcluido'] as bool? ?? false,
      );
}
