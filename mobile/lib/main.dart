import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/splash_page.dart';
import 'screens/login_screen.dart';
import 'screens/status_pengajuan_screen.dart';
import 'screens/profil_screen.dart';

void main() {
  runApp(const SiPklApp());
}

class SiPklApp extends StatelessWidget {
  const SiPklApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SI-PKL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashPage(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/status': (context) => const StatusPengajuanScreen(),
        '/profil': (context) => const ProfilScreen(),
      },
    );
  }
}
