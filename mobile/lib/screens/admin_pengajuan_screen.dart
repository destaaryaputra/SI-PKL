import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';
import 'admin_pengajuan_detail_screen.dart';

/// Daftar pengajuan PKL untuk admin. Ketuk kartu untuk membuka
/// detail pengajuan (wireframe #20) dengan tombol Tolak/Setujui.
class AdminPengajuanScreen extends StatefulWidget {
  const AdminPengajuanScreen({super.key});

  @override
  State<AdminPengajuanScreen> createState() => _AdminPengajuanScreenState();
}

class _AdminPengajuanScreenState extends State<AdminPengajuanScreen> {
  final _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _pengajuanFuture;

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  Future<void> _muatUlang() async {
    setState(() {
      _pengajuanFuture = _apiService.ambilPengajuanAdmin();
    });
    await _pengajuanFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan PKL')),
      body: RefreshIndicator(
        onRefresh: _muatUlang,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _pengajuanFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(label: 'Memuat pengajuan...');
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  ErrorView(
                    message: 'Gagal memuat pengajuan: ${snapshot.error}',
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
                    icon: Icons.inbox_outlined,
                    title: 'Belum ada pengajuan PKL',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = data[index];
                final industri = item['industri'] as Map<String, dynamic>?;
                final pengguna = item['pengguna'] as Map<String, dynamic>?;
                final status = item['status'] as String? ?? '-';

                return Card(
                  child: ListTile(
                    onTap: () => _bukaDetail(item),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.warnaStatus(status).bg,
                      child: Icon(
                        AppTheme.ikonStatus(status),
                        color: AppTheme.warnaStatus(status).fg,
                      ),
                    ),
                    title: Text(industri?['nama'] as String? ?? 'Industri'),
                    subtitle: Text(
                      '${pengguna?['nama'] ?? '-'} • ${pengguna?['nis'] ?? '-'}',
                    ),
                    trailing: StatusBadge(status: status),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _bukaDetail(Map<String, dynamic> item) async {
    final berubah = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminPengajuanDetailScreen(pengajuan: item),
      ),
    );
    if (berubah == true) _muatUlang();
  }
}
