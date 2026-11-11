import 'package:flutter/material.dart';
import '../../../core/theme/tcg_theme.dart';
import '../services/tom_preflight_service.dart';

class TomPreflightPage extends StatelessWidget {
  final String torneioId;
  const TomPreflightPage({super.key, required this.torneioId});

  @override
  Widget build(BuildContext context) => TcgTheme.wrap(Scaffold(
    appBar: AppBar(title: const Text('Validação para TOM')),
    body: FutureBuilder<TomPreflightResult>(
      future: TomPreflightService().validar(torneioId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro na validação: ${snapshot.error}'));
        }
        final resultado = snapshot.data!;
        return ListView(padding: const EdgeInsets.all(16), children: [
          const TcgHero(title: 'Conferência do torneio',
              subtitle: 'Confira os dados antes da exportação TDF experimental.',
              icon: Icons.fact_check_outlined),
          Card(child: Padding(padding: const EdgeInsets.all(16),
            child: Text(resultado.dadosCompletos
                ? 'Não foram encontrados erros estruturais nos dados.'
                : '${resultado.erros.length} problema(s) encontrado(s).'),
          )),
          if (resultado.erros.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Erros', style: Theme.of(context).textTheme.titleMedium),
            ...resultado.erros.map((e) => ListTile(
                leading: const Icon(Icons.error_outline), title: Text(e))),
          ],
          const SizedBox(height: 12),
          Text('Observações', style: Theme.of(context).textTheme.titleMedium),
          ...resultado.avisos.map((a) => ListTile(
              leading: const Icon(Icons.info_outline), title: Text(a))),
          const SizedBox(height: 16),
          const Text('Para gerar o arquivo, volte ao torneio e selecione Exportar torneio .tdf. '
              'A validação final deve ocorrer no TOM oficial.'),
        ]);
      },
    ),
  ));
}
