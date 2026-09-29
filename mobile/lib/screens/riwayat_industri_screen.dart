import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/state_views.dart';

/// Riwayat penempatan PKL di satu industri (wireframe #7, FR-17):
/// daftar tahun, tiap tahun berisi siswa yang pernah ditempatkan.
class RiwayatIndustriScreen extends StatefulWidget {
  const RiwayatIndustriScreen({super.key, required this.industriId, this.namaIndustri});

  final int industriId;
  final String? namaIndustri;

  @override
  State<RiwayatIndustriScreen> createState() => _RiwayatIndustriScreenState();
}

class _RiwayatIndustriScreenState extends State<RiwayatIndustriScreen> {
  final _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _riwayatFuture;

  @override
  void initState() {
    super.initState();
    _riwayatFuture = _apiService.ambilRiwayatIndustri(widget.industriId);
  }

  Future<void> _muatUlang() async {
    setState(() {
      _riwayatFuture = _apiService.ambilRiwayatIndustri(widget.industriId);
    });
    await _riwayatFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.namaIndustri ?? 'Riwayat Penempatan',
          overflow: TextOverflow.ellipsis,
        ),
      ),
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
                  SizedBox(height: 80),
                  EmptyStateView(
                    icon: Icons.history_outlined,
                    title: 'Belum ada riwayat penempatan',
                    message: 'Belum ada siswa yang pernah ditempatkan di industri ini.',
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final tahunData in data) ...[
                  Text(
                    '${tahunData['tahun']}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Text(
                    '${tahunData['jumlah']} siswa ditempatkan',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ...(tahunData['siswa'] as List<dynamic>).map(
                    (s) {
                      final siswa = s as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              (siswa['nama'] as String? ?? '?')
                                  .characters
                                  .first
                                  .toUpperCase(),
                            ),
                          ),
                          title: Text(siswa['nama'] as String? ?? '-'),
                          subtitle: Text(
                            'NIS ${siswa['nis'] ?? '-'}'
                            '${siswa['jurusan'] != null ? ' • ${siswa['jurusan']}' : ''}',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
