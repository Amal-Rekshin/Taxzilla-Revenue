import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';

  final FlutterSecureStorage _storage;
  String? _cachedToken;
  String? _cachedUsername;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // In-memory cache preserved if secure storage fails
    }
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      _cachedToken = await _storage.read(key: _tokenKey);
    } catch (_) {
      _cachedToken = null;
    }
    return _cachedToken;
  }

  Future<void> saveUsername(String username) async {
    _cachedUsername = username;
    try {
      await _storage.write(key: _usernameKey, value: username);
    } catch (_) {
      // In-memory cache preserved if secure storage fails
    }
  }

  Future<String?> getUsername() async {
    if (_cachedUsername != null) return _cachedUsername;
    try {
      _cachedUsername = await _storage.read(key: _usernameKey);
    } catch (_) {
      _cachedUsername = null;
    }
    return _cachedUsername;
  }

  Future<void> clearSession() async {
    _cachedToken = null;
    _cachedUsername = null;
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _usernameKey);
    } catch (_) {}
  }
}
