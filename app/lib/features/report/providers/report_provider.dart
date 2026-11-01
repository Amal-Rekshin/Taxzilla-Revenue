import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../../core/providers/month_provider.dart';
import '../../../core/utils/file_saver/file_saver.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/report_model.dart';

// Provider to fetch monthly report using shared month
final monthlyReportProvider = FutureProvider<MonthlyReportModel>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState.status != AuthStatus.authenticated) {
    throw ApiError(code: 'UNAUTHORIZED', message: 'User is not authenticated');
  }

  final dio = ref.watch(dioProvider);
  final month = ref.watch(selectedMonthProvider);

  try {
    final response = await dio.get('/reports/monthly', queryParameters: {'month': month});
    return MonthlyReportModel.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiError.fromDioException(e);
  }
});

enum ExportStatus { idle, downloading, opening, success, error }

class ExportState {
  final ExportStatus status;
  final String? filePath;
  final String? errorMessage;

  const ExportState({
    this.status = ExportStatus.idle,
    this.filePath,
    this.errorMessage,
  });
}

class ExportNotifier extends StateNotifier<ExportState> {
  final Dio _dio;

  ExportNotifier(this._dio) : super(const ExportState());

  Future<void> exportAndOpen(String month) async {
    state = const ExportState(status: ExportStatus.downloading);

    try {
      final response = await _dio.get<List<int>>(
        '/reports/monthly/export',
        queryParameters: {'month': month},
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        state = const ExportState(
          status: ExportStatus.error,
          errorMessage: 'Server returned empty file',
        );
        return;
      }

      state = const ExportState(status: ExportStatus.opening);

      final fileName = 'Revenue_Report_$month.xlsx';
      final savedPath = await FileSaver.saveAndOpenFile(
        bytes: bytes,
        fileName: fileName,
      );

      state = ExportState(status: ExportStatus.success, filePath: savedPath);
    } on DioException catch (e) {
      final err = ApiError.fromDioException(e);
      state = ExportState(status: ExportStatus.error, errorMessage: err.message);
    } catch (e) {
      state = ExportState(
        status: ExportStatus.error,
        errorMessage: 'Failed to export file: $e',
      );
    }
  }

  void reset() {
    state = const ExportState();
  }
}

final exportNotifierProvider = StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  final dio = ref.watch(dioProvider);
  return ExportNotifier(dio);
});
