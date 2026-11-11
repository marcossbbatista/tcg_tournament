import 'package:xml/xml.dart';

/// XML de referência: TOM 1.70 (TCG), conforme amostra recebida.
/// Não representa um esquema oficial publicado pela Pokémon.
class TomTdfDocumento {
  final Map<String, String> atributos;
  final Map<String, String> dados;
  final List<TomTdfJogador> jogadores;
  final List<TomTdfPod> pods;
  final String timeElapsed;
  final Map<String, String> finalsOptions;
  final List<String> avisos;

  TomTdfDocumento({
    required this.atributos,
    required this.dados,
    required this.jogadores,
    required this.pods,
    this.timeElapsed = '0',
    this.finalsOptions = const {},
    this.avisos = const [],
  });

  int get totalPartidas => pods.fold<int>(0, (total, p) =>
      total + p.rodadas.fold<int>(0, (soma, r) => soma + r.partidas.length));

  int get totalRodadas {
    final numeros = <int>{};
    for (final pod in pods) {
      for (final rodada in pod.rodadas) {
        numeros.add(rodada.numero);
      }
    }
    return numeros.length;
  }
}

class TomTdfJogador {
  final String id;
  final String primeiroNome;
  final String sobrenome;
  final DateTime? nascimento;
  final String starter;
  final String? criadoEm;
  final String? alteradoEm;
  final String? dropStatus;
  final int? dropRodada;
  final String? dropTimestamp;
  final Map<String, String> outrosCampos;

  const TomTdfJogador({
    required this.id,
    required this.primeiroNome,
    required this.sobrenome,
    required this.nascimento,
    this.starter = 'true',
    this.criadoEm,
    this.alteradoEm,
    this.dropStatus,
    this.dropRodada,
    this.dropTimestamp,
    this.outrosCampos = const {},
  });
}

class TomTdfPod {
  final String idInterno;
  final String categoria;
  final String stage;
  final String startingTable;
  final String playoffType;
  final List<TomTdfSubgrupo> subgrupos;
  final List<TomTdfRodada> rodadas;
  final Map<String, int> classificacao;
  final String standingsType;

  const TomTdfPod({
    required this.idInterno,
    required this.categoria,
    required this.stage,
    required this.startingTable,
    required this.playoffType,
    required this.subgrupos,
    required this.rodadas,
    required this.classificacao,
    this.standingsType = 'finished',
  });
}

class TomTdfSubgrupo {
  final String numero;
  final List<String> jogadores;
  const TomTdfSubgrupo(this.numero, this.jogadores);
}

class TomTdfRodada {
  final int numero;
  final String tipo;
  final String stage;
  final List<TomTdfPartida> partidas;
  const TomTdfRodada({
    required this.numero,
    required this.tipo,
    required this.stage,
    required this.partidas,
  });
}

class TomTdfPartida {
  final String outcome;
  final String jogador1;
  final String? jogador2;
  final int mesa;
  final String? timestamp;
  final Map<String, String> outrosCampos;
  const TomTdfPartida({
    required this.outcome,
    required this.jogador1,
    required this.jogador2,
    required this.mesa,
    this.timestamp,
    this.outrosCampos = const {},
  });
}

class TomTdfCodec {
  const TomTdfCodec();

  static const _camposDados = <String>{
    'name', 'id', 'city', 'state', 'country', 'roundtime',
    'finalsroundtime', 'startdate', 'lessswiss', 'autotimestamp', 'status',
  };
  static const _camposJogador = <String>{
    'firstname', 'lastname', 'birthdate', 'starter', 'dropped',
    'creationdate', 'lastmodifieddate',
  };

