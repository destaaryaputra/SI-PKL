import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';

/// Splash sesuai wireframe #1: logo, nama aplikasi, tagline.
/// Setelah animasi singkat, langsung ke dashboard (auto-login)
/// atau halaman login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  String _status = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _arahkan();
  }

  Future<void> _arahkan() async {
    // Beri waktu animasi splash tampil dulu.
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _status = 'Mengecek sesi...');

    final peran = await ApiService().cekSesi();
    if (!mounted) return;

    setState(() => _status = 'Membuka dashboard...');

    // Jika ada token (peran bukan null), langsung ke dashboard yang sesuai
    if (peran != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => switch (peran) {
            'admin' => const AdminDashboardScreen(),
            'siswa' => const DashboardScreen(),
            _ => const LoginScreen(),
          },
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeIn,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo SI-PKL (pin + nama) dari aset.
                Image.asset(
                  'assets/brand/logo_full.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sistem Informasi Pencari Lokasi PKL',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: warna.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _status,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: warna.onSurfaceVariant,
                            ),
                      ),
                    ],
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