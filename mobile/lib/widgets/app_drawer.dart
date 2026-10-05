import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/status_pengajuan_screen.dart';

/// Drawer dengan menu sesuai peran pengguna:
/// - Siswa: Dashboard, Status Pengajuan, Profil, Logout
/// - Admin: Dashboard Admin, Pengajuan PKL, Data Siswa/Jurusan/Industri, Logout
/// Semua menu membuka halaman dengan push biasa agar tombol kembali
/// sistem tetap berfungsi (balik ke halaman sebelumnya, bukan keluar app).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<String> _ambilPeran() async {
    try {
      final peran = await ApiService().cekSesi();
      return peran ?? 'siswa';
    } catch (_) {
      return 'siswa';
    }
  }

  Future<void> _logout(BuildContext context) async {
    await ApiService().logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<String>(
        future: _ambilPeran(),
        builder: (context, snapshot) {
          final peran = snapshot.data ?? 'siswa';
          final isAdmin = peran == 'admin';

          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: AppTheme.navy,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo lebih kecil dan rapi di drawer
                    ClipOval(
                      child: Image.asset(
                        'assets/brand/logo_full.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'SI-PKL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isAdmin ? 'Admin / Guru Pembimbing' : 'Siswa',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAdmin) ...[
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard Admin'),
                  onTap: () {
                    // Tutup drawer lalu balik ke halaman paling awal
                    // (dashboard) dari mana pun.
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Pengajuan PKL'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/admin-pengajuan');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Data Siswa'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/admin-siswa');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('Data Jurusan'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/admin-jurusan');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Data Industri'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/admin-industri');
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () {
                    // Tutup drawer lalu balik ke halaman paling awal
                    // (dashboard) dari mana pun.
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: const Text('Status Pengajuan'),
                  onTap: () {
                    // Tab status ada di dashboard: tutup drawer, biarkan
                    // user pindah lewat bottom nav. (Dipush terpisah agar
                    // tombol kembali tetap masuk akal.)
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StatusPengajuanScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profil'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/profil');
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () => _logout(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
