import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  /// Base URL API backend Laravel.
  ///
  /// - Web & desktop: localhost biasa.
  /// - Android emulator: 10.0.2.2 adalah alias untuk 127.0.0.1 PC host.
  /// - Perangkat fisik (lokal): IP PC via `--dart-define=API_IP=...`
  /// - Produksi (online): Gunakan `--dart-define=API_URL=https://...`
  static const String _mode = 'fisik'; // 'emulator', 'fisik', atau 'online'

  static const String _lanIp = String.fromEnvironment(
    'API_IP',
    // IP LAN PC host (lihat `ipconfig`). Bisa dioverride saat build:
    // flutter run --dart-define=API_IP=192.168.x.x
    defaultValue: '10.61.68.248',
  );

  static const String _productionUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.sipkl.com/api',
  );

  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    return switch (_mode) {
      'online' => _productionUrl,
      'fisik' => 'http://$_lanIp:8000/api',
      _ => 'http://10.0.2.2:8000/api', // emulator
    };
  }
}
