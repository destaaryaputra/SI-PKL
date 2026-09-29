import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/state_views.dart';
import 'form_siswa_screen.dart';

/// Daftar siswa (wireframe #14): pencarian, tombol tambah,
/// serta aksi edit & hapus per baris.
class AdminSiswaScreen extends StatefulWidget {
  const AdminSiswaScreen({super.key});

  @override
  State<AdminSiswaScreen> createState() => _AdminSiswaScreenState();
}

class _AdminSiswaScreenState extends State<AdminSiswaScreen> {
  final _apiService = ApiService();
  final _cariController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _siswaFuture;

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  @override
  void dispose() {
    _cariController.dispose();
    super.dispose();
  }

  Future<void> _muatUlang() async {
    setState(() {
      _siswaFuture = _apiService.ambilSiswa(cari: _cariController.text.trim());
    });
    await _siswaFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Siswa'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bukaFormTambah,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchBar(
              controller: _cariController,
              hintText: 'Cari nama atau NIS...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_cariController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _cariController.clear();
                      _muatUlang();
                    },
                  ),
              ],
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _muatUlang(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _muatUlang,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _siswaFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingView(label: 'Memuat daftar siswa...');
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        ErrorView(
                          message: 'Gagal memuat daftar siswa: ${snapshot.error}',
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
                          icon: Icons.people_outline,
                          title: 'Tidak ada siswa ditemukan',
                          message: 'Coba ubah kata kunci pencarian.',
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: data.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final siswa = data[index];
                      final jurusan = siswa['jurusan'] as Map<String, dynamic>?;
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
                            '${jurusan != null ? ' • ${jurusan['nama']}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                                onPressed: () => _bukaFormEdit(siswa),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                tooltip: 'Hapus',
                                onPressed: () => _hapus(siswa),
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
          ),
        ],
      ),
    );
  }

  Future<void> _bukaFormTambah() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FormSiswaScreen()),
    );
    _muatUlang();
  }

  Future<void> _bukaFormEdit(Map<String, dynamic> siswa) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FormSiswaScreen(siswa: siswa)),
    );
    _muatUlang();
  }

  Future<void> _hapus(Map<String, dynamic> siswa) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: Text(
          'Yakin ingin menghapus ${siswa['nama'] ?? 'siswa ini'}? '
          'Data yang sudah dihapus tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _apiService.hapusSiswa(siswa['id'] as int);
      messenger.showSnackBar(
        const SnackBar(content: Text('Siswa berhasil dihapus.')),
      );
      _muatUlang();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
