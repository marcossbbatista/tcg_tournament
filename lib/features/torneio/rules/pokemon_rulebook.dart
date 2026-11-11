/// Configuração versionada das divisões etárias Play! Pokémon.
/// Fonte temporada 2027: https://championships.pokemon.com/pt-br/about/2027-season-changes
/// Conferir alterações oficiais a cada temporada antes de criar novos eventos.
class PokemonRulebook {
  const PokemonRulebook._();

  static const int temporadaAtual = 2027;
  static const double pisoWinPercentage = 0.25;
  static const double tetoDropWinPercentage = 0.75;

  static const Map<int, AgeDivisionRule> _temporadas = {
    2026: AgeDivisionRule(juniorFrom: 2014, seniorFrom: 2010),
    2027: AgeDivisionRule(juniorFrom: 2015, seniorFrom: 2011),
  };

  static String divisaoEtaria(DateTime nascimento, int temporada) {
    final regras = _temporadas[temporada];
    if (regras == null) {
      throw StateError('Temporada $temporada sem configuração etária oficial.');
    }
    if (nascimento.year > temporada || nascimento.year < 1900) {
      throw ArgumentError('Data de nascimento inválida.');
    }
    if (nascimento.year >= regras.juniorFrom) return 'junior';
    if (nascimento.year >= regras.seniorFrom) return 'senior';
    return 'masters';
  }

  static int? temporadaPorData(DateTime data) {
    // A temporada 2027 iniciou em setembro de 2026.
    // Para outras temporadas, confirmar o calendário oficial.
    if (data.year == 2026 && data.month >= 9) return 2027;
    if (data.year == 2027 && data.month <= 8) return 2027;
    if (data.year == 2025 && data.month >= 9) return 2026;
    if (data.year == 2026 && data.month <= 8) return 2026;
    return null;
  }

  /// Quantidade de rodadas Swiss de referência para o modelo TCG Swiss Only.
  /// A validação oficial deve considerar o tipo de evento, presença por
  /// divisão/pod e a edição vigente do Tournament Rules Handbook.
  static int? rodadasSwissOnlySugeridas(int participantes) {
    if (participantes < 4) return null;
    if (participantes <= 8) return 3;
    if (participantes <= 16) return 4;
    if (participantes <= 32) return 5;
    if (participantes <= 64) return 6;
    if (participantes <= 128) return 7;
    if (participantes <= 256) return 8;
    if (participantes <= 512) return 9;
    return 10;
  }

  static bool get isTemporadaAtualConfigurada => _temporadas.containsKey(temporadaAtual);

  static bool eventoSancionado(String tipoEvento) =>
      tipoEvento == 'league_challenge' || tipoEvento == 'league_cup';

  static String? validarIdentificador(String? pokemonId) {
    if (pokemonId == null || pokemonId.trim().isEmpty) return 'Informe o Player ID.';
    if (!RegExp(r'^\d{5,12}$').hasMatch(pokemonId.trim())) {
      return 'O Player ID deve conter apenas números (5 a 12 dígitos).';
    }
    return null;
  }
}

class AgeDivisionRule {
  final int juniorFrom;
  final int seniorFrom;

  const AgeDivisionRule({required this.juniorFrom, required this.seniorFrom});
}
