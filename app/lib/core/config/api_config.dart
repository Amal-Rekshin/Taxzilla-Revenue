import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Override at compile time with --dart-define=API_URL=http://...
  static const String _envBaseUrl = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    // Default to localhost for desktop/web and 10.0.2.2 for Android emulator
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}

