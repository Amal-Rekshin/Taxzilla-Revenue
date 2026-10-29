import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../../core/providers/month_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_model.dart';

final dashboardProvider = FutureProvider<DashboardModel>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState.status != AuthStatus.authenticated) {
    throw ApiError(code: 'UNAUTHORIZED', message: 'User is not authenticated');
  }

  final dio = ref.watch(dioProvider);
  final month = ref.watch(selectedMonthProvider);

  try {
    final response = await dio.get('/dashboard', queryParameters: {'month': month});
    return DashboardModel.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiError.fromDioException(e);
  }
});

