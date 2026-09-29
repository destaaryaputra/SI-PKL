import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Detail pengajuan PKL (wireframe #20): info pengajuan + catatan,
/// dengan tombol Tolak / Setujui di bawah.
class AdminPengajuanDetailScreen extends StatefulWidget {
  const AdminPengajuanDetailScreen({super.key, required this.pengajuan});

  final Map<String, dynamic> pengajuan;

  @override
  State<AdminPengajuanDetailScreen> createState() =>
      _AdminPengajuanDetailScreenState();
}

class _AdminPengajuanDetailScreenState
    extends State<AdminPengajuanDetailScreen> {
  final _apiService = ApiService();
  final _catatanController = TextEditingController();
  bool _memproses = false;

  @override
  void initState() {
    super.initState();
    _catatanController.text = widget.pengajuan['catatan'] as String? ?? '';
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _industri =>
      widget.pengajuan['industri'] as Map<String, dynamic>?;

  Map<String, dynamic>? get _pengguna =>
      widget.pengajuan['pengguna'] as Map<String, dynamic>?;

  String get _status => widget.pengajuan['status'] as String? ?? '-';

  @override
  Widget build(BuildContext context) {
    final sudahDiproses = _status != 'menunggu';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengajuan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info industri.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _industri?['nama'] as String? ?? 'Industri',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(_industri?['alamat'] as String? ?? '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Info siswa & pengajuan.
          Card(
            child: Column(
              children: [
                _baris('Nama Siswa', _pengguna?['nama'] as String? ?? '-'),
                _baris('NIS', _pengguna?['nis'] as String? ?? '-'),
                _baris('Status', _status),
                _baris(
                  'Tanggal Pengajuan',
                  widget.pengajuan['tanggal_pengajuan'] as String? ??
                      widget.pengajuan['created_at'] as String? ??
                      '-',
                ),
                _baris('Kuota Industri', '${_industri?['kuota'] ?? '-'}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Catatan (dari siswa &/atau admin).
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _catatanController,
                    maxLines: 3,
                    enabled: !sudahDiproses,
                    decoration: const InputDecoration(
                      hintText:
                          'Tambahkan catatan (wajib saat menolak, opsional saat menyetujui)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Tolak / Setujui (wireframe #20).
          if (!sudahDiproses)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _memproses ? null : _tolak,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.statusDitolak.fg,
                      side: BorderSide(color: AppTheme.statusDitolak.fg),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _memproses ? null : _setujui,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.statusDisetujui.fg,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Setujui'),
                  ),
                ),
              ],
            )
          else
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _status == 'disetujui'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _status == 'disetujui'
                          ? AppTheme.statusDisetujui.fg
                          : AppTheme.statusDitolak.fg,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pengajuan ini sudah $_status. Catatan tidak bisa diubah lagi.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _baris(String label, String nilai) {
    return ListTile(
      dense: true,
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      trailing: Text(
        nilai,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _setujui() async {
    await _proses(
      aksi: () => _apiService.setujuiPengajuan(
        widget.pengajuan['id'] as int,
        catatan: _catatanController.text.trim().isEmpty
            ? null
            : _catatanController.text.trim(),
      ),
      pesanSukses: 'Pengajuan disetujui.',
    );
  }

  Future<void> _tolak() async {
    if (_catatanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan wajib diisi saat menolak pengajuan.'),
        ),
      );
      return;
    }
    await _proses(
      aksi: () => _apiService.tolakPengajuan(
        widget.pengajuan['id'] as int,
        catatan: _catatanController.text.trim(),
      ),
      pesanSukses: 'Pengajuan ditolak.',
    );
  }

  Future<void> _proses({
    required Future<void> Function() aksi,
    required String pesanSukses,
  }) async {
    setState(() => _memproses = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await aksi();
      messenger.showSnackBar(SnackBar(content: Text(pesanSukses)));
      navigator.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
      if (mounted) setState(() => _memproses = false);
    }
  }
}
