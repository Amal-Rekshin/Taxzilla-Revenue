import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/health_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: RevenueTrackerApp(),
    ),
  );
}

class RevenueTrackerApp extends ConsumerWidget {
  const RevenueTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Automatically trigger backend health check when app opens
    ref.watch(backendHealthProvider);

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RevPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

