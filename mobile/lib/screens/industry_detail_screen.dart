import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/industri.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';
import 'pengajuan_berhasil_screen.dart';
import 'pengajuan_gagal_screen.dart';
import 'riwayat_industri_screen.dart';

class IndustryDetailScreen extends StatefulWidget {
  const IndustryDetailScreen({super.key, required this.industriId});

  final int industriId;

  @override
  State<IndustryDetailScreen> createState() => _IndustryDetailScreenState();
}

class _IndustryDetailScreenState extends State<IndustryDetailScreen> {
  final _apiService = ApiService();
  late Future<Industri> _industriFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _muatIndustri();
  }

  Future<void> _muatIndustri() async {
    setState(() {
      _industriFuture = _apiService.ambilDetailIndustri(widget.industriId);
    });
    await _industriFuture;
  }

  Future<void> _showKonfirmasiDialog(Industri industri) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Pengajuan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin mengajukan PKL di industri ini?',
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      industri.nama,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      industri.alamat,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jurusan: ${industri.jurusan.join(", ")}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sisa Kuota: ${industri.sisaKuota}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _ajukan(industri.nama);
    }
  }

  Future<void> _ajukan(String namaIndustri) async {
    setState(() => _isSubmitting = true);
    try {
      await _apiService.ajukanPkl(widget.industriId);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PengajuanBerhasilScreen(namaIndustri: namaIndustri),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PengajuanGagalScreen(
            industriId: widget.industriId,
            namaIndustri: namaIndustri,
            pesanError: error.message,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// FR-18: lempar koordinat ke aplikasi navigasi di perangkat.
  /// URL universal Google Maps: Android/iOS membuka aplikasi Maps,
  /// web membuka maps.google.com — tanpa API key.
  Future<void> _bukaNavigasi(Industri industri) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${industri.latitude},${industri.longitude}',
    );
    final berhasil = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!berhasil && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka aplikasi navigasi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Industri')),
      body: FutureBuilder<Industri>(
        future: _industriFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(label: 'Memuat detail industri...');
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: 'Gagal memuat detail industri: ${snapshot.error}',
              onRetry: _muatIndustri,
            );
          }
          final industri = snapshot.data;
          if (industri == null) {
            return const EmptyStateView(
              icon: Icons.business_outlined,
              title: 'Data industri tidak ditemukan',
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Header gambar placeholder (wireframe #7).
                    Container(
                      height: 140,
                      color: warna.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: warna.outline,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            industri.nama,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 18,
                                color: warna.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  industri.alamat,
                                  style: TextStyle(
                                    color: warna.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Kapasitas',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _KuotaCard(
                                label: 'Maksimal',
                                value: '${industri.kuota}',
                                color: warna.surfaceContainerHigh,
                                textColor: warna.onSurface,
                              ),
                              const SizedBox(width: 8),
                              _KuotaCard(
                                label: 'Terpakai',
                                value: '${industri.terpakai}',
                                color: AppTheme.statusMenunggu.bg,
                                textColor: AppTheme.statusMenunggu.fg,
                              ),
                              const SizedBox(width: 8),
                              _KuotaCard(
                                label: 'Sisa',
                                value: '${industri.sisaKuota}',
                                color: industri.sisaKuota > 0
                                    ? AppTheme.statusDisetujui.bg
                                    : AppTheme.statusDitolak.bg,
                                textColor: industri.sisaKuota > 0
                                    ? AppTheme.statusDisetujui.fg
                                    : AppTheme.statusDitolak.fg,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Jurusan yang Diterima',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: industri.jurusan
                                .map(
                                  (nama) => Chip(
                                    label: Text(nama),
                                    avatar: const Icon(Icons.school, size: 18),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          // Riwayat penempatan (wireframe #7, FR-17).
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.history),
                            title: const Text('Riwayat Penempatan'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RiwayatIndustriScreen(
                                    industriId: widget.industriId,
                                    namaIndustri: industri.nama,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tombol aksi bawah: Navigasi + Ajukan PKL (wireframe #7).
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _bukaNavigasi(industri),
                        icon: const Icon(Icons.navigation),
                        label: const Text('Navigasi'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: industri.sisaKuota == 0 || _isSubmitting
                              ? null
                              : () => _showKonfirmasiDialog(industri),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: const Text('Ajukan PKL'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Kartu kecil angka kuota (Maksimal / Terpakai / Sisa).
class _KuotaCard extends StatelessWidget {
  const _KuotaCard({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: textColor),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
