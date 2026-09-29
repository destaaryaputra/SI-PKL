import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Form tambah/edit siswa (wireframe #15).
class FormSiswaScreen extends StatefulWidget {
  const FormSiswaScreen({super.key, this.siswa});

  /// Jika terisi berarti mode edit (lewat layar daftar siswa).
  final Map<String, dynamic>? siswa;

  @override
  State<FormSiswaScreen> createState() => _FormSiswaScreenState();
}

class _FormSiswaScreenState extends State<FormSiswaScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nis;
  late final TextEditingController _nama;
  final _password = TextEditingController();
  int? _jurusanId;
  List<Map<String, dynamic>> _jurusanList = [];
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    final siswa = widget.siswa;
    _nis = TextEditingController(text: siswa?['nis'] as String? ?? '');
    _nama = TextEditingController(text: siswa?['nama'] as String? ?? '');
    final jurusan = siswa?['jurusan'] as Map<String, dynamic>?;
    _jurusanId = jurusan?['id'] as int?;
    _muatJurusan();
  }

  @override
  void dispose() {
    _nis.dispose();
    _nama.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _muatJurusan() async {
    try {
      final data = await _apiService.ambilJurusan();
      if (!mounted) return;
      setState(() => _jurusanList = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat jurusan: $e')),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (widget.siswa == null) {
        await _apiService.tambahSiswa(
          nis: _nis.text.trim(),
          nama: _nama.text.trim(),
          jurusanId: _jurusanId,
          password: _password.text,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Siswa berhasil ditambahkan.')),
        );
      } else {
        await _apiService.ubahSiswa(
          id: widget.siswa!['id'] as int,
          nis: _nis.text.trim(),
          nama: _nama.text.trim(),
          jurusanId: _jurusanId,
          password: _password.text.isEmpty ? null : _password.text,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Data siswa berhasil diperbarui.')),
        );
      }
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.siswa == null ? 'Tambah Siswa' : 'Edit Siswa'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nis,
              decoration: const InputDecoration(
                labelText: 'NIS',
                hintText: 'Contoh: 2413025058',
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'NIS wajib diisi.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                hintText: 'Contoh: Desta Arya Putra',
              ),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Nama wajib diisi.' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _jurusanId,
              decoration: const InputDecoration(
                labelText: 'Jurusan (opsional)',
              ),
              items: _jurusanList
                  .map(
                    (j) => DropdownMenuItem<int>(
                      value: j['id'] as int,
                      child: Text(j['nama'] as String? ?? '-'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _jurusanId = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              decoration: InputDecoration(
                labelText: widget.siswa == null
                    ? 'Password'
                    : 'Password Baru (opsional)',
                hintText: widget.siswa == null ? 'Minimal 6 karakter' : null,
                helperText: widget.siswa == null
                    ? null
                    : 'Kosongkan jika tidak ingin mengganti password.',
              ),
              obscureText: true,
              validator: (value) {
                if (widget.siswa == null &&
                    (value == null || value.length < 6)) {
                  return 'Password minimal 6 karakter.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _menyimpan ? null : _simpan,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _menyimpan
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
