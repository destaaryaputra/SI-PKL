import 'package:flutter/material.dart';

import '../models/industri.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';
import 'form_industri_screen.dart';

/// Daftar industri untuk admin (wireframe #18): pencarian, tombol tambah,
/// serta aksi edit & hapus per baris.
class AdminIndustriScreen extends StatefulWidget {
  const AdminIndustriScreen({super.key});

  @override
  State<AdminIndustriScreen> createState() => _AdminIndustriScreenState();
}

class _AdminIndustriScreenState extends State<AdminIndustriScreen> {
  final _apiService = ApiService();
  final _cariController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _industriFuture;

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
      _industriFuture = _apiService.ambilIndustriMentah(
        cari: _cariController.text.trim(),
      );
    });
    await _industriFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Industri')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bukaFormTambah,
        icon: Icon(Icons.add_business, color: AppTheme.navy),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchBar(
              controller: _cariController,
              hintText: 'Cari nama industri...',
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
                future: _industriFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingView(label: 'Memuat daftar industri...');
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        ErrorView(
                          message: 'Gagal memuat daftar industri: ${snapshot.error}',
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
                          icon: Icons.business_outlined,
                          title: 'Tidak ada industri ditemukan',
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
                      final industri = data[index];
                      final jurusanList =
                          industri['jurusan'] as List<dynamic>? ?? [];
                      final logoUrl = Industri.resolveLogoUrl(
                        industri['logo_url'] as String?,
                      );
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.tealLembut,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: logoUrl == null
                                  ? const Icon(
                                      Icons.business,
                                      color: AppTheme.tealGelap,
                                    )
                                  : Image.network(
                                      logoUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (_, child, progress) =>
                                          progress == null
                                              ? child
                                              : const Icon(
                                                  Icons.business,
                                                  color: AppTheme.tealGelap,
                                                ),
                                      errorBuilder: (_, _, _) =>
                                          const Icon(
                                            Icons.business,
                                            color: AppTheme.tealGelap,
                                          ),
                                    ),
                            ),
                          ),
                          title: Text(industri['nama'] as String? ?? '-'),
                          subtitle: Text(
                            'Kuota ${industri['kuota'] ?? '-'}'
                            '${jurusanList.isNotEmpty ? ' • ${jurusanList.length} jurusan' : ''}',
                          ),
                          isThreeLine: true,
                          dense: false,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                                onPressed: () => _bukaFormEdit(industri),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                tooltip: 'Hapus',
                                onPressed: () => _hapus(industri),
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
      MaterialPageRoute(builder: (_) => const FormIndustriScreen()),
    );
    _muatUlang();
  }

  Future<void> _bukaFormEdit(Map<String, dynamic> industri) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormIndustriScreen(industri: industri),
      ),
    );
    _muatUlang();
  }

  Future<void> _hapus(Map<String, dynamic> industri) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Industri'),
        content: Text(
          'Yakin ingin menghapus "${industri['nama']}"? '
          'Industri tidak bisa dihapus jika sudah ada pengajuan PKL yang '
          'terkait dengannya.',
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
      await _apiService.hapusIndustri(industri['id'] as int);
      messenger.showSnackBar(
        const SnackBar(content: Text('Industri berhasil dihapus.')),
      );
      _muatUlang();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
