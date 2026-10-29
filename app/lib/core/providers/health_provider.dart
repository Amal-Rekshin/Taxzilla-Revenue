import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

class HealthStatus {
  final bool isHealthy;
  final String status;
  final String? databaseStatus;
  final int? uptime;
  final String? timestamp;
  final int? latencyMs;
  final String? error;

  const HealthStatus({
    required this.isHealthy,
    required this.status,
    this.databaseStatus,
    this.uptime,
    this.timestamp,
    this.latencyMs,
    this.error,
  });

  factory HealthStatus.fromMap(Map<String, dynamic> map) {
    final db = map['database'] is Map ? map['database'] as Map : null;
    return HealthStatus(
      isHealthy: map['status'] == 'ok',
      status: map['status']?.toString() ?? 'unknown',
      databaseStatus: db != null ? db['status']?.toString() : null,
      uptime: map['uptime'] as int?,
      timestamp: map['timestamp']?.toString(),
      latencyMs: map['latencyMs'] as int?,
    );
  }

  factory HealthStatus.error(String message) {
    return HealthStatus(
      isHealthy: false,
      status: 'error',
      error: message,
    );
  }
}

// Automatically pings backend health on app startup or when manually invoked
final backendHealthProvider = FutureProvider<HealthStatus>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/health');
    if (response.data is Map<String, dynamic>) {
      return HealthStatus.fromMap(response.data as Map<String, dynamic>);
    }
    return HealthStatus.fromMap(Map<String, dynamic>.from(response.data as Map));
  } catch (e) {
    return HealthStatus.error(e.toString());
  }
});

