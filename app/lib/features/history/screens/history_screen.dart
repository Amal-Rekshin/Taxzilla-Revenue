import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/month_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/animated_refresh_action.dart';
import '../../entry/providers/entry_provider.dart';
import '../../report/widgets/month_selector_bar.dart';
import '../models/history_model.dart';
import '../providers/history_provider.dart';
import '../widgets/day_detail_modal.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final currentFilter = ref.watch(historyFilterProvider);
    final historyAsync = ref.watch(entriesHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry History'),
        actions: [
          AnimatedRefreshAction(
            onRefresh: () async {
              ref.invalidate(entriesHistoryProvider);
              await ref.read(entriesHistoryProvider.future);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector (Shared across Dashboard and History)
          MonthSelectorBar(
            currentMonth: selectedMonth,
            onMonthChanged: (newMonth) {
              ref.read(selectedMonthProvider.notifier).state = newMonth;
            },
          ),
          if (historyAsync.isRefreshing)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
              color: AppTheme.primary,
            ),
          const Divider(height: 1),

          // Filters Bar: All | Pending only | Edited only
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(context, ref, 'all', 'All', currentFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, ref, 'pending', 'Pending only', currentFilter),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, ref, 'edited', 'Edited only', currentFilter),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Days List
          Expanded(
            child: historyAsync.when(
              skipLoadingOnReload: false,
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading entries history...', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                      const SizedBox(height: 12),
                      Text('Failed to load history: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(entriesHistoryProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (days) {
                if (days.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          currentFilter == 'pending'
                              ? 'No pending days found for this month!'
                              : (currentFilter == 'edited'
                                  ? 'No edited entries for this month.'
                                  : 'No entries found for this month.'),
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(entriesHistoryProvider);
                    await ref.read(entriesHistoryProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = days[index];
                      return _buildDayCard(context, ref, item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String filterKey,
    String label,
    String activeFilter,
  ) {
    final isSelected = activeFilter == filterKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryLight.withValues(alpha: 0.18),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(historyFilterProvider.notifier).state = filterKey;
        }
      },
    );
  }

  Widget _buildDayCard(BuildContext context, WidgetRef ref, HistoryDayItem item) {
    final isPending = item.isPending;
    final isSunday = item.isSunday;
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(item.date);
    } catch (_) {}

    final dateTitle = parsedDate != null
        ? DateFormat('EEE, dd MMM yyyy').format(parsedDate)
        : item.date;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPending
              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
              : (isSunday ? AppTheme.primary.withValues(alpha: 0.25) : AppTheme.border),
          width: isPending ? 1.5 : 1,
        ),
      ),
      color: isPending
          ? const Color(0xFFFFFBEB)
          : (isSunday ? const Color(0xFFFAF5FF) : Colors.white),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (item.eveningDone || item.morningDone) {
            // Has data: open detail modal
            DayDetailModal.show(context, item.date);
          } else {
            // No data: open entry form for that date
            ref.read(selectedDateProvider.notifier).state = item.date;
            ref.read(selectedSlotProvider.notifier).state = 'EVENING';
            context.push('/entry');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Date + Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPending
                          ? const Color(0xFF92400E)
                          : (isSunday ? AppTheme.primary : AppTheme.textPrimary),
                    ),
                  ),
                  Row(
                    children: [
                      if (item.isEdited) ...[
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () {
                            DayDetailModal.show(context, item.date, initialTab: 1);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.history, size: 12, color: AppTheme.primary),
                                const SizedBox(width: 3),
                                Text(
                                  'Edited ${item.lastUpdatedBy != null ? 'by ${item.lastUpdatedBy}' : ''}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (isSunday && !item.eveningDone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'Sunday (Off)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        )
                      else if (isPending)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE68A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Pending (Tap to Enter)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                          ),
                        )
                      else
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Status badges & evening totals
              Row(
                children: [
                  _buildSlotStatusBadge('Afternoon', item.morningDone),
                  const SizedBox(width: 8),
                  _buildSlotStatusBadge('Evening', item.eveningDone),
                  const Spacer(),
                  if (!isPending && (item.eveningDone || item.morningDone)) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total 1: ${CurrencyFormatter.format(item.total1)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                        Text(
                          'Total 2: ${CurrencyFormatter.format(item.total2)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotStatusBadge(String slot, bool done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: done ? AppTheme.success.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check : Icons.close,
            size: 12,
            color: done ? AppTheme.success : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            slot,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: done ? AppTheme.success : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
