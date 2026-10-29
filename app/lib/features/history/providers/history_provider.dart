import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../../core/providers/month_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/history_model.dart';

final historyFilterProvider = StateProvider<String>((ref) => 'all');

final entriesHistoryProvider = FutureProvider<List<HistoryDayItem>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState.status != AuthStatus.authenticated) {
    throw ApiError(code: 'UNAUTHORIZED', message: 'User is not authenticated');
  }

  final dio = ref.watch(dioProvider);
  final month = ref.watch(selectedMonthProvider);
  final filter = ref.watch(historyFilterProvider);

  try {
    final response = await dio.get('/entries', queryParameters: {
      'month': month,
      'filter': filter,
    });
    final rawList = response.data['entries'] as List<dynamic>? ?? [];
    return rawList.map((e) => HistoryDayItem.fromJson(e as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw ApiError.fromDioException(e);
  }
});

final dayDetailProvider = FutureProvider.family<DayDetailModel, String>((ref, date) async {
  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.get('/entries/$date');
    return DayDetailModel.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiError.fromDioException(e);
  }
});

class AuditQueryParam {
  final String date;
  final String slot; // 'ALL', 'AFTERNOON', or 'EVENING'

  const AuditQueryParam({required this.date, this.slot = 'ALL'});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditQueryParam &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          slot == other.slot;

  @override
  int get hashCode => date.hashCode ^ slot.hashCode;
}

final auditHistoryProvider = FutureProvider.family<List<HistoryAuditItem>, AuditQueryParam>((ref, param) async {
  final dio = ref.watch(dioProvider);

  try {
    final queryParams = <String, dynamic>{};
    if (param.slot != 'ALL' && param.slot.isNotEmpty) {
      queryParams['slot'] = param.slot;
    }

    final response = await dio.get(
      '/entries/${param.date}/history',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final rawList = response.data as List<dynamic>? ?? [];
    return rawList.map((a) => HistoryAuditItem.fromJson(a as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw ApiError.fromDioException(e);
  }
});

