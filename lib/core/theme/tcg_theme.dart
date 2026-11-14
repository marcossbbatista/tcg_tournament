import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Identidade visual compartilhada do aplicativo (tema escuro + verde).
class TcgTheme {
  // ===== Cores novas =====
  static const Color fundo = Color(0xFF14142B);
  static const Color card = Color(0xFF1E1E38);
  static const Color campo = Color(0xFF2A2A45);
  static const Color borda = Color(0xFF3A3A5C);

  static const Color verde = Color(0xFF3DDC84);
  static const Color verdeClaro = Color(0xFF7BE495);
  static const Color verdeEscuro = Color(0xFF1FA84F);

  static const Color texto = Colors.white;
  static const Color muted = Color(0xFFA0A0BC);
  static const Color erro = Color(0xFFFF6B6B);

  // ===== Aliases antigos (para as telas atuais não quebrarem) =====
  // Você pode ir trocando pelos nomes novos aos poucos.
  static const Color orange = verde;
  static const Color orangeDark = verdeEscuro;
  static const Color green = verde;
  static const Color greenDark = verdeEscuro;
  static const Color black = texto; // antes era o texto escuro, agora é branco
  static const Color background = fundo;
  static const Color border = borda;
  static const Color lightOrange = campo;
  static const Color lightGreen = Color(0xFF1F3A2E);

  // Gradiente principal (botões, hero, ícones)
  static const LinearGradient gradient = LinearGradient(
    colors: [verdeClaro, verdeEscuro],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Estilo da status bar e da barra de navegação
  static const SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
    statusBarColor: fundo,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: fundo,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData data() {
    final scheme = ColorScheme.fromSeed(
      seedColor: verde,
      brightness: Brightness.dark,
    ).copyWith(
      primary: verde,
      onPrimary: fundo,
      secondary: verdeEscuro,
      onSecondary: Colors.white,
      surface: card,
      onSurface: texto,
      error: erro,
    );

    OutlineInputBorder borda0(Color cor, {double largura = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cor, width: largura),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: fundo,
      canvasColor: fundo,
      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        backgroundColor: fundo,
        foregroundColor: texto,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: overlay,
        titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: texto,
        ),
      ),

      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w800,
          color: texto,
          fontSize: 27,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: texto,
          fontSize: 21,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: texto,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(color: texto, fontSize: 14),
        bodySmall: TextStyle(color: muted, fontSize: 12),
      ),

      iconTheme: const IconThemeData(color: Colors.white70),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borda),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: campo,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIconColor: Colors.white70,
        suffixIconColor: Colors.white70,
        border: borda0(Colors.transparent),
        enabledBorder: borda0(Colors.transparent),
        focusedBorder: borda0(verde, largura: 2),
        errorBorder: borda0(erro),
        focusedErrorBorder: borda0(erro, largura: 2),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: verdeEscuro,
          foregroundColor: Colors.white,
          disabledBackgroundColor: campo,
          disabledForegroundColor: Colors.white38,
          minimumSize: const Size(0, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: verde,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: verde),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: verde),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: verdeEscuro,
        foregroundColor: Colors.white,
        extendedTextStyle: TextStyle(fontWeight: FontWeight.w700),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: campo,
        selectedColor: verdeEscuro,
        labelStyle: const TextStyle(color: texto),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide.none,
      ),

      dividerTheme: const DividerThemeData(color: Colors.white24),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? verde : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(fundo),
        side: const BorderSide(color: Colors.white54, width: 1.5),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? verde : Colors.white54,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0x663DDC84)
              : campo,
        ),
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: verde),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: campo,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: verdeEscuro,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return fundo;
          return texto;
        }),
        todayForegroundColor: WidgetStateProperty.all(verde),
        todayBorder: const BorderSide(color: verde),
        yearForegroundColor: WidgetStateProperty.all(verde),
        dayBackgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return verde;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Aplica o tema e o estilo da status bar / barra de navegação.
  static Widget wrap(Widget child) => Theme(
        data: data(),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: child,
        ),
      );
}

