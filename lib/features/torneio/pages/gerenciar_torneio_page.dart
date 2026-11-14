import 'package:tcg_tournament/core/theme/tcg_theme.dart';
import 'package:flutter/material.dart';
import 'package:tcg_tournament/features/jogador/service/jogador_torneio_service.dart';

import '../models/torneio_model.dart';
import '../services/torneio_service.dart';

import '../../jogador/models/jogador_torneio_model.dart';
import '../../jogador/pages/gerenciar_jogadores_page.dart';

import '../../partida/pages/montar_primeira_rodada_page.dart';
import '../../partida/pages/gerenciar_rodada_page.dart';
import '../../partida/services/rodada_service.dart';
import '../../partida/services/topcut_service.dart';

import 'classificacao_page.dart';
import 'tom_preflight_page.dart';
import 'tom_tdf_page.dart';
import 'tom_tdf_metadata_page.dart';

class GerenciarTorneioPage extends StatelessWidget {
  final TorneioModel torneio;

  const GerenciarTorneioPage({super.key, required this.torneio});

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  String _formatarHorario(DateTime data) {
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  String _formatarStatus(String status) {
    switch (status) {
      case 'inscricoes':
        return 'Inscrições abertas';

      case 'em_andamento':
        return 'Em andamento';

      case 'finalizado':
        return 'Finalizado';

      default:
        return status;
    }
  }

  Future<void> _iniciarTorneio(
    BuildContext context,
    TorneioModel torneioAtual,
  ) async {
    try {
      final resultado = await RodadaService().iniciarTorneio(
        torneioId: torneioAtual.id,
      );

      if (!context.mounted) return;

      if (resultado == 'jogadores_insuficientes') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('São necessários pelo menos 2 jogadores aprovados.'),
          ),
        );

        return;
      }

