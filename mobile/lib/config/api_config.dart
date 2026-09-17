import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const baseUrl = kIsWeb
      ? 'http://127.0.0.1:8000/api'
      : 'http://127.0.0.1:8000/api';
}
