import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/dashboard_model.dart';

class MonthSummaryCards extends StatelessWidget {
  final double total1;
  final double total2;
  final DashboardPreviousMonthModel prevMonth;

  const MonthSummaryCards({
    super.key,
    required this.total1,
    required this.total2,
    required this.prevMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Row(
        children: [
          // Total 1 Card (Core)
          Expanded(
            child: _buildCard(
              title: 'Total 1 (Core)',
              amount: total1,
              diff: prevMonth.diffTotal1,
              pct: prevMonth.percentageChangeTotal1,
              accentColor: AppTheme.primary,
              sublabel: 'CRO + GST + REG + EXIM',
            ),
          ),
          const SizedBox(width: 12),
          // Total 2 Card (Grand)
          Expanded(
            child: _buildCard(
              title: 'Total 2 (Grand)',
              amount: total2,
              diff: prevMonth.diffTotal2,
              pct: prevMonth.percentageChangeTotal2,
              accentColor: AppTheme.secondary,
              sublabel: 'All 6 Sections',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required double amount,
    required double diff,
    required double? pct,
    required Color accentColor,
    required String sublabel,
  }) {
    final isPositive = diff >= 0;
    final hasPrevData = pct != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accentColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            // Comparison with previous month
            if (hasPrevData)
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isPositive ? AppTheme.success : AppTheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'vs last mo',
                    style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              )
            else
              const Text(
                'First recorded month',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

