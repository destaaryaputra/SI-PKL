import 'package:flutter/material.dart';

import '../services/api_service.dart';

class StatusPengajuanScreen extends StatefulWidget {
  const StatusPengajuanScreen({super.key});

  @override
  State<StatusPengajuanScreen> createState() => _StatusPengajuanScreenState();
}

class _StatusPengajuanScreenState extends State<StatusPengajuanScreen> {
  final _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _pengajuanFuture;

  @override
  void initState() {
    super.initState();
    _pengajuanFuture = _apiService.ambilPengajuan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Pengajuan')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pengajuanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat pengajuan: ${snapshot.error}'),
            );
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Belum ada pengajuan PKL.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _pengajuanFuture = _apiService.ambilPengajuan());
              await _pengajuanFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final industri = item['industri'] as Map<String, dynamic>?;
                final status = item['status'] as String? ?? '-';
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text(industri?['nama'] as String? ?? 'Industri'),
                    subtitle: Text('Status: $status'),
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
