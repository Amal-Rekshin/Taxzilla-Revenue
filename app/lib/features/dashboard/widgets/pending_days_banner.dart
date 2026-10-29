import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PendingDaysBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const PendingDaysBanner({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'All days up to today have evening entries recorded!',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7), // Warm amber background
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count pending day${count == 1 ? '' : 's'} with no evening entry this month',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              const Text(
                'View list',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB45309),
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFB45309)),
            ],
          ),
        ),
      ),
    );
  }
}

