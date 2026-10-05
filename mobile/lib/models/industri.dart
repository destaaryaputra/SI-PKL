import '../config/api_config.dart';

class Industri {
  const Industri({    required this.id,
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.kuota,
    required this.sisaKuota,
    required this.jurusan,
    this.logoUrl,
    this.jumlahMenunggu = 0,
    this.jumlahDisetujui = 0,
  });

  final int id;
  final String nama;
  final String alamat;
  final String? logoUrl;
  final double latitude;
  final double longitude;
  final int kuota;
  final int sisaKuota;
  final List<String> jurusan;
  final int jumlahMenunggu;
  final int jumlahDisetujui;

  /// Kuota terpakai = pengajuan menunggu + disetujui.
  int get terpakai => jumlahMenunggu + jumlahDisetujui;

  factory Industri.fromJson(Map<String, dynamic> json) {
    return Industri(
      id: json['id'] as int,
      nama: json['nama'] as String,
      alamat: json['alamat'] as String,
      logoUrl: resolveLogoUrl(json['logo_url'] as String?),
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      kuota: (json['kuota'] as num).toInt(),
      sisaKuota: (json['sisa_kuota'] as num).toInt(),
      jurusan: (json['jurusan'] as List<dynamic>? ?? []).cast<String>(),
      jumlahMenunggu: (json['jumlah_menunggu'] as num? ?? 0).toInt(),
      jumlahDisetujui: (json['jumlah_disetujui'] as num? ?? 0).toInt(),
    );
  }

  /// Ubah path logo dari API menjadi URL penuh yang bisa diunduh aplikasi.
  ///
  /// Backend mengirim path relatif (mis. `/logo/newus.png`). File itu
  /// digabungkan dengan [ApiConfig.baseUrl] sehingga lewat route
  /// `/api/logo/{file}` — file statis di root server tidak punya header
  /// CORS sehingga `Image.network` di Flutter web selalu gagal.
  /// URL absolut (http/https) dilewatkan apa adanya.
  static String? resolveLogoUrl(String? logoUrl) {
    if (logoUrl == null || logoUrl.isEmpty) return null;
    if (logoUrl.startsWith('http')) return logoUrl;
    final path = logoUrl.startsWith('/') ? logoUrl : '/$logoUrl';
    return '${ApiConfig.baseUrl}$path';
  }
}
