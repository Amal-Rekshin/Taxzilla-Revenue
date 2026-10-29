import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return createDioClient(
    storage,
    onUnauthorized: () {
      ref.read(authNotifierProvider.notifier).handleUnauthorized();
    },
  );
});

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? username;
  final String? token;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.username,
    this.token,
    this.isLoading = false,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? token,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storage;
  final Dio _dio;

  AuthNotifier(this._storage, this._dio) : super(AuthState.initial()) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    final token = await _storage.getToken();
    final username = await _storage.getUsername();

    if (token != null && token.isNotEmpty) {
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        username: username,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username.trim(),
        'password': password,
      });

      final token = response.data['token'] as String;
      await _storage.saveToken(token);
      await _storage.saveUsername(username.trim());

      state = AuthState(
        status: AuthStatus.authenticated,
        username: username.trim(),
        token: token,
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      final apiError = ApiError.fromDioException(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: apiError.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred during login',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void handleUnauthorized() {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Your session has expired. Please sign in again.',
    );
  }
}

final StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = ref.watch(dioProvider);
  return AuthNotifier(storage, dio);
});

