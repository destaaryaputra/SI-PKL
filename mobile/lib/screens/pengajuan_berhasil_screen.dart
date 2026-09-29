import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PengajuanBerhasilScreen extends StatefulWidget {
  const PengajuanBerhasilScreen({super.key, required this.namaIndustri});

  final String namaIndustri;

  @override
  State<PengajuanBerhasilScreen> createState() => _PengajuanBerhasilScreenState();
}

class _PengajuanBerhasilScreenState extends State<PengajuanBerhasilScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 120, color: AppTheme.statusDisetujui.fg),
                const SizedBox(height: 24),
                Text('Pengajuan Berhasil!',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.statusDisetujui.fg),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('Pengajuan PKL Anda ke ${widget.namaIndustri} telah berhasil dikirim.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Silakan tunggu persetujuan dari perusahaan.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: warna.onSurfaceVariant),
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    // Ganti halaman ini dengan status; dashboard tetap di
                    // bawah stack, jadi tombol kembali balik ke dashboard.
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/status');
                    },
                    icon: const Icon(Icons.assignment),
                    label: const Text('Lihat Status Pengajuan'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Kembali ke Dashboard'),
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
