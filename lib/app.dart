import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/dashboard_screen.dart';
import 'services/data_repository.dart';

class App extends StatefulWidget {
  const App({super.key, required this.repository, required this.firebaseReady});

  final DataRepository repository;
  final bool firebaseReady;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void dispose() {
    widget.repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF036B6E),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF036B6E),
      secondary: const Color(0xFF03B5AA),
      tertiary: const Color(0xFFFFB703),
      surface: Colors.white,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Study Desk Monitor',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.spaceGroteskTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF4F7F4),
        cardTheme: CardThemeData(
          color: colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: DashboardScreen(
        repository: widget.repository,
        firebaseReady: widget.firebaseReady,
      ),
    );
  }
}
