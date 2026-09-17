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
  Future<String> login(String nis, String password) async {
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
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('token', token);
    return token;
  }

  Future<List<Industri>> ambilIndustri({String? cari}) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    final uri = Uri.parse('${ApiConfig.baseUrl}/industri').replace(
      queryParameters: cari == null || cari.isEmpty ? null : {'cari': cari},
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