      if (resultado != 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível iniciar o torneio.')),
        );

        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MontarPrimeiraRodadaPage(
            torneioId: torneioAtual.id,
            nomeTorneio: torneioAtual.nome,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível iniciar o torneio.')),
      );
    }
  }

  void _abrirClassificacao(
    BuildContext context,
    TorneioModel torneioAtual, {
    bool classificacaoFinal = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassificacaoPage(
          torneioId: torneioAtual.id,
          nomeTorneio: torneioAtual.nome,
          classificacaoFinal: classificacaoFinal,
        ),
      ),
    );
  }

  /// Estrutura padrão: fundo + seta fixa no topo + área central.
  Widget _estrutura(BuildContext context, Widget child) {
    return TcgTheme.wrap(
      Scaffold(
        backgroundColor: TcgTheme.fundo,
        body: TcgBackground(
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TorneioService torneioService = TorneioService();

    return StreamBuilder<TorneioModel?>(
      stream: torneioService.observarTorneio(torneio.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _estrutura(
            context,
            const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _estrutura(
            context,
            const Center(
              child: Text(
                'Não foi possível carregar o torneio.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final torneioAtual = snapshot.data ?? torneio;

        return _buildPagina(context, torneioAtual);
      },
    );
  }

  Widget _buildPagina(BuildContext context, TorneioModel torneioAtual) {
    final JogadorTorneioService jogadorService = JogadorTorneioService();

    return _estrutura(
      context,
      Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== CABEÇALHO + INFORMAÇÕES =====
                TcgGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: TcgTheme.gradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        torneioAtual.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Acompanhe participantes, rodadas e classificação.',
                        style: TextStyle(color: TcgTheme.muted, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      _InfoLinha(
                        icone: Icons.key,
                        titulo: 'Código',
                        valor: torneioAtual.codigo,
                      ),
                      const SizedBox(height: 14),
                      _InfoLinha(
                        icone: Icons.calendar_month,
                        titulo: 'Data',
                        valor: _formatarData(torneioAtual.dataHora),
                      ),
                      const SizedBox(height: 14),
                      _InfoLinha(
                        icone: Icons.access_time,
                        titulo: 'Horário',
                        valor: _formatarHorario(torneioAtual.dataHora),
                      ),
                      const SizedBox(height: 14),
                      _InfoLinha(
                        icone: Icons.sports_esports,
                        titulo: 'Formato',
                        valor: torneioAtual.formato.toUpperCase(),
                      ),
                      const SizedBox(height: 14),
                      _InfoLinha(
                        icone: Icons.repeat,
                        titulo: 'Rodadas',
                        valor: '${torneioAtual.quantidadeRodadas}',
                      ),
                      const SizedBox(height: 14),
                      _InfoLinha(
                        icone: Icons.flag,
                        titulo: 'Rodada atual',
                        valor: '${torneioAtual.rodadaAtual}',
                      ),
                      const SizedBox(height: 14),
                      _InfoLinha(
                        icone: Icons.info_outline,
                        titulo: 'Status',
                        valor: _formatarStatus(torneioAtual.status),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ===== TOM / TDF =====
                const _TituloSecao('TOM / TDF'),

                OutlinedButton.icon(
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Verificar dados para TOM / TDF'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TomPreflightPage(torneioId: torneioAtual.id),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_document),
                  label: const Text('Editar metadados TOM'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TomTdfMetadataPage(torneioId: torneioAtual.id),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TcgGradientButton(
                  texto: 'Exportar torneio .tdf',
                  icone: Icons.file_download_outlined,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TomTdfPage(torneioId: torneioAtual.id),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ===== PARTICIPANTES =====
                const _TituloSecao('Participantes'),

                StreamBuilder<List<JogadorTorneioModel>>(
                  stream: jogadorService.listarJogadores(torneioAtual.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const TcgGlassCard(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return const TcgGlassCard(
                        child: Text(
                          'Não foi possível carregar os participantes.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final jogadores = snapshot.data ?? [];

                    final aprovados = jogadores
                        .where((jogador) => jogador.status == 'aprovado')
                        .length;

                    final pendentes = jogadores
                        .where((jogador) => jogador.status == 'pendente')
                        .length;

                    return TcgGlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _ResumoParticipantes(
                                  titulo: 'Aprovados',
                                  quantidade: aprovados,
                                  destaque: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ResumoParticipantes(
                                  titulo: 'Pendentes',
                                  quantidade: pendentes,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GerenciarJogadoresPage(
                                      torneioId: torneioAtual.id,
                                      nomeTorneio: torneioAtual.nome,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.people),
                              label: const Text('Gerenciar jogadores'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ===== ANDAMENTO =====
                const _TituloSecao('Andamento'),

                if (torneioAtual.status == 'inscricoes')
                  _CardTorneioNaoIniciado(
                    onIniciar: () => _iniciarTorneio(context, torneioAtual),
                  )
                else if (torneioAtual.status == 'em_andamento')
                  StreamBuilder<String?>(
                    stream: RodadaService().observarStatusRodada(
                      torneioId: torneioAtual.id,
                      rodada: torneioAtual.rodadaAtual,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const TcgGlassCard(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      return _CardRodadaAtual(
                        torneio: torneioAtual,
                        statusRodada: snapshot.data,
                        onVerClassificacao: () =>
                            _abrirClassificacao(context, torneioAtual),
                      );
                    },
                  )
                else if (torneioAtual.status == 'finalizado')
                  _CardTorneioFinalizado(
                    onVerClassificacao: () => _abrirClassificacao(
                      context,
                      torneioAtual,
                      classificacaoFinal: true,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Título de seção
// ============================================================

class _TituloSecao extends StatelessWidget {
  final String texto;

  const _TituloSecao(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: TcgTheme.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ============================================================
// Torneio não iniciado
// ============================================================

class _CardTorneioNaoIniciado extends StatelessWidget {
  final VoidCallback onIniciar;

  const _CardTorneioNaoIniciado({required this.onIniciar});

  @override
  Widget build(BuildContext context) {
    return TcgGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 42,
            color: TcgTheme.verde,
          ),
          const SizedBox(height: 12),
          const Text(
            'O torneio ainda não foi iniciado.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          TcgGradientButton(
            texto: 'Iniciar torneio',
            icone: Icons.play_arrow,
            onPressed: onIniciar,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Rodada atual
// ============================================================

class _CardRodadaAtual extends StatelessWidget {
  final TorneioModel torneio;
  final String? statusRodada;
  final VoidCallback onVerClassificacao;

  const _CardRodadaAtual({
    required this.torneio,
    required this.statusRodada,
    required this.onVerClassificacao,
  });

  bool get _ultimaRodadaSwiss =>
      torneio.rodadaAtual == torneio.quantidadeRodadas;
  bool get _faseTopCut => torneio.rodadaAtual > torneio.quantidadeRodadas;
  bool get _topCutConcluido => torneio.topcutConcluido;
  bool get _podeFinalizar =>
      (torneio.tamanhoTopCut == 0 && _ultimaRodadaSwiss) ||
      (torneio.tamanhoTopCut > 0 && _topCutConcluido);

  String _titulo() {
    switch (statusRodada) {
      case 'configuracao':
        return 'Rodada ${torneio.rodadaAtual} aguardando configuração';

      case 'finalizada':
        return 'Rodada ${torneio.rodadaAtual} finalizada';

      case 'em_andamento':
        return 'Rodada ${torneio.rodadaAtual} em andamento';

      default:
        return 'Rodada ${torneio.rodadaAtual}';
    }
  }

  Future<void> _gerarProximaRodada(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Gerar Rodada ${torneio.rodadaAtual + 1}'),
          content: const Text(
            'O sistema irá sugerir os próximos confrontos com base na classificação e no histórico de partidas. '
            'Você poderá revisar e alterar os confrontos antes de iniciar a rodada.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Gerar rodada'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final resultado = await RodadaService().gerarProximaRodada(
        torneioId: torneio.id,
        rodadaAtual: torneio.rodadaAtual,
      );

      if (!context.mounted) return;

      switch (resultado) {
        case 'ok':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Rodada ${torneio.rodadaAtual + 1} gerada. Revise os confrontos antes de iniciar.',
              ),
            ),
          );

          break;

        case 'ultima_rodada':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('O torneio já chegou à última rodada.'),
            ),
          );

          break;

        case 'rodada_ja_existe':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A próxima rodada já existe.')),
          );

          break;

        case 'rodada_nao_finalizada':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Finalize a rodada atual antes de gerar a próxima.',
              ),
            ),
          );

          break;

        case 'sem_pareamento_valido':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível parear sem repetir adversários. Revise os pods e o histórico.',
              ),
            ),
          );
          break;

        case 'jogadores_insuficientes':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não existem jogadores suficientes para gerar a próxima rodada.',
              ),
            ),
          );

          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível gerar a próxima rodada.'),
            ),
          );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível gerar a próxima rodada.'),
        ),
      );
    }
  }

  Future<void> _gerarTopCut(BuildContext context) async {
    try {
      final resultado = _faseTopCut
          ? await TopCutService().gerarProximaRodada(torneioId: torneio.id)
          : await TopCutService().iniciarTopCut(torneioId: torneio.id);
      if (!context.mounted) return;
      final mensagem = resultado == 'ok'
          ? 'Chave de eliminação criada. Revise e inicie a rodada.'
          : 'Não foi possível gerar Top Cut: $resultado';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagem)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar Top Cut: $e')),
      );
    }
  }

  Future<void> _finalizarTorneio(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Finalizar torneio'),
          content: const Text(
            'Todas as rodadas foram concluídas. Deseja finalizar o torneio?\n\n'
            'Após a finalização, novas rodadas não poderão ser geradas.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Finalizar torneio'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final resultado = await TorneioService().finalizarTorneio(
        torneioId: torneio.id,
      );

      if (!context.mounted) return;

      switch (resultado) {
        case 'ok':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Torneio finalizado com sucesso.')),
          );

          break;

        case 'torneio_finalizado':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este torneio já foi finalizado.')),
          );

          break;

        case 'rodadas_pendentes':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ainda existem rodadas pendentes.')),
          );

          break;

        case 'rodada_nao_finalizada':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A última rodada ainda não foi finalizada.'),
            ),
          );

          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível finalizar o torneio.'),
            ),
          );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível finalizar o torneio.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TcgGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.sports_esports, size: 42, color: TcgTheme.verde),
          const SizedBox(height: 12),
          Text(
            _titulo(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GerenciarRodadaPage(
                      torneioId: torneio.id,
                      nomeTorneio: torneio.nome,
                      rodada: torneio.rodadaAtual,
                      formato: torneio.formato,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.table_rows),
              label: Text(
                statusRodada == 'configuracao'
                    ? 'Revisar rodada'
                    : 'Abrir rodada atual',
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onVerClassificacao,
              icon: const Icon(Icons.leaderboard),
              label: const Text('Ver classificação'),
            ),
          ),

          if (statusRodada == 'finalizada' &&
              torneio.rodadaAtual < torneio.quantidadeRodadas) ...[
            const SizedBox(height: 12),
            TcgGradientButton(
              texto: 'Gerar Rodada ${torneio.rodadaAtual + 1}',
              icone: Icons.next_plan,
              onPressed: () => _gerarProximaRodada(context),
            ),
          ],

          if (statusRodada == 'finalizada' &&
              ((torneio.tamanhoTopCut > 0 && !_podeFinalizar) ||
                  (_faseTopCut && !_topCutConcluido))) ...[
            const SizedBox(height: 12),
            TcgGradientButton(
              texto: _faseTopCut
                  ? 'Gerar próxima fase eliminatória'
                  : 'Iniciar Top Cut',
              icone: Icons.account_tree_rounded,
              onPressed: () => _gerarTopCut(context),
            ),
          ],

          if (statusRodada == 'finalizada' && _podeFinalizar) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Todas as rodadas foram concluídas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TcgGradientButton(
              texto: 'Finalizar torneio',
              icone: Icons.emoji_events,
              onPressed: () => _finalizarTorneio(context),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Torneio finalizado
// ============================================================

class _CardTorneioFinalizado extends StatelessWidget {
  final VoidCallback onVerClassificacao;

  const _CardTorneioFinalizado({required this.onVerClassificacao});

  @override
  Widget build(BuildContext context) {
    return TcgGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 52, color: TcgTheme.verde),
          const SizedBox(height: 12),
          const Text(
            'Torneio finalizado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Todas as rodadas foram concluídas e a classificação final está disponível.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TcgTheme.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          TcgGradientButton(
            texto: 'Ver classificação final',
            icone: Icons.leaderboard,
            onPressed: onVerClassificacao,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Componentes pequenos
// ============================================================

class _InfoLinha extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const _InfoLinha({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0x1F3DDC84),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icone, size: 18, color: TcgTheme.verde),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(color: TcgTheme.muted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumoParticipantes extends StatelessWidget {
  final String titulo;
  final int quantidade;
  final bool destaque;

  const _ResumoParticipantes({
    required this.titulo,
    required this.quantidade,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        border: Border.all(color: const Color(0x26FFFFFF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            quantidade.toString(),
            style: TextStyle(
              color: destaque ? TcgTheme.verde : Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(color: TcgTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}