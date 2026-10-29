import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class MonthSelectorBar extends StatelessWidget {
  final String currentMonth; // 'YYYY-MM'
  final ValueChanged<String> onMonthChanged;

  const MonthSelectorBar({
    super.key,
    required this.currentMonth,
    required this.onMonthChanged,
  });

  void _changeMonth(int offset) {
    final parts = currentMonth.split('-').map(int.parse).toList();
    final date = DateTime(parts[0], parts[1] + offset, 1);
    final newMonth = DateFormat('yyyy-MM').format(date);
    onMonthChanged(newMonth);
  }

  @override
  Widget build(BuildContext context) {
    final parts = currentMonth.split('-').map(int.parse).toList();
    final date = DateTime(parts[0], parts[1], 1);
    final displayTitle = DateFormat('MMMM yyyy').format(date);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.primary),
            tooltip: 'Previous Month',
            visualDensity: VisualDensity.compact,
            onPressed: () => _changeMonth(-1),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    displayTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.primary),
            tooltip: 'Next Month',
            visualDensity: VisualDensity.compact,
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }
}