  TomTdfDocumento importar(String xml) {
    if (xml.length > 5 * 1024 * 1024) {
      throw const FormatException('Arquivo TDF maior que 5 MB.');
    }
    if (RegExp(r'<!\s*(DOCTYPE|ENTITY)', caseSensitive: false).hasMatch(xml)) {
      throw const FormatException('TDF com DTD ou entidades XML não é permitido.');
    }
    late final XmlDocument documento;
    try {
      documento = XmlDocument.parse(xml.replaceFirst('\uFEFF', ''));
    } on XmlException catch (e) {
      throw FormatException('O arquivo não contém XML válido: $e');
    }
    final raiz = documento.rootElement;
    if (raiz.name.local != 'tournament') {
      throw const FormatException('A raiz do arquivo deve ser <tournament>.');
    }
    final atributos = _atributos(raiz);
    if (atributos['gametype'] != 'TRADING_CARD_GAME') {
      throw const FormatException('Este importador aceita apenas torneios TRADING_CARD_GAME.');
    }
    final dataXml = raiz.getElement('data');
    final jogadoresXml = raiz.getElement('players');
    final podsXml = raiz.getElement('pods');
    if (dataXml == null || jogadoresXml == null || podsXml == null) {
      throw const FormatException('TDF sem os blocos obrigatórios data, players ou pods.');
    }
    final dados = <String, String>{};
    for (final campo in dataXml.children.whereType<XmlElement>()) {
      if (campo.name.local == 'organizer') {
        dados['organizerPopid'] = campo.getAttribute('popid') ?? '';
        dados['organizerName'] = campo.getAttribute('name') ?? '';
      } else {
        dados[campo.name.local] = campo.innerText;
      }
    }
    if ((dados['name'] ?? '').trim().isEmpty) {
      throw const FormatException('Nome do torneio não informado.');
    }
    final avisos = <String>[];
    final jogadores = <TomTdfJogador>[];
    final ids = <String>{};
    for (final elemento in jogadoresXml.findElements('player')) {
      final id = (elemento.getAttribute('userid') ?? '').trim();
      if (id.isEmpty || !ids.add(id)) {
        throw FormatException('Player ID ausente ou duplicado: $id.');
      }
      final drop = elemento.getElement('dropped');
      final extras = <String, String>{};
      for (final filho in elemento.children.whereType<XmlElement>()) {
        if (!_camposJogador.contains(filho.name.local)) {
          extras[filho.name.local] = filho.innerText;
          avisos.add('Campo de jogador não padronizado: ${filho.name.local}.');
        }
      }
      final nascimentoTexto = _texto(elemento, 'birthdate');
      jogadores.add(TomTdfJogador(
        id: id,
        primeiroNome: _texto(elemento, 'firstname'),
        sobrenome: _texto(elemento, 'lastname'),
        nascimento: nascimentoTexto.isEmpty ? null : _lerData(nascimentoTexto),
        starter: _texto(elemento, 'starter', padrao: 'true'),
        criadoEm: _textoOpcional(elemento, 'creationdate'),
        alteradoEm: _textoOpcional(elemento, 'lastmodifieddate'),
        dropStatus: drop == null ? null : _texto(drop, 'status', padrao: '1'),
        dropRodada: drop == null ? null : int.tryParse(_texto(drop, 'round')),
        dropTimestamp: drop == null ? null : _textoOpcional(drop, 'timestamp'),
        outrosCampos: extras,
      ));
    }
    if (jogadores.isEmpty) throw const FormatException('Nenhum jogador no TDF.');
    final pods = <TomTdfPod>[];
    for (final elemento in podsXml.findElements('pod')) {
      final podId = 'tom_pod_${pods.length + 1}';
      final podData = elemento.getElement('poddata');
      if (podData == null) throw FormatException('Pod $podId sem poddata.');
      final subgrupos = <TomTdfSubgrupo>[];
      final inscritosPod = <String>{};
      for (final sub in podData.getElement('subgroups')?.findElements('subgroup') ?? <XmlElement>[]) {
        final lista = <String>[];
        for (final p in sub.getElement('players')?.findElements('player') ?? <XmlElement>[]) {
          final id = p.getAttribute('userid') ?? '';
          if (!ids.contains(id) || !inscritosPod.add(id)) {
            throw FormatException('Jogador inválido ou repetido no pod $podId: $id.');
          }
          lista.add(id);
        }
        subgrupos.add(TomTdfSubgrupo(sub.getAttribute('number') ?? '1', lista));
      }
      final rodadas = <TomTdfRodada>[];
      final numeros = <int>{};
      for (final rodada in elemento.getElement('rounds')?.findElements('round') ?? <XmlElement>[]) {
        final numero = int.tryParse(rodada.getAttribute('number') ?? '') ?? 0;
        if (numero < 1 || !numeros.add(numero)) {
          throw FormatException('Rodada ausente ou duplicada no pod $podId.');
        }
        if (rodada.getAttribute('type') != '2') {
          avisos.add('Tipo de rodada TOM ${rodada.getAttribute('type')} não homologado; será preservado.');
        }
        final partidas = <TomTdfPartida>[];
        final usadosNaRodada = <String>{};
        for (final match in rodada.getElement('matches')?.findElements('match') ?? <XmlElement>[]) {
          final j1 = match.getElement('player1')?.getAttribute('userid') ?? '';
          final j2 = match.getElement('player2')?.getAttribute('userid');
          if (!ids.contains(j1) || !usadosNaRodada.add(j1) ||
              (j2 != null && (!ids.contains(j2) || j1 == j2 || !usadosNaRodada.add(j2)))) {
            throw FormatException('Partida com jogadores inválidos na rodada $numero ($podId).');
          }
          final codigo = match.getAttribute('outcome') ?? '0';
          if (!RegExp(r'^\d+$').hasMatch(codigo)) {
            throw FormatException('Código de resultado inválido: $codigo.');
          }
          if (!{'0', '1', '2', '3', '10'}.contains(codigo)) {
            avisos.add('Resultado TOM $codigo preservado, mas sem interpretação confirmada.');
          }
          final extras = <String, String>{};
          for (final filho in match.children.whereType<XmlElement>()) {
            if (!{'player1', 'player2', 'timestamp', 'tablenumber'}.contains(filho.name.local)) {
              extras[filho.name.local] = filho.innerText;
              avisos.add('Campo de partida não padronizado: ${filho.name.local}.');
            }
          }
          partidas.add(TomTdfPartida(
            outcome: codigo,
            jogador1: j1,
            jogador2: j2,
            mesa: int.tryParse(_texto(match, 'tablenumber')) ?? 0,
            timestamp: _textoOpcional(match, 'timestamp'),
            outrosCampos: extras,
          ));
        }
        rodadas.add(TomTdfRodada(
          numero: numero,
          tipo: rodada.getAttribute('type') ?? '2',
          stage: rodada.getAttribute('stage') ?? (elemento.getAttribute('stage') ?? '5'),
          partidas: partidas,
        ));
      }
      final colocacoes = <String, int>{};
      final standingsXml = elemento.getElement('standings')?.getElement('pod');
      for (final linha in standingsXml?.findElements('player') ?? <XmlElement>[]) {
        final id = linha.getAttribute('id') ?? '';
        final lugar = int.tryParse(linha.getAttribute('place') ?? '');
        if (ids.contains(id) && lugar != null && lugar > 0) colocacoes[id] = lugar;
      }
      pods.add(TomTdfPod(
        idInterno: podId,
        categoria: elemento.getAttribute('category') ?? '2',
        stage: elemento.getAttribute('stage') ?? '5',
        startingTable: _texto(podData, 'startingtable', padrao: '1'),
        playoffType: _texto(podData, 'playofftype', padrao: '0'),
        subgrupos: subgrupos,
        rodadas: rodadas,
        classificacao: colocacoes,
        standingsType: standingsXml?.getAttribute('type') ?? 'ongoing',
      ));
      for (final filho in elemento.children.whereType<XmlElement>()) {
        if (!{'poddata', 'rounds', 'standings'}.contains(filho.name.local)) {
          avisos.add('Bloco TOM não suportado no pod $podId: ${filho.name.local}.');
        }
      }
    }
    if (pods.isEmpty) throw const FormatException('O arquivo não possui pods.');
    for (final jogador in jogadores) {
      final inclusoes = pods.expand((p) => p.subgrupos).where((s) => s.jogadores.contains(jogador.id)).length;
      if (inclusoes != 1) {
        throw FormatException('O jogador ${jogador.id} deve pertencer a exatamente um subgrupo.');
      }
    }
    for (final pod in pods) {
      final membros = pod.subgrupos.expand((s) => s.jogadores).toSet();
      for (final rodada in pod.rodadas) {
        for (final partida in rodada.partidas) {
          if (!membros.contains(partida.jogador1) ||
              (partida.jogador2 != null && !membros.contains(partida.jogador2))) {
            throw FormatException('Partida da rodada ${rodada.numero} fora do pod ${pod.idInterno}.');
          }
        }
      }
    }
    final finals = raiz.getElement('finalsoptions');
    if (finals != null && finals.children.whereType<XmlElement>().isNotEmpty) {
      avisos.add('finalsoptions contém elementos extras não interpretados; revise antes de reexportar.');
    }
    for (final filho in raiz.children.whereType<XmlElement>()) {
      if (!{'data', 'timeelapsed', 'players', 'pods', 'finalsoptions'}.contains(filho.name.local)) {
        avisos.add('Bloco desconhecido no TDF: ${filho.name.local} (não será reexportado).');
      }
    }
    return TomTdfDocumento(
      atributos: atributos,
      dados: dados,
      jogadores: jogadores,
      pods: pods,
      timeElapsed: _texto(raiz, 'timeelapsed', padrao: '0'),
      finalsOptions: finals == null ? {} : _atributos(finals),
      avisos: avisos,
    );
  }

