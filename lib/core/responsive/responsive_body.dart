import 'package:flutter/material.dart';

/// Larguras de referência para os layouts do aplicativo.
/// Os limites se aplicam à área disponível, não ao modelo do dispositivo.
class TcgBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  static int tournamentColumns(double width) {
    if (width >= desktop) return 3;
    if (width >= 780) return 2;
    return 1;
  }
}

/// Evita conteúdo excessivamente largo em tablets, janelas e desktop.
/// Mantém o espaço vertical do Scaffold para ListView, ScrollView e Expanded.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 1080,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Reorganiza uma lista vertical de cards em colunas somente quando houver
/// largura suficiente; mantém dimensões adequadas aos botões e aos textos.
class ResponsiveTournamentGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry? padding;

  const ResponsiveTournamentGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = TcgBreakpoints.tournamentColumns(constraints.maxWidth);
        if (columns == 1) {
          return ListView.builder(
            padding: padding,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        }
        return GridView.builder(
          padding: padding,
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 8,
            mainAxisExtent: 285,
          ),
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
