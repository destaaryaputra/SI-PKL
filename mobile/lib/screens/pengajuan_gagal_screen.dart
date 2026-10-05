import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/animasi.dart';
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
  State<PengajuanGagalScreen> createState() =>
      _PengajuanGagalScreenState();
}

class _PengajuanGagalScreenState extends State<PengajuanGagalScreen> {
  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            // Ikon cancel: pop halus (scale 0.85 → 1 + fade).
            Center(
              child: MunculSkala(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.statusDitolak.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cancel,
                    size: 72,
                    color: AppTheme.statusDitolak.fg,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ItemMasuk(
              index: 1,
              child: Text(
                'Pengajuan Gagal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.statusDitolak.fg,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ItemMasuk(
              index: 2,
              child: Text(
                'Pengajuan PKL Anda ke ${widget.namaIndustri} tidak dapat diproses.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            ItemMasuk(
              index: 3,
              child: Text(
                widget.pesanError,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: warna.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            ItemMasuk(
              index: 4,
              child: TombolMuat(
                teks: 'Coba Lagi',
                ikon: Icons.refresh,
                pertahankanTeks: true,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => IndustryDetailScreen(
                        industriId: widget.industriId,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ItemMasuk(
              index: 5,
              child: SizedBox(
                width: double.infinity,
                child: TombolMuat(
                  teks: 'Kembali ke Dashboard',
                  ikon: Icons.arrow_back,
                  pertahankanTeks: true,
                  garis: true,
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}