/// Botão principal com degradê verde (o ElevatedButton não aceita gradiente).
class TcgGradientButton extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool carregando;
  final IconData? icone;

  const TcgGradientButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.carregando = false,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    final desabilitado = onPressed == null || carregando;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: desabilitado ? null : TcgTheme.gradient,
          color: desabilitado ? TcgTheme.campo : null,
        ),
        child: ElevatedButton(
          onPressed: desabilitado ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: carregando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icone != null) ...[
                      Icon(icone, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      texto.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Banner principal das páginas
class TcgHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imageAsset;

  const TcgHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.emoji_events_rounded,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 390;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: EdgeInsets.all(compacto ? 16 : 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2A45), Color(0xFF1E1E38)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TcgTheme.borda),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: TcgTheme.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compacto ? 8 : 12),
              Container(
                width: compacto ? 46 : 76,
                height: compacto ? 46 : 76,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: TcgTheme.gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: imageAsset != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          imageAsset!,
                          fit: BoxFit.cover,
                          width: compacto ? 46 : 76,
                          height: compacto ? 46 : 76,
                        ),
                      )
                    : Icon(
                        icon,
                        color: Colors.white,
                        size: compacto ? 26 : 34,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Identificação visual dos status
class TcgStatusBadge extends StatelessWidget {
  final String status;

  const TcgStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();

    final good = s == 'aprovado' || s == 'finalizado' || s == 'finalizada';
    final bad = s == 'recusado' || s == 'contestada';

    final color = good
        ? TcgTheme.verde
        : bad
            ? TcgTheme.erro
            : const Color(0xFFFFB74D);

    final bg = good
        ? const Color(0x263DDC84)
        : bad
            ? const Color(0x26FF6B6B)
            : const Color(0x26FFB74D);

    final label = status.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            good
                ? Icons.check_circle
                : bad
                    ? Icons.cancel
                    : Icons.schedule,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de torneio
class TcgTournamentTile extends StatelessWidget {
  final String nome;
  final DateTime data;
  final String formato;
  final String status;
  final int? pontos;
  final String buttonText;
  final VoidCallback onTap;

  const TcgTournamentTile({
    super.key,
    required this.nome,
    required this.data,
    required this.formato,
    required this.status,
    required this.onTap,
    this.pontos,
    this.buttonText = 'Abrir',
  });

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final when =
        '${two(data.day)}/${two(data.month)}/${data.year}  •  ${two(data.hour)}:${two(data.minute)}';

    return TcgGlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formato.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: TcgTheme.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: TcgTheme.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        when,
                        style: const TextStyle(
                            fontSize: 12, color: TcgTheme.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TcgStatusBadge(status: status),
                    if (pontos != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: TcgTheme.verde, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$pontos pts',
                            style: const TextStyle(
                              color: TcgTheme.verde,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TcgCircleButton(onTap: onTap),
        ],
      ),
    );
  }
}

/// Fundo com brilhos verdes (dá o que desfocar atrás do glass)
class TcgBackground extends StatelessWidget {
  final Widget child;
  const TcgBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: TcgTheme.fundo)),
        Positioned(
          top: 120,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x553DDC84), Color(0x003DDC84)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x441FA84F), Color(0x001FA84F)],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Card estilo vidro (glassmorphism)
class TcgGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const TcgGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x26FFFFFF), Color(0x0DFFFFFF)],
              ),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão circular com um círculo translúcido ao fundo
class TcgCircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;

  const TcgCircleButton({
    super.key,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0x1F3DDC84), // círculo de fundo
        ),
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: TcgTheme.gradient,
            boxShadow: [
              BoxShadow(
                color: Color(0x663DDC84),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

/// Cabeçalho com curva embaixo (como o modelo)
class TcgCurvedHeader extends StatelessWidget {
  final String saudacao;
  final String titulo;
  final List<Widget> actions;

  const TcgCurvedHeader({
    super.key,
    required this.saudacao,
    required this.titulo,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurvaClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 8, 8, 56),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1FA84F), Color(0xFF0F5E45)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
            const SizedBox(height: 4),
            Text(
              saudacao,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvaClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(
        size.width * 0.5, size.height + 24,
        size.width, size.height - 36,
      )
      ..lineTo(size.width, 0)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}