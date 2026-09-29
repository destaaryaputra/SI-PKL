import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/admin_industri_screen.dart';
import '../screens/admin_jurusan_screen.dart';
import '../screens/admin_pengajuan_screen.dart';
import '../screens/admin_siswa_screen.dart';
import '../screens/status_pengajuan_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Drawer dengan menu sesuai peran pengguna:
/// - Siswa: Dashboard, Status Pengajuan, Profil, Logout
/// - Admin: Dashboard Admin, Pengajuan PKL, Data Siswa/Jurusan/Industri, Logout
/// Semua menu membuka halaman dengan push biasa agar tombol kembali
/// sistem tetap berfungsi (balik ke halaman sebelumnya, bukan keluar app).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<String> _ambilPeran() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getString('peran') ?? 'siswa';
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
                decoration: const BoxDecoration(color: AppTheme.navy),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Image.asset(
                      'assets/brand/logo_pin.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SI‑PKL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isAdmin ? 'Admin / Guru Pembimbing' : 'Siswa',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
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
                    // Tutup drawer lalu push biasa, supaya tombol kembali
                    // balik ke dashboard (bukan keluar aplikasi).
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminPengajuanScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Data Siswa'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminSiswaScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('Data Jurusan'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminJurusanScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Data Industri'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminIndustriScreen(),
                      ),
                    );
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
