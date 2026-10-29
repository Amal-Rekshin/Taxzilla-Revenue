import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final void Function()? onUnauthorized;

  AuthInterceptor(this._storage, {this.onUnauthorized});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Attach JWT Bearer token if present
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Prevent HTTP caching on web browsers
    options.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
    options.headers['Pragma'] = 'no-cache';
    if (options.method.toUpperCase() == 'GET') {
      options.queryParameters = {
        ...options.queryParameters,
        '_t': DateTime.now().millisecondsSinceEpoch,
      };
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid
      _storage.clearSession();
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
    }
    return handler.next(err);
  }
}

