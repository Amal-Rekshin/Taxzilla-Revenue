import 'package:dio/dio.dart';

class ApiError implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  ApiError({
    required this.code,
    required this.message,
    this.statusCode,
  });

  factory ApiError.fromDioException(DioException error) {
    if (error.response != null && error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      if (data.containsKey('error') && data['error'] is Map<String, dynamic>) {
        final errObj = data['error'] as Map<String, dynamic>;
        return ApiError(
          code: errObj['code']?.toString() ?? 'API_ERROR',
          message: errObj['message']?.toString() ?? 'An unknown API error occurred',
          statusCode: error.response?.statusCode,
        );
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError(
          code: 'TIMEOUT',
          message: 'Connection timed out. Please check your internet connection.',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiError(
          code: 'NETWORK_ERROR',
          message: 'Unable to connect to the server. Please verify backend is running.',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        return ApiError(
          code: 'HTTP_${error.response?.statusCode ?? 500}',
          message: error.response?.statusMessage ?? 'Server error',
          statusCode: error.response?.statusCode,
        );
      default:
        return ApiError(
          code: 'UNKNOWN',
          message: error.message ?? 'An unexpected error occurred.',
          statusCode: error.response?.statusCode,
        );
    }
  }

  @override
  String toString() => message;
}

