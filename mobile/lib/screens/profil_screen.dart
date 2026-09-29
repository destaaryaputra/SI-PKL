import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _apiService = ApiService();
  late Future<Map<String, dynamic>> _profilFuture;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  void _loadProfil() {
    setState(() {
      _profilFuture = _apiService.ambilProfil();
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _apiService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Tanpa AppBar sendiri: sebagai tab di DashboardScreen, judul
      // "Profil" diberi lewat header di bawah; saat dibuka lewat
      // route '/profil' AppBar tetap tampil dari Scaffold ini.
      appBar: AppBar(title: const Text('Profil')),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadProfil();
          await _profilFuture;
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profilFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Gagal memuat profil: ${snapshot.error}'),
              );
            }

            final pengguna = snapshot.data?['pengguna'] as Map<String, dynamic>?;
            if (pengguna == null) {
              return const Center(child: Text('Data profil tidak ditemukan'));
            }

            final nama = pengguna['nama'] as String? ?? '-';
            final nis = pengguna['nis'] as String? ?? '-';
            final jurusan = pengguna['jurusan'] as Map<String, dynamic>?;
            final namaJurusan = jurusan?['nama'] as String? ?? '-';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar Section
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        nama,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(namaJurusan),
                        avatar: const Icon(Icons.school, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Menu Items
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.assignment),
                        title: const Text('Status Pengajuan'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).pushNamed('/status');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Tentang Aplikasi'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'SI-PKL',
                            applicationVersion: '1.0.0',
                            applicationLegalese: '© 2026 SI-PKL\n\nSistem Informasi Pencari Lokasi PKL',
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                'Aplikasi ini membantu siswa mencari dan mengajukan tempat PKL dengan mudah.',
                              ),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                        title: Text(
                          'Logout',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
