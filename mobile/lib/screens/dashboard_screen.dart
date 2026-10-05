import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/state_views.dart';
import 'peta_industri_screen.dart';
import 'profil_screen.dart';
import 'status_pengajuan_screen.dart';

/// Shell utama siswa sesuai wireframe #3: bottom nav
/// Peta / Riwayat / Pengajuan / Profil, dengan peta sebagai layar utama.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _indeks = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      // Setiap tab punya Scaffold sendiri (lengkap dengan AppBar-nya),
      // jadi tab non-aktif tetap mempertahankan state-nya.
      body: IndexedStack(
        index: _indeks,
        children: const [
          PetaIndustriScreen(),
          RiwayatPenempatanTab(),
          StatusPengajuanScreen(),
          ProfilScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indeks,
        onDestinationSelected: (i) => setState(() => _indeks = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Peta',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Pengajuan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Tab Riwayat Penempatan siswa (FR-17): pengajuan siswa yang sedang login,
/// dikelompokkan per tahun penempatan.
class RiwayatPenempatanTab extends StatefulWidget {
  const RiwayatPenempatanTab({super.key});

  @override
  State<RiwayatPenempatanTab> createState() => _RiwayatPenempatanTabState();
}

class _RiwayatPenempatanTabState extends State<RiwayatPenempatanTab> {
  final _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _riwayatFuture;

  @override
  void initState() {
    super.initState();
    _riwayatFuture = _apiService.ambilRiwayatSiswa();
  }

  Future<void> _muatUlang() async {
    setState(() {
      _riwayatFuture = _apiService.ambilRiwayatSiswa();
    });
    await _riwayatFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Penempatan')),
      body: RefreshIndicator(
        onRefresh: _muatUlang,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _riwayatFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(label: 'Memuat riwayat...');
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  ErrorView(
                    message: 'Gagal memuat riwayat: ${snapshot.error}',
                    onRetry: _muatUlang,
                  ),
                ],
              );
            }

            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyStateView(
                    icon: Icons.history_outlined,
                    title: 'Belum ada riwayat pengajuan PKL',
                    message: 'Ajukan PKL dari peta industri di halaman utama.',
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final tahunData in data) ...[
                  Row(
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
                        '${tahunData['tahun']}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...(tahunData['pengajuan'] as List<dynamic>).map(
                    (p) {
                      final item = p as Map<String, dynamic>;
                      final industri = item['industri'] as Map<String, dynamic>;
                      final status = item['status'] as String? ?? '-';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Builder(
                            builder: (context) {
                              final (:fg, :bg) = AppTheme.warnaStatus(status);
                              return IkonKotak(
                                icon: AppTheme.ikonStatus(status),
                                fg: fg,
                                bg: bg,
                              );
                            },
                          ),
                          title: Text(industri['nama'] as String? ?? '-'),
                          subtitle: Text(
                            '${industri['alamat'] ?? '-'}\n'
                            'Diajukan: ${item['tanggal'] ?? '-'}',
                          ),
                          isThreeLine: true,
                          trailing: StatusBadge(status: status),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
