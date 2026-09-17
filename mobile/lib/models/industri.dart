class Industri {
  const Industri({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.kuota,
    required this.sisaKuota,
    required this.jurusan,
  });

  final int id;
  final String nama;
  final String alamat;
  final double latitude;
  final double longitude;
  final int kuota;
  final int sisaKuota;
  final List<String> jurusan;

  factory Industri.fromJson(Map<String, dynamic> json) {
    return Industri(
      id: json['id'] as int,
      nama: json['nama'] as String,
      alamat: json['alamat'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      kuota: (json['kuota'] as num).toInt(),
      sisaKuota: (json['sisa_kuota'] as num).toInt(),
      jurusan: (json['jurusan'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}
