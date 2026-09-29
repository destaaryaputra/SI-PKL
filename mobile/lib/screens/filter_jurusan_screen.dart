import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Filter jurusan sebagai bottom sheet, sesuai wireframe #5.
/// Menampilkan checkbox "Semua Jurusan" + daftar jurusan multi-select,
/// dan tombol "Terapkan".
///
/// Dipakai lewat showModalBottomSheet; hasilnya berupa `List<int>` id
/// jurusan terpilih (kosong/null berarti semua jurusan).
class FilterJurusanSheet extends StatefulWidget {
  const FilterJurusanSheet({super.key, this.selectedJurusanIds = const []});

  final List<int> selectedJurusanIds;

  @override
  State<FilterJurusanSheet> createState() => _FilterJurusanSheetState();
}

class _FilterJurusanSheetState extends State<FilterJurusanSheet> {
  final _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _jurusanFuture;
  late List<int> _selectedJurusanIds;

  @override
  void initState() {
    super.initState();
    _selectedJurusanIds = widget.selectedJurusanIds.toList();
    _jurusanFuture = _apiService.ambilJurusan();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Judul + tombol tutup (wireframe #5).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter Jurusan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _jurusanFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Gagal memuat jurusan: ${snapshot.error}'),
                    );
                  }

                  final jurusanList = snapshot.data ?? [];
                  if (jurusanList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Belum ada data jurusan'),
                    );
                  }

                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      CheckboxListTile(
                        title: const Text('Semua Jurusan'),
                        value: _selectedJurusanIds.isEmpty,
                        onChanged: (value) {
                          if (value == true) {
                            setState(() => _selectedJurusanIds.clear());
                          }
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      ...jurusanList.map((jurusan) {
                        final id = jurusan['id'] as int;
                        final nama = jurusan['nama'] as String;

                        return CheckboxListTile(
                          title: Text(nama),
                          value: _selectedJurusanIds.contains(id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedJurusanIds.add(id);
                              } else {
                                _selectedJurusanIds.remove(id);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            // Tombol Terapkan (wireframe #5).
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final result =
                        _selectedJurusanIds.isEmpty ? null : _selectedJurusanIds;
                    Navigator.of(context).pop(result);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Terapkan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
