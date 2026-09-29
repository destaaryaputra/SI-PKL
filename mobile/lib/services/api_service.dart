import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/industri.dart';
import '../models/tempat_sekitar.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;
}

class ApiService {
  /// Login dan simpan token.
  ///
  /// Mengembalikan token beserta peran pengguna, supaya pemanggil bisa
  /// mengarahkan ke dashboard yang sesuai (admin atau siswa).
  Future<({String token, String peran})> login(
    String nis,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/login'),
      headers: {'Accept': 'application/json'},
      body: {'nis': nis, 'password': password},
    );

    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(body['pesan'] as String? ?? 'Login gagal.');
    }

    final token = body['token'] as String;
    final pengguna = body['pengguna'] as Map<String, dynamic>?;
    final peran = pengguna?['peran'] as String? ?? 'siswa';
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('token', token);
    await preferences.setString('peran', peran);
    return (token: token, peran: peran);
  }

  /// Cek apakah ada sesi tersimpan, untuk auto-login saat aplikasi dibuka.
  ///
  /// Mengembalikan peran pengguna ('siswa' atau 'admin') atau null jika
  /// belum ada token tersimpan.
  Future<String?> cekSesi() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final token = preferences.getString('token');
      if (token == null || token.isEmpty) return null;
      return preferences.getString('peran') ?? 'siswa';
    } catch (_) {
      // Penyimpanan tidak tersedia (mis. di lingkungan uji) — anggap
      // belum login supaya aplikasi tetap terbuka di halaman login.
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> ambilJurusan() async {
    final response = await _request('GET', '/jurusan');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        body['pesan'] as String? ?? 'Data jurusan gagal dimuat.',
      );
    }

    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> ambilProfil() async {
    final response = await _request('GET', '/profil');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        body['pesan'] as String? ?? 'Data profil gagal dimuat.',
      );
    }

    return body;
  }

  Future<List<Industri>> ambilIndustri({String? cari, List<int>? jurusanIds}) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    final queryParams = <String, dynamic>{};

    if (cari != null && cari.isNotEmpty) {
      queryParams['cari'] = cari;
    }
    if (jurusanIds != null && jurusanIds.isNotEmpty) {
      // Laravel expects array parameters like jurusan_ids[]=1&jurusan_ids[]=2
      queryParams['jurusan_ids[]'] = jurusanIds.map((e) => e.toString()).toList();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/industri').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http.get(uri, headers: _headers(token));
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        body['pesan'] as String? ?? 'Data industri gagal dimuat.',
      );
    }

    return (body['data'] as List<dynamic>)
        .map((item) => Industri.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Daftar industri berupa data mentah (dengan jurusan_ids), untuk
  /// keperluan CRUD admin — berbeda dari [ambilIndustri] yang mengembalikan
  /// model [Industri] untuk tampilan peta.
  Future<List<Map<String, dynamic>>> ambilIndustriMentah({String? cari}) async {
    final path = cari != null && cari.isNotEmpty
        ? '/industri?cari=${Uri.encodeComponent(cari)}'
        : '/industri';
    final response = await _request('GET', path);
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        body['pesan'] as String? ?? 'Data industri gagal dimuat.',
      );
    }

    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<TempatSekitar>> ambilTempatSekitar({
    required double latitude,
    required double longitude,
    String? cari,
  }) async {
    final query = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (cari != null && cari.trim().isNotEmpty) 'cari': cari.trim(),
    };
    final response = await _request(
      'GET',
      '/tempat-sekitar?${Uri(queryParameters: query).query}',
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        body['pesan'] as String? ?? 'Pencarian tempat sekitar gagal.',
      );
    }

    return (body['data'] as List<dynamic>)
        .map((item) => TempatSekitar.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Industri> ambilDetailIndustri(int id) async {
    final response = await _request('GET', '/industri/$id');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        body['pesan'] as String? ?? 'Detail industri gagal dimuat.',
      );
    }

    return Industri.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> ajukanPkl(int industriId, {String? catatan}) async {
    final response = await _request(
      'POST',
      '/pengajuan',
      body: {
        'industri_id': industriId,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 201) {
      final errors = body['errors'] as Map<String, dynamic>?;
      final pesanValidasi = errors?.values.firstOrNull;
      throw ApiException(
        pesanValidasi is List && pesanValidasi.isNotEmpty
            ? pesanValidasi.first.toString()
            : body['pesan'] as String? ?? 'Pengajuan PKL gagal dikirim.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> ambilPengajuan() async {
    final response = await _request('GET', '/pengajuan');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(body['pesan'] as String? ?? 'Pengajuan gagal dimuat.');
    }

    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Menghapus token di server (kalau masih valid) lalu membuang token lokal.
  ///
  /// Tidak melakukan navigasi: pemanggil yang mengatur perpindahan halaman,
  /// supaya service ini tetap bebas dari ketergantungan ke widget.
  Future<void> logout() async {
    try {
      await _request('POST', '/logout');
    } catch (_) {
      // Token mungkin sudah tidak valid — tetap lanjut hapus data lokal.
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('token');
    await preferences.remove('peran');
  }

  Future<List<Map<String, dynamic>>> ambilPengajuanAdmin() async {
    final response = await _request('GET', '/admin/pengajuan');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        body['pesan'] as String? ?? 'Data pengajuan gagal dimuat.',
      );
    }

    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> setujuiPengajuan(int id, {String? catatan}) async {
    final response = await _request(
      'PATCH',
      '/admin/pengajuan/$id/setujui',
      body: {
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      final errors = body['errors'] as Map<String, dynamic>?;
      final pesanValidasi = errors?.values.firstOrNull;
      throw ApiException(
        pesanValidasi is List && pesanValidasi.isNotEmpty
            ? pesanValidasi.first.toString()
            : body['pesan'] as String? ?? 'Pengajuan gagal disetujui.',
      );
    }
  }

  Future<void> tolakPengajuan(int id, {required String catatan}) async {
    final response = await _request(
      'PATCH',
      '/admin/pengajuan/$id/tolak',
      body: {'catatan': catatan},
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      final errors = body['errors'] as Map<String, dynamic>?;
      final pesanValidasi = errors?.values.firstOrNull;
      throw ApiException(
        pesanValidasi is List && pesanValidasi.isNotEmpty
            ? pesanValidasi.first.toString()
            : body['pesan'] as String? ?? 'Pengajuan gagal ditolak.',
      );
    }
  }

  /// Riwayat penempatan siswa di suatu industri, dikelompokkan per tahun
  /// (FR-17): [{tahun, jumlah, siswa: [{nis, nama, jurusan}]}].
  Future<List<Map<String, dynamic>>> ambilRiwayatIndustri(int industriId) async {
    final response = await _request('GET', '/industri/$industriId/riwayat');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        body['pesan'] as String? ?? 'Riwayat penempatan gagal dimuat.',
      );
    }

    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Riwayat pengajuan siswa yang sedang login, dikelompokkan per tahun:
  /// [{tahun, pengajuan: [{id, industri, status, tanggal}]}].
  Future<List<Map<String, dynamic>>> ambilRiwayatSiswa() async {
    final response = await _request('GET', '/riwayat');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        body['pesan'] as String? ?? 'Riwayat gagal dimuat.',
      );
    }

    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  // ===== Admin: statistik =====

  Future<Map<String, dynamic>> ambilStatistikAdmin() async {
    final response = await _request('GET', '/admin/statistik');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        body['pesan'] as String? ?? 'Statistik gagal dimuat.',
      );
    }

    return body['data'] as Map<String, dynamic>;
  }

  // ===== Admin: CRUD siswa =====

  Future<List<Map<String, dynamic>>> ambilSiswa({String? cari}) async {
    final response = await _request(
      'GET',
      '/admin/siswa${cari != null && cari.isNotEmpty ? '?cari=${Uri.encodeComponent(cari)}' : ''}',
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(body['pesan'] as String? ?? 'Data siswa gagal dimuat.');
    }

    return (body['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> tambahSiswa({
    required String nis,
    required String nama,
    int? jurusanId,
    required String password,
  }) async {
    final response = await _request(
      'POST',
      '/admin/siswa',
      body: {
        'nis': nis,
        'nama': nama,
        'jurusan_id': ?jurusanId,
        'password': password,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 201) {
      throw ApiException(_pesanValidasi(body) ?? 'Siswa gagal ditambahkan.');
    }
  }

  Future<void> ubahSiswa({
    required int id,
    required String nis,
    required String nama,
    int? jurusanId,
    String? password,
  }) async {
    final response = await _request(
      'PUT',
      '/admin/siswa/$id',
      body: {
        'nis': nis,
        'nama': nama,
        'jurusan_id': ?jurusanId,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_pesanValidasi(body) ?? 'Data siswa gagal diperbarui.');
    }
  }

  Future<void> hapusSiswa(int id) async {
    final response = await _request('DELETE', '/admin/siswa/$id');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(body['pesan'] as String? ?? 'Siswa gagal dihapus.');
    }
  }

  // ===== Admin: CRUD jurusan =====

  Future<void> tambahJurusan(String nama) async {
    final response = await _request('POST', '/admin/jurusan', body: {'nama': nama});
    final body = _decode(response);
    if (response.statusCode != 201) {
      throw ApiException(_pesanValidasi(body) ?? 'Jurusan gagal ditambahkan.');
    }
  }

  Future<void> ubahJurusan(int id, String nama) async {
    final response = await _request('PUT', '/admin/jurusan/$id', body: {'nama': nama});
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_pesanValidasi(body) ?? 'Jurusan gagal diperbarui.');
    }
  }

  Future<void> hapusJurusan(int id) async {
    final response = await _request('DELETE', '/admin/jurusan/$id');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(body['pesan'] as String? ?? 'Jurusan gagal dihapus.');
    }
  }

  // ===== Admin: CRUD industri =====

  Future<void> tambahIndustri({
    required String nama,
    required String alamat,
    required double latitude,
    required double longitude,
    required int kuota,
    required List<int> jurusanIds,
  }) async {
    final response = await _request(
      'POST',
      '/admin/industri',
      body: {
        'nama': nama,
        'alamat': alamat,
        'latitude': latitude,
        'longitude': longitude,
        'kuota': kuota,
        'jurusan_ids': jurusanIds,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 201) {
      throw ApiException(_pesanValidasi(body) ?? 'Industri gagal ditambahkan.');
    }
  }

  Future<void> ubahIndustri({
    required int id,
    required String nama,
    required String alamat,
    required double latitude,
    required double longitude,
    required int kuota,
    required List<int> jurusanIds,
  }) async {
    final response = await _request(
      'PUT',
      '/admin/industri/$id',
      body: {
        'nama': nama,
        'alamat': alamat,
        'latitude': latitude,
        'longitude': longitude,
        'kuota': kuota,
        'jurusan_ids': jurusanIds,
      },
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_pesanValidasi(body) ?? 'Data industri gagal diperbarui.');
    }
  }

  Future<void> hapusIndustri(int id) async {
    final response = await _request('DELETE', '/admin/industri/$id');
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(body['pesan'] as String? ?? 'Industri gagal dihapus.');
    }
  }

  String? _pesanValidasi(Map<String, dynamic> body) {
    final errors = body['errors'] as Map<String, dynamic>?;
    final pesanValidasi = errors?.values.firstOrNull;
    if (pesanValidasi is List && pesanValidasi.isNotEmpty) {
      return pesanValidasi.first.toString();
    }
    return body['pesan'] as String?;
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      ..._headers(token),
      if (body != null) 'Content-Type': 'application/json',
    };
    final encodedBody = body == null ? null : jsonEncode(body);

    return switch (method) {
      'POST' => http.post(uri, headers: headers, body: encodedBody),
      'PATCH' => http.patch(uri, headers: headers, body: encodedBody),
      'PUT' => http.put(uri, headers: headers, body: encodedBody),
      'DELETE' => http.delete(uri, headers: headers),
      _ => http.get(uri, headers: headers),
    };
  }

  Map<String, String> _headers(String? token) {
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException('Server mengirim response yang tidak valid.');
    }
  }
}
