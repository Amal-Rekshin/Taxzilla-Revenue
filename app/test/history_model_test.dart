import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_tracker/features/history/models/history_model.dart';

void main() {
  group('History Models Deserialization Tests', () {
    test('parses history day list items correctly', () {
      final json = {
        'date': '2026-09-10',
        'morningDone': true,
        'eveningDone': true,
        'total1': 2500.0,
        'total2': 3500.0,
        'isPending': false,
        'isEdited': true,
        'lastUpdatedBy': 'admin',
        'lastUpdatedAt': '2026-10-28T22:30:00.000Z',
      };

      final item = HistoryDayItem.fromJson(json);

      expect(item.date, '2026-09-10');
      expect(item.morningDone, true);
      expect(item.eveningDone, true);
      expect(item.total1, 2500.0);
      expect(item.total2, 3500.0);
      expect(item.isPending, false);
      expect(item.isEdited, true);
      expect(item.lastUpdatedBy, 'admin');
    });

    test('parses audit item record correctly with old and new values', () {
      final json = {
        'id': 1,
        'entry_date': '2026-09-10',
        'section_id': 1,
        'section_code': 'EXIM',
        'section_name': 'EXIM',
        'slot': 'EVENING',
        'old_values': {'amount': '1000.00', 'jobs_completed': 5},
        'new_values': {'amount': '2500.00', 'jobs_completed': 12},
        'changed_by_username': 'admin',
        'changed_at': '2026-10-28T22:30:00.000Z',
      };

      final audit = HistoryAuditItem.fromJson(json);

      expect(audit.id, 1);
      expect(audit.sectionCode, 'EXIM');
      expect(audit.oldValues?['amount'], '1000.00');
      expect(audit.newValues['amount'], '2500.00');
      expect(audit.changedByUsername, 'admin');
    });

    test('parses day detail side-by-side model correctly', () {
      final json = {
        'date': '2026-09-10',
        'morning': [
          {
            'section_id': 1,
            'code': 'EXIM',
            'name': 'EXIM',
            'in_core_total': true,
            'count_type': 'SINGLE',
            'amount': '500.00',
            'jobs_completed': 2,
            'is_entered': true,
          }
        ],
        'evening': [
          {
            'section_id': 1,
            'code': 'EXIM',
            'name': 'EXIM',
            'in_core_total': true,
            'count_type': 'SINGLE',
            'amount': '2500.00',
            'jobs_completed': 12,
            'is_entered': true,
          }
        ],
      };

      final detail = DayDetailModel.fromJson(json);

      expect(detail.date, '2026-09-10');
      expect(detail.morning.length, 1);
      expect(detail.evening.length, 1);
      expect(detail.morning[0].amount, 500.0);
      expect(detail.evening[0].amount, 2500.0);
    });
  });
}

