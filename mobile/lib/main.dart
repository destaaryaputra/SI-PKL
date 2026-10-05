import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/splash_page.dart';
import 'screens/login_screen.dart';
import 'screens/status_pengajuan_screen.dart';
import 'screens/profil_screen.dart';
import 'screens/admin_siswa_screen.dart';
import 'screens/admin_jurusan_screen.dart';
import 'screens/admin_industri_screen.dart';
import 'screens/admin_pengajuan_screen.dart';

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
      // Hanya route yang benar-benar dipakai navigasi bernama. Layar lain
      // (dashboard, detail industri, form, peta) dibuka lewat MaterialPageRoute
      // langsung dari pemanggilnya karena butuh argumen/instance.
      routes: {
        '/login': (context) => const LoginScreen(),
        '/status': (context) => const StatusPengajuanScreen(),
        '/profil': (context) => const ProfilScreen(),
        '/admin-siswa': (context) => const AdminSiswaScreen(),
        '/admin-jurusan': (context) => const AdminJurusanScreen(),
        '/admin-industri': (context) => const AdminIndustriScreen(),
        '/admin-pengajuan': (context) => const AdminPengajuanScreen(),
      },
    );
  }
}
