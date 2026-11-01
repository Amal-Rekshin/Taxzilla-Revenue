import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/history_model.dart';
import '../providers/history_provider.dart';

class AuditHistoryView extends ConsumerStatefulWidget {
  final String date;
  final String initialSlot;
  final ScrollController? scrollController;

  const AuditHistoryView({
    super.key,
    required this.date,
    this.initialSlot = 'ALL',
    this.scrollController,
  });

  @override
  ConsumerState<AuditHistoryView> createState() => _AuditHistoryViewState();
}

class _AuditHistoryViewState extends ConsumerState<AuditHistoryView> {
  late String _activeSlot;

  @override
  void initState() {
    super.initState();
    _activeSlot = widget.initialSlot;
  }

  @override
  Widget build(BuildContext context) {
    final auditAsync = ref.watch(
      auditHistoryProvider(AuditQueryParam(date: widget.date, slot: _activeSlot)),
    );

    return Column(
      children: [
        // Slot Filter Bar: All | Afternoon | Evening
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: const Color(0xFFF8FAFC),
          child: Row(
            children: [
              _buildSlotFilterChip('ALL', 'All Slots'),
              const SizedBox(width: 8),
              _buildSlotFilterChip('AFTERNOON', 'Afternoon'),
              const SizedBox(width: 8),
              _buildSlotFilterChip('EVENING', 'Evening'),
            ],
          ),
        ),
        const Divider(height: 1),

        // List of audit items
        Expanded(
          child: auditAsync.when(
            skipLoadingOnReload: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Failed to load audit history: $err'),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                final slotText = _activeSlot == 'ALL'
                    ? 'this date'
                    : (_activeSlot == 'AFTERNOON' || _activeSlot == 'MORNING' ? 'afternoon slot' : 'evening slot');
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history, size: 48, color: AppTheme.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'No audit records found for $slotText.',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final audit = items[index];
                  return _buildAuditItemCard(audit);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlotFilterChip(String slotKey, String label) {
    final isSelected = _activeSlot == slotKey;
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
          setState(() {
            _activeSlot = slotKey;
          });
        }
      },
    );
  }

  Widget _buildAuditItemCard(HistoryAuditItem audit) {
    DateTime? changedTime;
    try {
      changedTime = DateTime.parse(audit.changedAt).toLocal();
    } catch (_) {}

    final timeStr = changedTime != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(changedTime)
        : audit.changedAt;

    final oldAmount = audit.oldValues?['amount']?.toString();
    final newAmount = audit.newValues['amount']?.toString();
    final isAfternoon = audit.slot == 'AFTERNOON' || audit.slot == 'MORNING';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF), // Light purple background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Slot Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isAfternoon ? const Color(0xFFF59E0B) : AppTheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isAfternoon ? 'AFTERNOON' : audit.slot,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Section Code Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      audit.sectionCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    audit.sectionName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Text(
                timeStr,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Edited by: ${audit.changedByUsername ?? 'Unknown'}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Amount diff
          if (oldAmount != null && newAmount != null && oldAmount != newAmount)
            _buildDiffRow(
              'Amount',
              CurrencyFormatter.format(double.tryParse(oldAmount) ?? 0),
              CurrencyFormatter.format(double.tryParse(newAmount) ?? 0),
            ),

          // Single section jobs_completed diff
          if (audit.oldValues?['jobs_completed'] != audit.newValues['jobs_completed'])
            _buildDiffRow(
              'Jobs Completed',
              audit.oldValues?['jobs_completed']?.toString() ?? 'None',
              audit.newValues['jobs_completed']?.toString() ?? 'None',
            ),

          // Accounts amounts diffs
          if (audit.oldValues?['new_jobs_amount'] != audit.newValues['new_jobs_amount'])
            _buildDiffRow(
              'New Job Amount',
              audit.oldValues?['new_jobs_amount'] != null ? CurrencyFormatter.format(num.tryParse(audit.oldValues!['new_jobs_amount'].toString())) : 'None',
              audit.newValues['new_jobs_amount'] != null ? CurrencyFormatter.format(num.tryParse(audit.newValues['new_jobs_amount'].toString())) : 'None',
            ),
          if (audit.oldValues?['outstanding_jobs_amount'] != audit.newValues['outstanding_jobs_amount'])
            _buildDiffRow(
              'Outstanding Amount',
              audit.oldValues?['outstanding_jobs_amount'] != null ? CurrencyFormatter.format(num.tryParse(audit.oldValues!['outstanding_jobs_amount'].toString())) : 'None',
              audit.newValues['outstanding_jobs_amount'] != null ? CurrencyFormatter.format(num.tryParse(audit.newValues['outstanding_jobs_amount'].toString())) : 'None',
            ),
        ],
      ),
    );
  }

  Widget _buildDiffRow(String field, String oldVal, String newVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$field:',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
          ),
          Text(
            oldVal,
            style: const TextStyle(fontSize: 12, color: AppTheme.error, decoration: TextDecoration.lineThrough),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0),
            child: Icon(Icons.arrow_forward, size: 12, color: AppTheme.textSecondary),
          ),
          Text(
            newVal,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.success),
          ),
        ],
      ),
    );
  }
}

class AuditHistoryModal extends StatelessWidget {
  final String date;
  final String slot;

  const AuditHistoryModal({
    super.key,
    required this.date,
    this.slot = 'ALL',
  });

  static Future<void> show(BuildContext context, String date, [String slot = 'ALL']) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AuditHistoryModal(date: date, slot: slot),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Audit Trail',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Date: $date',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content Body
              Expanded(
                child: AuditHistoryView(
                  date: date,
                  initialSlot: slot,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
