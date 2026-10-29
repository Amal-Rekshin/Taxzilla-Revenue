import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/month_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_refresh_action.dart';
import '../../auth/providers/auth_provider.dart';
import '../../report/widgets/month_selector_bar.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/accounts_summary_card.dart';
import '../widgets/month_summary_cards.dart';
import '../widgets/pending_days_banner.dart';
import '../widgets/section_breakdown_card.dart';
import '../widgets/today_status_card.dart';
import '../widgets/trend_line_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'RevPulse',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          AnimatedRefreshAction(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              await ref.read(dashboardProvider.future);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector (Controls everything on the dashboard)
          MonthSelectorBar(
            currentMonth: selectedMonth,
            onMonthChanged: (newMonth) {
              ref.read(selectedMonthProvider.notifier).state = newMonth;
            },
          ),
          if (dashboardAsync.isRefreshing)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
              color: AppTheme.primary,
            ),
          const Divider(height: 1),

          // Dashboard Content
          Expanded(
            child: dashboardAsync.when(
              skipLoadingOnReload: false,
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading dashboard metrics...', style: TextStyle(color: AppTheme.textSecondary)),
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
                        'Failed to load dashboard: $err',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(dashboardProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(dashboardProvider);
                    await ref.read(dashboardProvider.future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 28),
                    children: [
                      // 1. Summary Cards: Total 1 and Total 2
                      MonthSummaryCards(
                        total1: data.total1,
                        total2: data.total2,
                        prevMonth: data.previousMonth,
                      ),

                      // 2. Today's Status Card
                      TodayStatusCard(today: data.today),

                      // 3. Pending Days Banner
                      PendingDaysBanner(
                        count: data.pendingDays,
                        onTap: () {
                          // Navigate to Entries tab with pending filter
                          context.go('/entries?filter=pending');
                        },
                      ),

                      // 4. Trend Chart (fl_chart dual line)
                      TrendLineChart(trend: data.dailyTrend),

                      // 5. Accounts Running Balance Card
                      AccountsSummaryCard(accounts: data.accounts),

                      // 6. Section Revenue Breakdown
                      SectionBreakdownCard(sections: data.sectionBreakdown),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
