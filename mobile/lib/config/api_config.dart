import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  /// Base URL API backend Laravel.
  ///
  /// - Web & desktop: localhost biasa.
  /// - Android emulator: 10.0.2.2 adalah alias untuk 127.0.0.1 PC host.
  /// - Perangkat fisik (USB debug): HP harus satu jaringan WiFi dengan PC,
  ///   lalu ganti [_lanIp] ke IP lokal PC (cek via `ipconfig` di CMD).
  ///
  /// Untuk ganti mode: ubah [_mode] ke 'emulator' atau 'fisik'.
  static const String _mode = 'fisik'; // 'emulator' atau 'fisik'
  static const String _lanIp = '10.61.68.248'; // IP WiFi PC ini (cek: ipconfig)

  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    return switch (_mode) {
      'fisik' => 'http://$_lanIp:8000/api',
      _ => 'http://10.0.2.2:8000/api', // emulator
    };
  }
}
