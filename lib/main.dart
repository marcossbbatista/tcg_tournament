import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tcg_tournament/core/theme/tcg_theme.dart';

import 'firebase_options.dart';
import 'features/auth/pages/login_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TcgTournamentApp());
}

class TcgTournamentApp extends StatelessWidget {
  const TcgTournamentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      title: 'TCG Tournament',
      theme: TcgTheme.data(),
      home: const LoginPage(),
    );
  }
}