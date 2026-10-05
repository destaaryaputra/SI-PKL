import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/animasi.dart';

class PengajuanBerhasilScreen extends StatefulWidget {
  const PengajuanBerhasilScreen({super.key, required this.namaIndustri});

  final String namaIndustri;

  @override
  State<PengajuanBerhasilScreen> createState() =>
      _PengajuanBerhasilScreenState();
}

class _PengajuanBerhasilScreenState extends State<PengajuanBerhasilScreen> {
  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            // Ikon centang: pop halus (scale 0.85 → 1 + fade).
            Center(
              child: MunculSkala(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.statusDisetujui.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 72,
                    color: AppTheme.statusDisetujui.fg,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ItemMasuk(
              index: 1,
              child: Text(
                'Pengajuan Berhasil!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.statusDisetujui.fg,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ItemMasuk(
              index: 2,
              child: Text(
                'Pengajuan PKL Anda ke ${widget.namaIndustri} telah dikirim.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            ItemMasuk(
              index: 3,
              child: Text(
                'Silakan tunggu persetujuan dari perusahaan.',
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
              child: SizedBox(
                width: double.infinity,
                child: TombolMuat(
                  teks: 'Lihat Status Pengajuan',
                  ikon: Icons.assignment,
                  pertahankanTeks: true,
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/status');
                  },
                ),
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