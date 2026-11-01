import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/month_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_refresh_action.dart';
import '../providers/report_provider.dart';
import '../widgets/month_selector_bar.dart';
import '../widgets/report_table.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final reportAsync = ref.watch(monthlyReportProvider);
    final exportState = ref.watch(exportNotifierProvider);

    ref.listen<ExportState>(exportNotifierProvider, (prev, next) {
      if (next.status == ExportStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.error,
          ),
        );
      } else if (next.status == ExportStatus.success && next.filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported: ${next.filePath}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    });

    final isDownloading = exportState.status == ExportStatus.downloading ||
        exportState.status == ExportStatus.opening;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        actions: [
          // Refresh Action Button
          AnimatedRefreshAction(
            onRefresh: () async {
              ref.invalidate(monthlyReportProvider);
              await ref.read(monthlyReportProvider.future);
            },
          ),
          // Export Excel Action Button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size.zero,
              ),
              onPressed: isDownloading
                  ? null
                  : () {
                      ref
                          .read(exportNotifierProvider.notifier)
                          .exportAndOpen(selectedMonth);
                    },
              icon: isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_download, size: 18),
              label: Text(
                isDownloading ? 'Exporting...' : 'Export Excel',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector Bar (prev/next)
          MonthSelectorBar(
            currentMonth: selectedMonth,
            onMonthChanged: (newMonth) {
              ref.read(selectedMonthProvider.notifier).state = newMonth;
            },
          ),
          if (reportAsync.isRefreshing)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
              color: AppTheme.primary,
            ),
          const Divider(height: 1),

          // Report Table or Error / Loading states
          Expanded(
            child: reportAsync.when(
              skipLoadingOnReload: false,
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading monthly report...', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load report: $err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(monthlyReportProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (report) {
                if (report.days.isEmpty) {
                  return const Center(
                    child: Text('No data found for this month.'),
                  );
                }
                return ReportTable(report: report);
              },
            ),
          ),
        ],
      ),
    );
  }
}
