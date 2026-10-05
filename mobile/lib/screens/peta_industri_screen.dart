import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/industri.dart';
import '../models/tempat_sekitar.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'filter_jurusan_screen.dart';
import 'industry_detail_screen.dart';
import '../widgets/animasi.dart';

/// Layar utama siswa sesuai wireframe #3 & #6: peta penuh dengan
/// search bar + filter di atasnya, popup saat marker diketuk,
/// dan panel hasil pencarian tempat sekitar.
class PetaIndustriScreen extends StatefulWidget {
  const PetaIndustriScreen({super.key});

  @override
  State<PetaIndustriScreen> createState() => _PetaIndustriScreenState();
}

class _PetaIndustriScreenState extends State<PetaIndustriScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  final _mapController = MapController();

  List<Industri> _industri = [];
  bool _memuat = true;
  String? _galat;
  List<int> _selectedJurusanIds = [];
  Industri? _markerTerpilih;

  Future<List<TempatSekitar>>? _tempatFuture;

  static const _pusatLampung = LatLng(-5.3971, 105.2668);

  @override
  void initState() {
    super.initState();
    _muatIndustri();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _muatIndustri() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final hasil = await _apiService.ambilIndustri(
        cari: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        jurusanIds: _selectedJurusanIds,
      );
      if (!mounted) return;
      setState(() {
        _industri = hasil;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galat = 'Gagal memuat data industri: $e';
        _memuat = false;
      });
    }
  }

  Future<void> _bukaFilterJurusan() async {
    final result = await showModalBottomSheet<List<int>?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FilterJurusanSheet(selectedJurusanIds: _selectedJurusanIds),
    );

    if (result == null) return;
    setState(() => _selectedJurusanIds = result);
    _muatIndustri();
  }

  void _ketukMarker(Industri industri) {
    setState(() => _markerTerpilih = industri);
    // Geser peta agar popup tidak terpotong tepi layar.
    _mapController.move(
      LatLng(industri.latitude, industri.longitude),
      _mapController.camera.zoom < 14 ? 15 : _mapController.camera.zoom,
    );
  }

  void _bukaDetail(Industri industri) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IndustryDetailScreen(industriId: industri.id),
      ),
    );
  }

  void _cariTempat() {
    setState(() {
      _tempatFuture = _apiService.ambilTempatSekitar(
        latitude: _pusatLampung.latitude,
        longitude: _pusatLampung.longitude,
        cari: _searchController.text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _pusatLampung,
              initialZoom: 12,
            ),
            children: [
              // Tile OpenStreetMap standar: gratis tanpa API key
              // (Carto kini menuntut API key sehingga peta kosong).
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sipkl.mobile',
              ),
              MarkerLayer(
                markers: _industri.map((item) {
                  final terpilih = item.id == _markerTerpilih?.id;
                  return Marker(
                    point: LatLng(item.latitude, item.longitude),
                    width: 40,
                    height: 46,
                    // Box sepenuhnya di atas titik koordinat (bottom edge
                    // = titik industri) agar ujung pin tepat menunjuk lokasi.
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _ketukMarker(item),
                      child: _PinIndustri(
                        logoUrl: item.logoUrl,
                        warna: terpilih ? warna.primary : AppTheme.navy,
                        terpilih: terpilih,
                      ),
                    ),
                  );
                }).toList(),
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors',
                      onTap: () {}),
                ],
              ),
            ],
          ),

          // Search bar + filter mengambang di atas peta (wireframe #3).
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) {
                        _muatIndustri();
                        _cariTempat();
                      },
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Cari industri...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Badge(
                    isLabelVisible: _selectedJurusanIds.isNotEmpty,
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: warna.surface,
                      ),
                      onPressed: _bukaFilterJurusan,
                      icon: const Icon(Icons.filter_list),
                      tooltip: 'Filter jurusan',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Popup detail saat marker diketuk (wireframe #6).
          if (_markerTerpilih != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _PopupMarkerAnimasi(
                industri: _markerTerpilih!,
                onLihatDetail: () => _bukaDetail(_markerTerpilih!),
                onTutup: () => setState(() => _markerTerpilih = null),
              ),
            ),

          // Panel hasil pencarian tempat sekitar.
          if (_tempatFuture != null && _markerTerpilih == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _HasilTempatPanel(future: _tempatFuture!),
            ),

          // Indikator memuat: pill kecil mengambang agar terbaca di atas tile peta.
          if (_memuat)
            const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: _MapStatusPill(
                  icon: Icons.downloading,
                  label: 'Memuat industri...',
                ),
              ),
            ),
          if (_galat != null)
            Positioned(
              top: 100,
              left: 24,
              right: 24,
              child: _MapStatusPill(
                icon: Icons.cloud_off_outlined,
                label: 'Gagal memuat. Ketuk ikon cari untuk mencoba lagi.',
                error: true,
              ),
            ),
        ],
      ),
    );
  }
}

