import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

Dio createDioClient(SecureStorageService storage, {void Function()? onUnauthorized}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(storage, onUnauthorized: onUnauthorized),
  );

  return dio;
}

