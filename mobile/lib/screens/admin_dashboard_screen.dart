import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/state_views.dart';

import '../services/api_service.dart';
import 'admin_pengajuan_screen.dart';
import 'admin_siswa_screen.dart';
import 'admin_jurusan_screen.dart';
import 'admin_industri_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
      ),
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
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Ringkasan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatCard(
                      label: 'Total Siswa',
                      nilai: '${data['total_siswa'] ?? 0}',
                      icon: Icons.people,
                      warna: AppTheme.navy,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      label: 'Total Industri',
                      nilai: '${data['total_industri'] ?? 0}',
                      icon: Icons.business,
                      warna: AppTheme.navy,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatCard(
                      label: 'Menunggu',
                      nilai: '${data['pengajuan_menunggu'] ?? 0}',
                      icon: Icons.pending,
                      warna: AppTheme.statusMenunggu.fg,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      label: 'Disetujui',
                      nilai: '${data['pengajuan_disetujui'] ?? 0}',
                      icon: Icons.check_circle,
                      warna: AppTheme.statusDisetujui.fg,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Grafik pengajuan per bulan (wireframe #13).
                Text(
                  'Pengajuan per Bulan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _GrafikBulanan(
                  dataBulan:
                      (data['pengajuan_per_bulan'] as List<dynamic>? ?? [])
                          .cast<Map<String, dynamic>>(),
                ),

                const SizedBox(height: 24),
                // Menu pintasan kelola (wireframe #13-19).
                _MenuKelola(
                  onPengajuan: () => _buka(const AdminPengajuanScreen()),
                  onSiswa: () => _buka(const AdminSiswaScreen()),
                  onJurusan: () => _buka(const AdminJurusanScreen()),
                  onIndustri: () => _buka(const AdminIndustriScreen()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _buka(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.nilai,
    required this.icon,
    required this.warna,
  });

  final String label;
  final String nilai;
  final IconData icon;
  final Color warna;

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
                  Icon(icon, color: warna, size: 28),
                  const Spacer(),
                  Text(
                    nilai,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: warna,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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

/// Grafik batang sederhana tanpa dependency tambahan:
/// setiap bulan = satu bar vertikal (menunggu + disetujui + ditolak).
class _GrafikBulanan extends StatelessWidget {
  const _GrafikBulanan({required this.dataBulan});

  final List<Map<String, dynamic>> dataBulan;

  @override
  Widget build(BuildContext context) {
    final maksimal = dataBulan.fold<int>(0, (maks, bulan) {
      final total = ((bulan['menunggu'] as num? ?? 0) +
              (bulan['disetujui'] as num? ?? 0) +
              (bulan['ditolak'] as num? ?? 0))
          .toInt();
      return total > maks ? total : maks;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: dataBulan.isEmpty || maksimal == 0
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Belum ada pengajuan dalam 6 bulan terakhir.'),
                ),
              )
            : Column(
                children: [
                  SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: dataBulan.map((bulan) {
                        final menunggu = (bulan['menunggu'] as num? ?? 0).toInt();
                        final disetujui =
                            (bulan['disetujui'] as num? ?? 0).toInt();
                        final ditolak = (bulan['ditolak'] as num? ?? 0).toInt();
                        final total = menunggu + disetujui + ditolak;
                        // Segmen tumpuk per status — warna sama dengan
                        // badge status di seluruh aplikasi.
                        Widget segmen(int n, Color warna) => Container(
                              height: n / maksimal * 106.0,
                              width: 28,
                              color: warna,
                            );

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '$total',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 28,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                    color: AppTheme.statusMenunggu.fg,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (ditolak > 0)
                                        segmen(ditolak, AppTheme.statusDitolak.fg),
                                      if (disetujui > 0)
                                        segmen(
                                            disetujui, AppTheme.statusDisetujui.fg),
                                      Container(
                                        height: menunggu / maksimal * 106.0,
                                        color: AppTheme.statusMenunggu.fg,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: dataBulan
                        .map(
                          (bulan) => Expanded(
                            child: Center(
                              child: Text(
                                bulan['label'] as String? ?? '-',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Menu pintasan ke layar kelola.
class _MenuKelola extends StatelessWidget {
  const _MenuKelola({
    required this.onPengajuan,
    required this.onSiswa,
    required this.onJurusan,
    required this.onIndustri,
  });

  final VoidCallback onPengajuan;
  final VoidCallback onSiswa;
  final VoidCallback onJurusan;
  final VoidCallback onIndustri;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Kelola Pengajuan PKL'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onPengajuan,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Data Siswa'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onSiswa,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Data Jurusan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onJurusan,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Data Industri'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onIndustri,
          ),
        ],
      ),
    );
  }
}
