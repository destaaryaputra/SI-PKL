import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';

/// Daftar jurusan (wireframe #16): daftar + ikon edit & hapus per baris.
class AdminJurusanScreen extends StatefulWidget {
  const AdminJurusanScreen({super.key});

  @override
  State<AdminJurusanScreen> createState() => _AdminJurusanScreenState();
}

class _AdminJurusanScreenState extends State<AdminJurusanScreen> {
  final _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _jurusanFuture;

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  Future<void> _muatUlang() async {
    setState(() {
      _jurusanFuture = _apiService.ambilJurusan();
    });
    await _jurusanFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Jurusan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambah,
        icon: Icon(Icons.add, color: AppTheme.tealGelap),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: _muatUlang,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _jurusanFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(label: 'Memuat daftar jurusan...');
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  ErrorView(
                    message: 'Gagal memuat daftar jurusan: ${snapshot.error}',
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
                    icon: Icons.school_outlined,
                    title: 'Belum ada jurusan',
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: data.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final jurusan = data[index];
                return Card(
                  child: ListTile(
                    leading: IkonKotak(
                      icon: Icons.school,
                      fg: AppTheme.tealGelap,
                      bg: AppTheme.tealLembut,
                    ),
                    title: Text(jurusan['nama'] as String? ?? '-'),
                    subtitle: Text(
                      '${jurusan['jumlah_siswa'] ?? 0} siswa',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit',
                          onPressed: () => _edit(jurusan),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          tooltip: 'Hapus',
                          onPressed: () => _hapus(jurusan),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _tambah() async {
    final controller = TextEditingController();
    final nama = await _dialogNama(
      judul: 'Tambah Jurusan',
      controller: controller,
    );
    if (nama == null || nama.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _apiService.tambahJurusan(nama);
      messenger.showSnackBar(
        const SnackBar(content: Text('Jurusan berhasil ditambahkan.')),
      );
      _muatUlang();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _edit(Map<String, dynamic> jurusan) async {
    final nama = await _dialogNama(
      judul: 'Edit Jurusan',
      controller: TextEditingController(text: jurusan['nama'] as String?),
    );
    if (nama == null || nama.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _apiService.ubahJurusan(jurusan['id'] as int, nama);
      messenger.showSnackBar(
        const SnackBar(content: Text('Jurusan berhasil diperbarui.')),
      );
      _muatUlang();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<String?> _dialogNama({
    required String judul,
    required TextEditingController controller,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(judul),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Jurusan',
            hintText: 'Contoh: Rekayasa Perangkat Lunak',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _hapus(Map<String, dynamic> jurusan) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jurusan'),
        content: Text(
          'Yakin ingin menghapus jurusan "${jurusan['nama']}"? '
          'Jurusan tidak bisa dihapus jika masih dipakai siswa atau industri.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _apiService.hapusJurusan(jurusan['id'] as int);
      messenger.showSnackBar(
        const SnackBar(content: Text('Jurusan berhasil dihapus.')),
      );
      _muatUlang();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
