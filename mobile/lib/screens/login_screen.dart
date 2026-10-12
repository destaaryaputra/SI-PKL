import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animasi.dart';
import 'admin_dashboard_screen.dart';
import 'dashboard_screen.dart';

/// Layar login (wireframe #2) — struktur wireframe dipertahankan:
/// logo, judul, NIS, password, tombol. Lapisan visualnya saja yang
/// dirapikan: panel form putih di atas latar brand, footer brand.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nisController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nisController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_nisController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'NIS dan password wajib diisi.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasil = await _apiService.login(
        _nisController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => hasil.peran == 'admin'
              ? const AdminDashboardScreen()
              : const DashboardScreen(),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Tidak dapat terhubung ke server: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Scaffold(
      // Latar brand navy-teal sangat lembut — senada dengan splash.
      backgroundColor: warna.surface,
      body: LatarBrand(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Image.asset(
                      'assets/brand/logo_full.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sistem Informasi Pencari Lokasi PKL',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.navy,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.teal,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Panel form: satu bidang putih ber-outline — form terasa
                    // jadi satu kesatuan, bukan field melayang di ruang kosong.
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: warna.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: warna.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.navy.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _nisController,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              labelText: 'NIS',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: Motion.sedang,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: _errorMessage != null
                                ? Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.statusDitolak.bg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 18,
                                          color: AppTheme.statusDitolak.fg,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: AppTheme.statusDitolak.fg,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 20),
                          TombolMuat(
                            teks: 'Masuk',
                            memuat: _isLoading,
                            onPressed: _login,
                            gaya: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Footer brand: satu baris kecil, wajar untuk app institusi.
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.tealGelap),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Temukan tempat PKL terbaikmu di Lampung',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: warna.onSurfaceVariant,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
