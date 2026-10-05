import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animasi.dart';

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
                      Expanded(
                        child: Text(
                          _industri?['nama'] as String? ?? 'Industri',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _industri?['alamat'] as String? ?? '-',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
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
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.teal,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Catatan',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
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
          AnimatedSwitcher(
            duration: Motion.sedang,
            switchInCurve: Motion.std,
            switchOutCurve: Motion.std,
            layoutBuilder: (currentChild, previousChildren) {
              // Anak lama dibiarkan menempati ruang (opacity 0) supaya tinggi
              // area tidak meloncat saat kartu "diproses" menyusul.
              final anak = <Widget>[
                for (final lama in previousChildren)
                  Opacity(opacity: 0, child: lama),
              ];
              if (currentChild != null) anak.add(currentChild);
              return Stack(alignment: Alignment.center, children: anak);
            },
            child: sudahDiproses
                ? Card(
                    key: const ValueKey('sudahDiproses'),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) {
                              final (:fg, :bg) = AppTheme.warnaStatus(_status);
                              return IkonKotak(
                                icon: AppTheme.ikonStatus(_status),
                                fg: fg,
                                bg: bg,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pengajuan ini sudah $_status. Catatan tidak bisa diubah lagi.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('aksi'),
                    children: [
                      Expanded(
                        child: TombolMuat(
                          teks: 'Tolak',
                          ikon: Icons.close,
                          pertahankanTeks: true,
                          memuat: _memproses,
                          garis: true,
                          warnaSpinner: AppTheme.statusDitolak.fg,
                          onPressed: _tolak,
                          gaya: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.statusDitolak.fg,
                            side: BorderSide(color: AppTheme.statusDitolak.fg),
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TombolMuat(
                          teks: 'Setujui',
                          ikon: Icons.check,
                          pertahankanTeks: true,
                          memuat: _memproses,
                          warnaSpinner: Colors.white,
                          onPressed: _setujui,
                          gaya: FilledButton.styleFrom(
                            backgroundColor: AppTheme.statusDisetujui.fg,
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _baris(String label, String nilai) {
    // Status tampil sebagai badge; nilai lain tetap teks tebal.
    final Widget trailing = label == 'Status'
        ? StatusBadge(status: nilai, ikon: true)
        : Text(
            nilai,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          );

    return ListTile(
      dense: true,
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      trailing: trailing,
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
