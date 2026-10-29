import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final selectedMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return DateFormat('yyyy-MM').format(now);
});

