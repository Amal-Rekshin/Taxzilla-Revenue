import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/animated_refresh_action.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../report/providers/report_provider.dart';
import '../providers/entry_provider.dart';
import '../widgets/live_totals_bar.dart';
import '../widgets/section_card.dart';

class DailyEntryScreen extends ConsumerStatefulWidget {
  final String? initialDate;
  final String? initialSlot;

  const DailyEntryScreen({
    super.key,
    this.initialDate,
    this.initialSlot,
  });

  @override
  ConsumerState<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends ConsumerState<DailyEntryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialDate != null) {
        ref.read(selectedDateProvider.notifier).state = widget.initialDate!;
      }
      if (widget.initialSlot != null) {
        ref.read(selectedSlotProvider.notifier).state = widget.initialSlot!;
      }
      _loadData();
    });
  }

  void _loadData() {
    final date = ref.read(selectedDateProvider);
    final slot = ref.read(selectedSlotProvider);
    ref.read(entryFormNotifierProvider.notifier).loadEntriesForDateAndSlot(date, slot);
  }

  Future<void> _selectDate() async {
    final currentDateStr = ref.read(selectedDateProvider);
    final currentDate = DateTime.tryParse(currentDateStr) ?? DateTime.now();
    final today = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate.isAfter(today) ? today : currentDate,
      firstDate: DateTime(2020),
      lastDate: today, // Block future dates
      helpText: 'Select Entry Date',
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      if (formatted != currentDateStr) {
        final isDirty = ref.read(entryFormNotifierProvider).isDirty;
        if (isDirty) {
          final confirm = await _showDiscardChangesDialog();
          if (!confirm) return;
        }
        ref.read(selectedDateProvider.notifier).state = formatted;
        _loadData();
      }
    }
  }

  Future<bool> _showDiscardChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes in this form. Discard changes and proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _showEditConfirmationDialog(List<Map<String, dynamic>> changes) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Past-Date Edit'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You are modifying entries for a past date. Please review the changes:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: changes.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final c = changes[index];
                    final sectionName = c['sectionName'] as String;
                    final fieldChanges = c['changes'] as Map<String, Map<String, dynamic>>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sectionName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 4),
                        ...fieldChanges.entries.map((f) {
                          final oldVal = f.key == 'Amount'
                              ? CurrencyFormatter.format(f.value['old'] as num)
                              : f.value['old'].toString();
                          final newVal = f.key == 'Amount'
                              ? CurrencyFormatter.format(f.value['new'] as num)
                              : f.value['new'].toString();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.0),
                            child: Row(
                              children: [
                                Text('${f.key}: ', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                Text(oldVal, style: const TextStyle(fontSize: 12, color: AppTheme.error, decoration: TextDecoration.lineThrough)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward, size: 12, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(newVal, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.success)),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    final date = ref.read(selectedDateProvider);
    final slot = ref.read(selectedSlotProvider);

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isPastDate = date.compareTo(today) < 0;

    if (isPastDate) {
      final changes = ref.read(entryFormNotifierProvider.notifier).getChangedFields();
      if (changes.isNotEmpty) {
        final confirmed = await _showEditConfirmationDialog(changes);
        if (!confirmed) return;
      }
    }

    final success = await ref
        .read(entryFormNotifierProvider.notifier)
        .saveEntries(date, slot);

    if (mounted) {
      final state = ref.read(entryFormNotifierProvider);
      if (success) {
        // Automatically invalidate all related providers so no stale data exists
        ref.invalidate(dashboardProvider);
        ref.invalidate(entriesHistoryProvider);
        ref.invalidate(monthlyReportProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.successMessage ?? 'Entries saved successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedSlot = ref.watch(selectedSlotProvider);
    final formState = ref.watch(entryFormNotifierProvider);
    final sectionsAsync = ref.watch(sectionsProvider);

    final isEvening = selectedSlot == 'EVENING';

    return PopScope(
      canPop: !formState.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _showDiscardChangesDialog();
        if (discard && context.mounted) {
          ref.read(entryFormNotifierProvider.notifier).resetDirty();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily Revenue Entry'),
          actions: [
            // Date Selector Button
            TextButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
              label: Text(
                DateFormat('dd MMM yyyy').format(DateTime.parse(selectedDate)),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            AnimatedRefreshAction(
              tooltip: 'Reload Form',
              onRefresh: () async {
                ref.invalidate(sectionsProvider);
                await ref.read(sectionsProvider.future);
                _loadData();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: sectionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: AppTheme.error),
                  const SizedBox(height: 12),
                  Text('Failed to load sections: $err', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.refresh(sectionsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (sections) {
            return Column(
              children: [
                // Slot Selector Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Afternoon', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Reference only', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          selected: selectedSlot == 'AFTERNOON' || selectedSlot == 'MORNING',
                          selectedColor: AppTheme.primaryLight.withValues(alpha: 0.2),
                          onSelected: (selected) async {
                            if (selected && selectedSlot != 'AFTERNOON') {
                              if (formState.isDirty) {
                                final confirm = await _showDiscardChangesDialog();
                                if (!confirm) return;
                              }
                              ref.read(selectedSlotProvider.notifier).state = 'AFTERNOON';
                              _loadData();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Evening', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Counts in totals', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                          selected: selectedSlot == 'EVENING',
                          selectedColor: AppTheme.primary.withValues(alpha: 0.18),
                          onSelected: (selected) async {
                            if (selected && selectedSlot != 'EVENING') {
                              if (formState.isDirty) {
                                final confirm = await _showDiscardChangesDialog();
                                if (!confirm) return;
                              }
                              ref.read(selectedSlotProvider.notifier).state = 'EVENING';
                              _loadData();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Sunday notice banner if selected date is Sunday
                if (DateTime.tryParse(selectedDate)?.weekday == DateTime.sunday)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.event_busy, size: 18, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sunday is a non-working day. Entries are optional.',
                            style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Section Cards List
                Expanded(
                  child: formState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 20),
                          itemCount: formState.entries.length,
                          itemBuilder: (context, index) {
                            final entryItem = formState.entries[index];
                            return SectionCard(
                              key: ValueKey('${entryItem.sectionId}_$selectedDate}_$selectedSlot'),
                              entry: entryItem,
                              onAmountChanged: (amt) {
                                ref.read(entryFormNotifierProvider.notifier).updateAmount(entryItem.sectionId, amt);
                              },
                              onJobCountsChanged: ({jobsCompleted, ongoing, newJobs, outstanding}) {
                                ref.read(entryFormNotifierProvider.notifier).updateJobCount(
                                      entryItem.sectionId,
                                      jobsCompleted: jobsCompleted,
                                      ongoing: ongoing,
                                      newJobs: newJobs,
                                      outstanding: outstanding,
                                    );
                              },
                            );
                          },
                        ),
                ),

                // Live Totals Bar
                LiveTotalsBar(
                  total1: formState.liveTotal1,
                  total2: formState.liveTotal2,
                  isEvening: isEvening,
                ),

                // Bottom Save Action Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: ElevatedButton.icon(
                    onPressed: formState.isSaving ? null : _save,
                    icon: formState.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      formState.isSaving ? 'Saving...' : 'Save $selectedSlot Entry',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
