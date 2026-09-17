import 'package:flutter/material.dart';

import '../models/industri.dart';
import '../services/api_service.dart';

class IndustryDetailScreen extends StatefulWidget {
  const IndustryDetailScreen({super.key, required this.industriId});

  final int industriId;

  @override
  State<IndustryDetailScreen> createState() => _IndustryDetailScreenState();
}

class _IndustryDetailScreenState extends State<IndustryDetailScreen> {
  final _apiService = ApiService();
  late Future<Industri> _industriFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _industriFuture = _apiService.ambilDetailIndustri(widget.industriId);
  }

  Future<void> _ajukan() async {
    setState(() => _isSubmitting = true);
    try {
      await _apiService.ajukanPkl(widget.industriId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan PKL berhasil dikirim.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Industri')),
      body: FutureBuilder<Industri>(
        future: _industriFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat detail: ${snapshot.error}'),
            );
          }
          final industri = snapshot.data;
          if (industri == null) {
            return const Center(child: Text('Data industri tidak ditemukan.'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                industri.nama,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(industri.alamat),
              const SizedBox(height: 24),
              _InfoRow(
                label: 'Kuota maksimal',
                value: '${industri.kuota} siswa',
              ),
              _InfoRow(
                label: 'Sisa kuota',
                value: '${industri.sisaKuota} siswa',
              ),
              _InfoRow(
                label: 'Jurusan diterima',
                value: industri.jurusan.join(', '),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: industri.sisaKuota == 0 || _isSubmitting
                    ? null
                    : _ajukan,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Ajukan PKL'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
