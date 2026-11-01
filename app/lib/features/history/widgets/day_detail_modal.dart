import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/animated_refresh_action.dart';
import '../../entry/providers/entry_provider.dart';
import '../models/history_model.dart';
import '../providers/history_provider.dart';
import 'audit_history_modal.dart';

class DayDetailModal extends ConsumerStatefulWidget {
  final String date;
  final int initialTab; // 0 = Comparison, 1 = Audit Trail

  const DayDetailModal({
    super.key,
    required this.date,
    this.initialTab = 0,
  });

  static Future<void> show(BuildContext context, String date, {int initialTab = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DayDetailModal(date: date, initialTab: initialTab),
    );
  }

  @override
  ConsumerState<DayDetailModal> createState() => _DayDetailModalState();
}

class _DayDetailModalState extends ConsumerState<DayDetailModal> {
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  void _navigateToEdit(BuildContext context, WidgetRef ref, String slot) {
    Navigator.of(context).pop(); // close modal
    ref.read(selectedDateProvider.notifier).state = widget.date;
    ref.read(selectedSlotProvider.notifier).state = slot;
    context.push('/entry');
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(dayDetailProvider(widget.date));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entry Details: ${widget.date}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _activeTab == 0
                              ? 'Side-by-side comparison (Afternoon vs Evening)'
                              : 'Complete audit history for this day',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        AnimatedRefreshAction(
                          onRefresh: () async {
                            ref.invalidate(dayDetailProvider(widget.date));
                            ref.invalidate(auditHistoryProvider(AuditQueryParam(date: widget.date, slot: 'ALL')));
                            ref.invalidate(auditHistoryProvider(AuditQueryParam(date: widget.date, slot: 'AFTERNOON')));
                            ref.invalidate(auditHistoryProvider(AuditQueryParam(date: widget.date, slot: 'EVENING')));
                            await ref.read(dayDetailProvider(widget.date).future);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tabs: Comparison vs Audit Trail
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        icon: Icon(Icons.compare_arrows, size: 16),
                        label: Text('Comparison', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: Icon(Icons.history, size: 16),
                        label: Text('Audit Trail', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_activeTab},
                    onSelectionChanged: (set) {
                      setState(() {
                        _activeTab = set.first;
                      });
                    },
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),

              // Tab 0: Comparison Table
              if (_activeTab == 0) ...[
                // Action Buttons Bar
                Container(
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _navigateToEdit(context, ref, 'AFTERNOON'),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Afternoon', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => _navigateToEdit(context, ref, 'EVENING'),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Evening', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Table Body
                Expanded(
                  child: detailAsync.when(
                    skipLoadingOnReload: false,
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Failed to load entry details: $err'),
                      ),
                    ),
                    data: (data) {
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(14),
                        itemCount: data.evening.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final eveningItem = data.evening[index];
                          final morningItem = data.morning.firstWhere(
                            (m) => m.sectionId == eveningItem.sectionId,
                            orElse: () => eveningItem,
                          );

                          return _buildSectionComparisonCard(morningItem, eveningItem);
                        },
                      );
                    },
                  ),
                ),
              ] else ...[
                // Tab 1: Audit Trail View (embedded directly, no second popup!)
                Expanded(
                  child: AuditHistoryView(
                    date: widget.date,
                    initialSlot: 'ALL',
                    scrollController: scrollController,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionComparisonCard(DayDetailSectionItem morning, DayDetailSectionItem evening) {
    final isTriple = evening.countType == 'TRIPLE';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: evening.inCoreTotal ? AppTheme.primary : AppTheme.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  evening.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                evening.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              if (evening.inCoreTotal)
                const Text(
                  'Core Section',
                  style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Side-by-side comparison table
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
            },
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text('Afternoon\n(Reference)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.textSecondary)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text('Evening\n(Used in totals)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.primary)),
                  ),
                ],
              ),
              // Amount row
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Text(morning.isEntered ? CurrencyFormatter.format(morning.amount) : '-', style: const TextStyle(fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Text(
                      evening.isEntered ? CurrencyFormatter.format(evening.amount) : '-',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
              // Job counts rows
              if (!isTriple)
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Text('Jobs Done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Text(morning.isEntered ? (morning.jobsCompleted ?? 0).toString() : '-', style: const TextStyle(fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Text(evening.isEntered ? (evening.jobsCompleted ?? 0).toString() : '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              else ...[
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text('New Job Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(morning.isEntered ? CurrencyFormatter.format(morning.newJobsAmount ?? 0) : '-', style: const TextStyle(fontSize: 11)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(evening.isEntered ? CurrencyFormatter.format(evening.newJobsAmount ?? 0) : '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text('Outstanding Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(morning.isEntered ? CurrencyFormatter.format(morning.outstandingJobsAmount ?? 0) : '-', style: const TextStyle(fontSize: 11)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(evening.isEntered ? CurrencyFormatter.format(evening.outstandingJobsAmount ?? 0) : '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
