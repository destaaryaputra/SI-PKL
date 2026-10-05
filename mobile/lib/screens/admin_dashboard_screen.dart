import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animasi.dart';
import '../widgets/app_drawer.dart';
import '../widgets/grafik.dart';
import '../widgets/state_views.dart';

import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _apiService = ApiService();
  Future<Map<String, dynamic>>? _statistikFuture;

  @override
  void initState() {
    super.initState();
    _statistikFuture = _apiService.ambilStatistikAdmin();
  }

  Future<void> _muatUlang() async {
    setState(() => _statistikFuture = _apiService.ambilStatistikAdmin());
    await _statistikFuture;
  }

  /// Parsing defensif statistik dari backend (bisa int/String/bool/null).
  static int _parseAngka(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is bool) return v ? 1 : 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: RefreshIndicator(
        onRefresh: _muatUlang,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _statistikFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(label: 'Memuat statistik...');
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  ErrorView(
                    message: 'Gagal memuat statistik: ${snapshot.error}',
                    onRetry: _muatUlang,
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            final dataBulan =
                (data['pengajuan_per_bulan'] as List<dynamic>? ?? [])
                    .cast<Map<String, dynamic>>();
            final topIndustri =
                (data['top_industri'] as List<dynamic>? ?? [])
                    .cast<Map<String, dynamic>>();
            final siswaPerJurusan =
                (data['siswa_per_jurusan'] as List<dynamic>? ?? [])
                    .cast<Map<String, dynamic>>();
            final kuotaIndustri =
                (data['kuota_industri'] as List<dynamic>? ?? [])
                    .cast<Map<String, dynamic>>();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section Ringkasan — card stat bertahap di dalam
                ItemMasuk(index: 0, child: _JudulSeksi(teks: 'Ringkasan')),
                const SizedBox(height: 16),
                ItemMasuk(
                  index: 1,
                  child: Row(
                    children: [
                      _StatCard(
                        label: 'Total Siswa',
                        nilai: '${data['total_siswa'] ?? 0}',
                        icon: Icons.people,
                        warna: AppTheme.tealGelap,
                        bg: AppTheme.tealLembut,
                      ),
                      const SizedBox(width: 8),
                      _StatCard(
                        label: 'Total Industri',
                        nilai: '${data['total_industri'] ?? 0}',
                        icon: Icons.business,
                        warna: AppTheme.navy,
                        bg: const Color(0xFFE7EFF6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ItemMasuk(
                  index: 2,
                  child: Row(
                    children: [
                      _StatCard(
                        label: 'Menunggu',
                        nilai: '${data['pengajuan_menunggu'] ?? 0}',
                        icon: Icons.pending,
                        warna: AppTheme.statusMenunggu.fg,
                        bg: AppTheme.statusMenunggu.bg,
                      ),
                      const SizedBox(width: 8),
                      _StatCard(
                        label: 'Disetujui',
                        nilai: '${data['pengajuan_disetujui'] ?? 0}',
                        icon: Icons.check_circle,
                        warna: AppTheme.statusDisetujui.fg,
                        bg: AppTheme.statusDisetujui.bg,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ItemMasuk(index: 3, child: _JudulSeksi(teks: 'Status Pengajuan')),
                const SizedBox(height: 16),
                ItemMasuk(
                  index: 4,
                  child: GrafikDonat(
                    menunggu: _parseAngka(data['pengajuan_menunggu']),
                    disetujui: _parseAngka(data['pengajuan_disetujui']),
                    ditolak: _parseAngka(data['pengajuan_ditolak']),
                  ),
                ),
                const SizedBox(height: 24),
                ItemMasuk(index: 5, child: _JudulSeksi(teks: 'Pengajuan per Bulan')),
                const SizedBox(height: 16),
                ItemMasuk(
                  index: 6,
                  child: GrafikBatangBertumpuk(
                    dataBulan: dataBulan,
                    onBukaTabel: () => tampilkanTabelData(
                      context,
                      judul: 'Pengajuan per bulan',
                      kolom: ['Bulan', 'Menunggu', 'Disetujui', 'Ditolak'],
                      baris: [
                        for (final bulan in dataBulan)
                          [
                            '${bulan['label']}',
                            '${bulan['menunggu'] ?? 0}',
                            '${bulan['disetujui'] ?? 0}',
                            '${bulan['ditolak'] ?? 0}',
                          ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ItemMasuk(index: 7, child: _JudulSeksi(teks: 'Top 5 Industri Dilamar')),
                const SizedBox(height: 16),
                ItemMasuk(
                  index: 8,
                  child: DaftarBarHorizontal(
                    data: topIndustri,
                    satuan: 'pengajuan',
                  ),
                ),
                const SizedBox(height: 24),
                ItemMasuk(index: 9, child: _JudulSeksi(teks: 'Siswa per Jurusan')),
                const SizedBox(height: 16),
                ItemMasuk(
                  index: 10,
                  child: DaftarBarHorizontal(
                    data: siswaPerJurusan,
                    satuan: 'siswa',
                  ),
                ),
                const SizedBox(height: 24),
                ItemMasuk(index: 11, child: _JudulSeksi(teks: 'Kuota Industri')),
                const SizedBox(height: 16),
                ItemMasuk(
                  index: 12,
                  child: DaftarMeterKuota(data: kuotaIndustri),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Judul seksi dengan penanda teal — sama seperti di layar detail siswa.
class _JudulSeksi extends StatelessWidget {
  const _JudulSeksi({required this.teks});

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.teal,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          teks,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.nilai,
    required this.icon,
    required this.warna,
    required this.bg,
  });

  final String label;
  final String nilai;
  final IconData icon;
  final Color warna;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IkonKotak(icon: icon, fg: warna, bg: bg),
                  const Spacer(),
                  AngkaBerjalan(
                    nilai: int.tryParse(nilai) ?? 0,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: warna,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

