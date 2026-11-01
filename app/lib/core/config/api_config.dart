import 'package:flutter/foundation.dart';

class ApiConfig {
  // Override at compile time with --dart-define=API_URL=https://...
  static const String _envBaseUrl = String.fromEnvironment('API_URL');

  // Production backend API URL on Render
  static const String defaultProductionUrl = 'https://taxzilla-revenue.onrender.com/api';

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/api') ? _envBaseUrl : '$_envBaseUrl/api';
    }

    // In web browsers, detect if running on localhost
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
        if (Uri.base.port == 3000) {
          return '/api';
        }
        return 'http://localhost:3000/api';
      }
    }

    return defaultProductionUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
