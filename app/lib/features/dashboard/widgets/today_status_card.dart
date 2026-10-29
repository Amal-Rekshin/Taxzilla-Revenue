import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/dashboard_model.dart';

class TodayStatusCard extends StatelessWidget {
  final DashboardTodayModel today;

  const TodayStatusCard({
    super.key,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(today.date) ?? DateTime.now();
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(parsedDate);

    final needsMorning = !today.morningDone;
    final needsEvening = !today.eveningDone;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.today_rounded, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Today's Entry Status",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Afternoon status
                Expanded(
                  child: _buildSlotStatus(
                    label: 'Afternoon (Reference)',
                    isDone: today.morningDone,
                  ),
                ),
                const SizedBox(width: 12),
                // Evening status
                Expanded(
                  child: _buildSlotStatus(
                    label: 'Evening (Totals)',
                    isDone: today.eveningDone,
                  ),
                ),
              ],
            ),
            if (needsMorning || needsEvening) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size.fromHeight(42),
                ),
                onPressed: () {
                  context.push('/entry');
                },
                icon: const Icon(Icons.edit_calendar, size: 18),
                label: Text(
                  needsEvening && needsMorning
                      ? 'Enter Today’s Revenue'
                      : (needsEvening ? 'Enter Today’s Evening' : 'Enter Today’s Afternoon'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlotStatus({required String label, required bool isDone}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDone
            ? AppTheme.success.withValues(alpha: 0.08)
            : AppTheme.pendingWarning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone
              ? AppTheme.success.withValues(alpha: 0.3)
              : AppTheme.pendingWarning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.pending_outlined,
            color: isDone ? AppTheme.success : AppTheme.pendingWarning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isDone ? 'Entered' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDone ? AppTheme.success : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

