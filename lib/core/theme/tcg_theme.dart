
import 'package:flutter/material.dart';

/// Identidade visual compartilhada do aplicativo TCG.
/// Inspirada nas cores da Trasgo Nerd Store.
class TcgTheme {
  // Cores principais
  static const Color orange = Color(0xFFF47B16);
  static const Color orangeDark = Color(0xFFE6650B);
  static const Color green = Color(0xFF39A935);
  static const Color greenDark = Color(0xFF27852A);
  static const Color black = Color(0xFF151515);

  // Cores de apoio
  static const Color background = Color(0xFFFFF8F1);
  static const Color muted = Color(0xFF77716B);
  static const Color lightOrange = Color(0xFFFFE9D2);
  static const Color lightGreen = Color(0xFFE5F5E2);
  static const Color border = Color(0xFFE9DED1);

  // Gradiente principal
  static const LinearGradient gradient = LinearGradient(
    colors: [orange, orangeDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData data() {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.light,
      surface: Colors.white,
    ).copyWith(
      primary: orange,
      onPrimary: Colors.white,
      secondary: green,
      onSecondary: Colors.white,
      tertiary: black,
      surface: Colors.white,
      onSurface: black,
      error: const Color(0xFFC62828),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: black,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: black,
        ),
      ),

      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w800,
          color: black,
          fontSize: 27,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: black,
          fontSize: 21,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: black,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: black,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: muted,
          fontSize: 12,
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x1A000000),
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(
          color: Color(0xFFAAA19A),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: orange,
            width: 2,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFFFD1A6),
          minimumSize: const Size(0, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: orangeDark,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        extendedTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: lightOrange,
        selectedColor: orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide.none,
      ),

      dividerTheme: const DividerThemeData(
        color: border,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: black,
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: orange,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return black;
        }),
        todayForegroundColor: WidgetStateProperty.all(orange),
        todayBorder: const BorderSide(color: orange),
        yearForegroundColor: WidgetStateProperty.all(orange),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return orange;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static Widget wrap(Widget child) =>
      Theme(data: data(), child: child);
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
            gradient: TcgTheme.gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33F47B16),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
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
                        color: Color(0xFFFFF1E3),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compacto ? 8 : 12),

              // Imagem ou ícone
              Container(
                width: compacto ? 46 : 76,
                height: compacto ? 46 : 76,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: imageAsset != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
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

  const TcgStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();

    final good = s == 'aprovado' ||
        s == 'finalizado' ||
        s == 'finalizada';

    final bad = s == 'recusado' || s == 'contestada';

    final color = good
        ? TcgTheme.greenDark
        : bad
            ? const Color(0xFFC62828)
            : TcgTheme.orangeDark;

    final bg = good
        ? TcgTheme.lightGreen
        : bad
            ? const Color(0xFFFFE7E7)
            : TcgTheme.lightOrange;

    final label = status.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 62,
                  height: 69,
                  decoration: BoxDecoration(
                    gradient: TcgTheme.gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: TcgTheme.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              when,
                              style: const TextStyle(
                                fontSize: 12,
                                color: TcgTheme.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.style_outlined,
                            size: 16,
                            color: TcgTheme.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formato.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: TcgTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                TcgStatusBadge(status: status),
                if (pontos != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                        color: TcgTheme.orange, size: 17),
                      const SizedBox(width: 5),
                      Text('$pontos pts', style: const TextStyle(
                        color: TcgTheme.orangeDark,
                        fontWeight: FontWeight.w800,
                      )),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
