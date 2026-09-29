import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';

/// Status pengajuan siswa dengan tab filter,
/// sesuai wireframe #11 (Semua / Pending / Disetujui / Ditolak).
class StatusPengajuanScreen extends StatefulWidget {
  const StatusPengajuanScreen({super.key});

  @override
  State<StatusPengajuanScreen> createState() => _StatusPengajuanScreenState();
}

class _StatusPengajuanScreenState extends State<StatusPengajuanScreen> {
  final _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _pengajuanFuture;

  @override
  void initState() {
    super.initState();
    _pengajuanFuture = _apiService.ambilPengajuan();
  }

  Future<void> _muatUlang() async {
    setState(() => _pengajuanFuture = _apiService.ambilPengajuan());
    await _pengajuanFuture;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Status Pengajuan'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Semua'),
              Tab(text: 'Menunggu'),
              Tab(text: 'Disetujui'),
              Tab(text: 'Ditolak'),
            ],
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _pengajuanFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(label: 'Memuat pengajuan...');
            }
            if (snapshot.hasError) {
              return ErrorView(
                message: 'Gagal memuat pengajuan: ${snapshot.error}',
                onRetry: _muatUlang,
              );
            }
            final data = snapshot.data ?? [];

            return TabBarView(
              children: [
                _DaftarPengajuan(items: data, onRefresh: _muatUlang),
                _DaftarPengajuan(
                  items: _saring(data, 'menunggu'),
                  onRefresh: _muatUlang,
                ),
                _DaftarPengajuan(
                  items: _saring(data, 'disetujui'),
                  onRefresh: _muatUlang,
                ),
                _DaftarPengajuan(
                  items: _saring(data, 'ditolak'),
                  onRefresh: _muatUlang,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _saring(
    List<Map<String, dynamic>> data,
    String status,
  ) {
    return data.where((item) => item['status'] == status).toList();
  }
}

class _DaftarPengajuan extends StatelessWidget {
  const _DaftarPengajuan({required this.items, required this.onRefresh});

  final List<Map<String, dynamic>> items;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            EmptyStateView(
              icon: Icons.inbox_outlined,
              title: 'Belum ada pengajuan PKL',
              message: 'Ajukan dari halaman detail industri.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final industri = item['industri'] as Map<String, dynamic>?;
          final status = item['status'] as String? ?? '-';
          final catatan = item['catatan'] as String?;
          final sudahDiproses = status == 'disetujui' || status == 'ditolak';

          return Card(
            child: ListTile(
              leading: Icon(
                AppTheme.ikonStatus(status),
                color: AppTheme.warnaStatus(status).fg,
              ),
              title: Text(industri?['nama'] as String? ?? 'Industri'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sudahDiproses && catatan != null && catatan.isNotEmpty)
                    Text(
                      'Catatan admin: $catatan',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              trailing: StatusBadge(status: status),
            ),
          );
        },
      ),
    );
  }
}
