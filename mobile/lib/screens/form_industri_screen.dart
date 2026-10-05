import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/animasi.dart';

/// Form tambah/edit industri (wireframe #19).
class FormIndustriScreen extends StatefulWidget {
  const FormIndustriScreen({super.key, this.industri});

  /// Jika terisi berarti mode edit.
  final Map<String, dynamic>? industri;

  @override
  State<FormIndustriScreen> createState() => _FormIndustriScreenState();
}

class _FormIndustriScreenState extends State<FormIndustriScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _alamat;
  late final TextEditingController _logoUrl;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _kuota;
  List<int> _jurusanTerpilih = [];
  List<Map<String, dynamic>> _jurusanList = [];
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    final industri = widget.industri;
    _nama = TextEditingController(text: industri?['nama'] as String? ?? '');
    _alamat = TextEditingController(text: industri?['alamat'] as String? ?? '');
    _logoUrl = TextEditingController(
      text: industri?['logo_url'] as String? ?? '',
    );
    _latitude = TextEditingController(
      text: industri?['latitude']?.toString() ?? '',
    );
    _longitude = TextEditingController(
      text: industri?['longitude']?.toString() ?? '',
    );
    _kuota = TextEditingController(
      text: industri?['kuota']?.toString() ?? '',
    );
    _jurusanTerpilih =
        (industri?['jurusan_ids'] as List<dynamic>? ?? [])
            .map((e) => e as int)
            .toList();
    _muatJurusan();
  }

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _logoUrl.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _kuota.dispose();
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
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final data = (
      nama: _nama.text.trim(),
      alamat: _alamat.text.trim(),
      logoUrl: _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
      latitude: double.tryParse(_latitude.text.trim().replaceAll(',', '.')),
      longitude: double.tryParse(_longitude.text.trim().replaceAll(',', '.')),
      kuota: int.tryParse(_kuota.text.trim()),
    );

    try {
      if (widget.industri == null) {
        await _apiService.tambahIndustri(
          nama: data.nama,
          alamat: data.alamat,
          logoUrl: data.logoUrl,
          latitude: data.latitude!,
          longitude: data.longitude!,
          kuota: data.kuota!,
          jurusanIds: _jurusanTerpilih,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Industri berhasil ditambahkan.')),
        );
      } else {
        await _apiService.ubahIndustri(
          id: widget.industri!['id'] as int,
          nama: data.nama,
          alamat: data.alamat,
          logoUrl: data.logoUrl,
          latitude: data.latitude!,
          longitude: data.longitude!,
          kuota: data.kuota!,
          jurusanIds: _jurusanTerpilih,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Data industri berhasil diperbarui.')),
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
        title: Text(widget.industri == null ? 'Tambah Industri' : 'Edit Industri'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(
                labelText: 'Nama Industri',
                hintText: 'Contoh: CV Karya Digital',
              ),
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Nama wajib diisi.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alamat,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                hintText: 'Contoh: Jl. Sudirman No. 1, Bandar Lampung',
              ),
              textInputAction: TextInputAction.next,
              minLines: 2,
              maxLines: 3,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Alamat wajib diisi.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _logoUrl,
              decoration: const InputDecoration(
                labelText: 'URL Logo (opsional)',
                hintText: 'Contoh: /logo/newus.png atau https://...',
                helperText:
                    'Path logo di server (mis. /logo/nama.png) atau URL lengkap.',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitude,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '-5.3971',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) =>
                        double.tryParse(value?.replaceAll(',', '.') ?? '') == null
                            ? 'Latitude tidak valid.'
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _longitude,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '105.2668',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) =>
                        double.tryParse(value?.replaceAll(',', '.') ?? '') == null
                            ? 'Longitude tidak valid.'
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kuota,
              decoration: const InputDecoration(
                labelText: 'Kuota',
                hintText: 'Contoh: 5',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final nilai = int.tryParse(value ?? '');
                if (nilai == null || nilai < 1 || nilai > 1000) {
                  return 'Kuota harus angka 1-1000.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Checkbox jurusan (wireframe #19).
            Text('Jurusan yang bisa mendaftar', style: Theme.of(context).textTheme.titleSmall),
            if (_jurusanList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Memuat jurusan...'),
              )
            else
              ..._jurusanList.map(
                (jurusan) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(jurusan['nama'] as String? ?? '-'),
                  value: _jurusanTerpilih.contains(jurusan['id']),
                  onChanged: (terpilih) {
                    setState(() {
                      final id = jurusan['id'] as int;
                      if (terpilih == true) {
                        _jurusanTerpilih.add(id);
                      } else {
                        _jurusanTerpilih.remove(id);
                      }
                    });
                  },
                ),
              ),
            const SizedBox(height: 24),
            TombolMuat(
              teks: 'Simpan',
              onPressed: _menyimpan ? null : _simpan,
              memuat: _menyimpan,
              pertahankanTeks: false,
            ),
          ],
        ),
      ),
    );
  }
}