  String exportar(TomTdfDocumento documento) {
    if (documento.jogadores.isEmpty || documento.pods.isEmpty) {
      throw const FormatException('O torneio precisa de jogadores e pods para gerar o TDF.');
    }
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('tournament', attributes: documento.atributos, nest: () {
      builder.element('data', nest: () {
        _campo(builder, 'name', documento.dados['name'] ?? '');
        _campo(builder, 'id', documento.dados['id'] ?? '');
        for (final nome in ['city', 'state', 'country', 'roundtime', 'finalsroundtime']) {
          _campo(builder, nome, documento.dados[nome] ?? '');
        }
        builder.element('organizer', attributes: {
          'popid': documento.dados['organizerPopid'] ?? '',
          'name': documento.dados['organizerName'] ?? '',
        });
        for (final nome in ['startdate', 'lessswiss', 'autotimestamp', 'status']) {
          _campo(builder, nome, documento.dados[nome] ?? '');
        }
        for (final entrada in documento.dados.entries) {
          if (!_camposDados.contains(entrada.key) &&
              entrada.key != 'organizerPopid' && entrada.key != 'organizerName') {
            _campo(builder, entrada.key, entrada.value);
          }
        }
      });
      _campo(builder, 'timeelapsed', documento.timeElapsed);
      builder.element('players', nest: () {
        for (final j in documento.jogadores) {
          builder.element('player', attributes: {'userid': j.id}, nest: () {
            _campo(builder, 'firstname', j.primeiroNome);
            _campo(builder, 'lastname', j.sobrenome);
            if (j.nascimento != null) _campo(builder, 'birthdate', formatarData(j.nascimento!));
            _campo(builder, 'starter', j.starter);
            if (j.dropStatus != null) {
              builder.element('dropped', nest: () {
                _campo(builder, 'status', j.dropStatus!);
                if (j.dropRodada != null) _campo(builder, 'round', '${j.dropRodada}');
                if (j.dropTimestamp != null) _campo(builder, 'timestamp', j.dropTimestamp!);
              });
            }
            if (j.criadoEm != null) _campo(builder, 'creationdate', j.criadoEm!);
            if (j.alteradoEm != null) _campo(builder, 'lastmodifieddate', j.alteradoEm!);
            for (final extra in j.outrosCampos.entries) {
              _campo(builder, extra.key, extra.value);
            }
          });
        }
      });
      builder.element('pods', nest: () {
        for (final p in documento.pods) {
          builder.element('pod', attributes: {'category': p.categoria, 'stage': p.stage}, nest: () {
            builder.element('poddata', nest: () {
              _campo(builder, 'startingtable', p.startingTable);
              _campo(builder, 'playofftype', p.playoffType);
              builder.element('subgroups', nest: () {
                for (final subgroup in p.subgrupos) {
                  builder.element('subgroup', attributes: {'number': subgroup.numero}, nest: () {
                    builder.element('players', nest: () {
                      for (final id in subgroup.jogadores) {
                        builder.element('player', attributes: {'userid': id});
                      }
                    });
                  });
                }
              });
            });
            builder.element('rounds', nest: () {
              for (final r in p.rodadas) {
                builder.element('round', attributes: {
                  'number': '${r.numero}', 'type': r.tipo, 'stage': r.stage,
                }, nest: () {
                  builder.element('matches', nest: () {
                    for (final m in r.partidas) {
                      builder.element('match', attributes: {'outcome': m.outcome}, nest: () {
                        builder.element('player1', attributes: {'userid': m.jogador1});
                        if (m.jogador2 != null) {
                          builder.element('player2', attributes: {'userid': m.jogador2!});
                        }
                        if (m.timestamp != null) _campo(builder, 'timestamp', m.timestamp!);
                        _campo(builder, 'tablenumber', '${m.mesa}');
                        for (final extra in m.outrosCampos.entries) {
                          _campo(builder, extra.key, extra.value);
                        }
                      });
                    }
                  });
                });
              }
            });
            builder.element('standings', nest: () {
              builder.element('pod', attributes: {
                'category': p.categoria, 'type': p.standingsType,
              }, nest: () {
                final ranking = p.classificacao.entries.toList()
                  ..sort((a, b) => a.value.compareTo(b.value));
                for (final linha in ranking) {
                  builder.element('player', attributes: {
                    'id': linha.key, 'place': '${linha.value}',
                  });
                }
              });
            });
          });
        }
      });
      builder.element('finalsoptions', attributes: documento.finalsOptions);
    });
    return '${builder.buildDocument().toXmlString(pretty: true, indent: '\t')}\n';
  }

