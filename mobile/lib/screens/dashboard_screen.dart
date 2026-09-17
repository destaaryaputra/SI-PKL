import 'package:flutter/material.dart';

import '../models/industri.dart';
import '../services/api_service.dart';
import 'industry_detail_screen.dart';
import 'peta_industri_screen.dart';
import 'status_pengajuan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  final _searchController = TextEditingController();
  late Future<List<Industri>> _industriFuture;

  @override
  void initState() {
    super.initState();
    _industriFuture = _apiService.ambilIndustri();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _cari() {
    setState(() {
      _industriFuture = _apiService.ambilIndustri(
        cari: _searchController.text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Industri'),
        actions: [
          IconButton(
            tooltip: 'Lihat peta',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PetaIndustriScreen()),
              );
            },
            icon: const Icon(Icons.map),
          ),
          IconButton(
            tooltip: 'Status pengajuan',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StatusPengajuanScreen(),
                ),
              );
            },
            icon: const Icon(Icons.assignment),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _industriFuture = _apiService.ambilIndustri());
          await _industriFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              onSubmitted: (_) => _cari(),
              decoration: InputDecoration(
                labelText: 'Cari industri',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _cari,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Industri>>(
              future: _industriFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Gagal memuat data industri: ${snapshot.error}');
                }
                final industri = snapshot.data ?? [];
                if (industri.isEmpty) {
                  return const Text('Belum ada industri yang sesuai.');
                }
                return Column(
                  children: industri
                      .map((item) => _IndustriCard(industri: item))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IndustriCard extends StatelessWidget {
  const _IndustriCard({required this.industri});

  final Industri industri;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => IndustryDetailScreen(industriId: industri.id),
            ),
          );
        },
        leading: const CircleAvatar(child: Icon(Icons.business)),
        title: Text(industri.nama),
        subtitle: Text(
          '${industri.alamat}\nSisa kuota: ${industri.sisaKuota}/${industri.kuota}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
