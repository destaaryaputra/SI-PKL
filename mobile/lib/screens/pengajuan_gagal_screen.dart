import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'industry_detail_screen.dart';

class PengajuanGagalScreen extends StatefulWidget {
  const PengajuanGagalScreen({
    super.key,
    required this.industriId,
    required this.namaIndustri,
    required this.pesanError,
  });

  final int industriId;
  final String namaIndustri;
  final String pesanError;

  @override
  State<PengajuanGagalScreen> createState() => _PengajuanGagalScreenState();
}

class _PengajuanGagalScreenState extends State<PengajuanGagalScreen>
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
                Icon(Icons.cancel, size: 120, color: AppTheme.statusDitolak.fg),
                const SizedBox(height: 24),
                Text('Pengajuan Gagal',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.statusDitolak.fg),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(
                    'Pengajuan PKL Anda ke ${widget.namaIndustri} tidak dapat diproses.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(widget.pesanError,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: warna.onSurfaceVariant),
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    // Halaman detail digantikan oleh halaman ini saat
                    // pengajuan gagal, jadi "Coba Lagi" kembali ke detail
                    // (initState-nya otomatis memuat ulang data kuota).
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => IndustryDetailScreen(
                            industriId: widget.industriId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
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