  static void _campo(XmlBuilder builder, String nome, String texto) {
    builder.element(nome, nest: texto);
  }

  static Map<String, String> _atributos(XmlElement elemento) => {
    for (final atributo in elemento.attributes)
      atributo.name.local: atributo.value,
  };

  static String _texto(XmlElement elemento, String nome, {String padrao = ''}) =>
      elemento.getElement(nome)?.innerText.trim() ?? padrao;

  static String? _textoOpcional(XmlElement elemento, String nome) {
    final valor = _texto(elemento, nome);
    return valor.isEmpty ? null : valor;
  }

  static DateTime _lerData(String texto) {
    final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(texto.trim());
    if (match == null) throw FormatException('Data TOM inválida: $texto (esperado MM/DD/YYYY).');
    final mes = int.parse(match.group(1)!);
    final dia = int.parse(match.group(2)!);
    final ano = int.parse(match.group(3)!);
    final data = DateTime(ano, mes, dia);
    if (data.year != ano || data.month != mes || data.day != dia) {
      throw FormatException('Data TOM inexistente: $texto.');
    }
    return data;
  }

  static DateTime lerData(String texto) => _lerData(texto);

  static String formatarData(DateTime data) =>
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.day.toString().padLeft(2, '0')}/${data.year}';

  static String formatarDataHora(DateTime data) =>
      '${formatarData(data)} ${data.hour.toString().padLeft(2, '0')}:'
      '${data.minute.toString().padLeft(2, '0')}:'
      '${data.second.toString().padLeft(2, '0')}';
}
