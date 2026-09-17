import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/industri.dart';
import '../models/tempat_sekitar.dart';
import '../services/api_service.dart';
import 'industry_detail_screen.dart';

class PetaIndustriScreen extends StatefulWidget {
  const PetaIndustriScreen({super.key});

  @override
  State<PetaIndustriScreen> createState() => _PetaIndustriScreenState();
}

class _PetaIndustriScreenState extends State<PetaIndustriScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  late Future<List<Industri>> _industriFuture;
  Future<List<TempatSekitar>>? _tempatFuture;

  static const _pusatLampung = LatLng(-5.3971, 105.2668);

  @override
  void initState() {
    super.initState();
    _industriFuture = _apiService.ambilIndustri();
  }

  void _bukaDetail(Industri industri) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IndustryDetailScreen(industriId: industri.id),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Peta Industri')),
      body: FutureBuilder<List<Industri>>(
        future: _industriFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat peta: ${snapshot.error}'));
          }

          final industri = snapshot.data ?? [];
          return Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: _pusatLampung,
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sipkl.mobile',
                  ),
                  MarkerLayer(
                    markers: industri.map((item) {
                      return Marker(
                        point: LatLng(item.latitude, item.longitude),
                        width: 120,
                        height: 80,
                        child: GestureDetector(
                          onTap: () => _bukaDetail(item),
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 38,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _cariTempat(),
                    decoration: InputDecoration(
                      hintText: 'Cari tempat PKL sekitar',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        onPressed: _cariTempat,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              if (_tempatFuture != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _HasilTempatPanel(future: _tempatFuture!),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HasilTempatPanel extends StatelessWidget {
  const _HasilTempatPanel({required this.future});

  final Future<List<TempatSekitar>> future;

  @override
  Widget build(BuildContext context) {
    return Card(
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