/// Kartu popup di atas marker (wireframe #6) — muncul dengan pop halus.
class _PopupMarkerAnimasi extends StatelessWidget {
  const _PopupMarkerAnimasi({
    required this.industri,
    required this.onLihatDetail,
    required this.onTutup,
  });

  final Industri industri;
  final VoidCallback onLihatDetail;
  final VoidCallback onTutup;

  @override
  Widget build(BuildContext context) {
    return MunculSkala(
      child: _PopupMarker(
        industri: industri,
        onLihatDetail: onLihatDetail,
        onTutup: onTutup,
      ),
    );
  }
}

/// Kartu popup di atas marker — isinya tanpa animasi (dipakai saat direstore state).
class _PopupMarker extends StatelessWidget {
  const _PopupMarker({
    required this.industri,
    required this.onLihatDetail,
    required this.onTutup,
  });

  final Industri industri;
  final VoidCallback onLihatDetail;
  final VoidCallback onTutup;

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: warna.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Logo industri (fallback ikon pabrik) agar popup konsisten
                // dengan pin peta.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.tealLembut,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: industri.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            industri.logoUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.factory,
                              size: 20,
                              color: AppTheme.tealGelap,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.factory,
                          size: 20,
                          color: AppTheme.tealGelap,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    industri.nama,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onTutup,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              industri.alamat,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: warna.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: industri.sisaKuota > 0
                    ? AppTheme.statusDisetujui.bg
                    : AppTheme.statusDitolak.bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                industri.sisaKuota > 0
                    ? 'Sisa Kuota: ${industri.sisaKuota}'
                    : 'Kuota Penuh',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: industri.sisaKuota > 0
                      ? AppTheme.statusDisetujui.fg
                      : AppTheme.statusDitolak.fg,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onLihatDetail,
                child: const Text('Lihat Detail'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill status mengambang di atas peta (memuat / galat) — flat, terbaca di atas tile.
class _MapStatusPill extends StatelessWidget {
  const _MapStatusPill({
    required this.icon,
    required this.label,
    this.error = false,
  });

  final IconData icon;
  final String label;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: error ? warna.errorContainer : warna.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: warna.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: error ? warna.error : warna.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: error ? warna.onErrorContainer : warna.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel hasil pencarian tempat sekitar (Overpass/OSM).
class _HasilTempatPanel extends StatelessWidget {
  const _HasilTempatPanel({required this.future});

  final Future<List<TempatSekitar>> future;

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: warna.outlineVariant),
      ),
      child: FutureBuilder<List<TempatSekitar>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Pencarian gagal: ${snapshot.error}'),
            );
          }

          final places = snapshot.data ?? [];
          if (places.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada tempat yang ditemukan.'),
            );
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(place.nama),
                  subtitle: Text(
                    '${place.kategori}${place.alamat.isEmpty ? '' : ' - ${place.alamat}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Pin map branded untuk industri: logo perusahaan (fallback ikon pabrik)
/// + ujung panah bawah.
class _PinIndustri extends StatelessWidget {
  const _PinIndustri({
    this.logoUrl,
    required this.warna,
    this.terpilih = false,
  });

  final String? logoUrl;
  final Color warna;
  final bool terpilih;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: terpilih ? warna : Colors.black26,
              width: terpilih ? 3 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: logoUrl != null
              ? ClipOval(
                  child: Image.network(
                    logoUrl!,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : _fallbackIkon(),
                    errorBuilder: (_, _, _) => _fallbackIkon(),
                  ),
                )
              : _fallbackIkon(),
        ),
        const SizedBox(height: 1),
        CustomPaint(
          size: const Size(14, 10),
          painter: _PinArrowPainter(warna),
        ),
      ],
    );
  }

  Widget _fallbackIkon() {
    return Icon(
      Icons.factory,
      size: 16,
      color: warna, // navy brand
    );
  }
}

class _PinArrowPainter extends CustomPainter {
  _PinArrowPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}