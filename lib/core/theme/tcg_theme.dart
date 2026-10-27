import 'package:flutter/material.dart';

/// Identidade visual compartilhada. Pode ser aplicada a telas existentes
/// sem alterar os services, rotas ou modelos.
class TcgTheme {
  static const Color navy = Color(0xFF101B43);
  static const Color blue = Color(0xFF1265E9);
  static const Color violet = Color(0xFF7541F4);
  static const Color cyan = Color(0xFF08B5E9);
  static const Color background = Color(0xFFF2F7FF);
  static const Color muted = Color(0xFF6F7E9D);

  static const LinearGradient gradient = LinearGradient(
    colors: [cyan, blue, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData data() {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: navy,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 21, fontWeight: FontWeight.w800, color: navy,
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 27),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 21),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: navy, fontSize: 16),
        bodyMedium: TextStyle(color: navy, fontSize: 14),
        bodySmall: TextStyle(color: muted, fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x1A4E78C8),
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: Color(0xFFA1ADC6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCE5F6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB9C9E9),
          minimumSize: const Size(0, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blue,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: Color(0xFFBDD3FA)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        extendedTextStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEAF1FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE3EAF7)),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static Widget wrap(Widget child) => Theme(data: data(), child: child);
}

class TcgHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const TcgHero({super.key, required this.title, required this.subtitle,
    this.icon = Icons.emoji_events_rounded});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: TcgTheme.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x263F6EED), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 7),
          Text(subtitle, style: const TextStyle(color: Color(0xFFE8F4FF), height: 1.35)),
        ])),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, color: Colors.white, size: 34),
        ),
      ]),
    );
  }
}

class TcgStatusBadge extends StatelessWidget {
  final String status;
  const TcgStatusBadge({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final good = s == 'aprovado' || s == 'finalizado' || s == 'finalizada';
    final bad = s == 'recusado' || s == 'contestada';
    final color = good ? const Color(0xFF087F55) : bad ? const Color(0xFFC52E52) : const Color(0xFFB76A0A);
    final bg = good ? const Color(0xFFE0F9EF) : bad ? const Color(0xFFFFE7ED) : const Color(0xFFFFF2DB);
    final label = status.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(good ? Icons.check_circle : bad ? Icons.cancel : Icons.schedule, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }
}

class TcgTournamentTile extends StatelessWidget {
  final String nome;
  final DateTime data;
  final String formato;
  final String status;
  final int? pontos;
  final String buttonText;
  final VoidCallback onTap;
  const TcgTournamentTile({super.key, required this.nome, required this.data,
    required this.formato, required this.status, required this.onTap,
    this.pontos, this.buttonText = 'Abrir'});

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final when = '${two(data.day)}/${two(data.month)}/${data.year}  •  ${two(data.hour)}:${two(data.minute)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 62, height: 69,
              decoration: BoxDecoration(gradient: TcgTheme.gradient, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nome, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 7),
              Row(children: [const Icon(Icons.calendar_today_outlined, size: 15, color: TcgTheme.muted),
                const SizedBox(width: 6), Expanded(child: Text(when, style: const TextStyle(fontSize: 12, color: TcgTheme.muted)))]),
              const SizedBox(height: 5),
              Row(children: [const Icon(Icons.style_outlined, size: 16, color: TcgTheme.muted),
                const SizedBox(width: 6), Text(formato.toUpperCase(), style: const TextStyle(fontSize: 12, color: TcgTheme.muted))]),
            ])),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            TcgStatusBadge(status: status),
            const Spacer(),
            if (pontos != null) ...[
              const Icon(Icons.emoji_events_rounded, color: TcgTheme.blue, size: 17),
              const SizedBox(width: 5),
              Text('$pontos pts', style: const TextStyle(color: TcgTheme.blue, fontWeight: FontWeight.w800)),
            ],
          ]),
          const SizedBox(height: 13),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: onTap, icon: const Icon(Icons.arrow_forward_rounded), label: Text(buttonText),
          )),
        ]),
      ),
    );
  }
}
