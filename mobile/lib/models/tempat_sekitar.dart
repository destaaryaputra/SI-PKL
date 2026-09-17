class TempatSekitar {
  const TempatSekitar({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.alamat,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String nama;
  final String kategori;
  final String alamat;
  final double latitude;
  final double longitude;

  factory TempatSekitar.fromJson(Map<String, dynamic> json) {
    return TempatSekitar(
      id: json['id'].toString(),
      nama: json['nama'] as String,
      kategori: json['kategori'] as String,
      alamat: json['alamat'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
    );
  }
}
