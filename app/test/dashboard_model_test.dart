import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_tracker/features/dashboard/models/dashboard_model.dart';

void main() {
  group('DashboardModel Deserialization Tests', () {
    test('parses full backend dashboard payload correctly', () {
      final json = {
        'month': '2026-10',
        'totals': {'total1': 4200.0, 'total2': 4900.0},
        'sectionBreakdown': [
          {
            'code': 'EXIM',
            'name': 'EXIM',
            'in_core_total': true,
            'count_type': 'SINGLE',
            'amount': 1000.0,
            'jobs': 5,
            'percentageShare': 20.41,
          },
          {
            'code': 'ACCOUNTS',
            'name': 'ACCOUNTS',
            'in_core_total': false,
            'count_type': 'TRIPLE',
            'amount': 300.0,
            'jobs': 4,
            'percentageShare': 6.12,
          }
        ],
        'accounts': {
          'ongoing': 15,
          'newJobs': 4,
          'outstanding': 7,
        },
        'dailyTrend': [
          {
            'date': '2026-10-01',
            'total1': 0.0,
            'total2': 0.0,
            'status': 'PENDING',
          },
          {
            'date': '2026-10-05',
            'total1': 4200.0,
            'total2': 4900.0,
            'status': 'COMPLETE',
          }
        ],
        'today': {
          'date': '2026-10-29',
          'morningDone': true,
          'eveningDone': false,
        },
        'pendingDays': 3,
        'previousMonth': {
          'month': '2026-09',
          'total1': 3800.0,
          'total2': 4500.0,
          'diffTotal1': 400.0,
          'diffTotal2': 400.0,
          'percentageChangeTotal1': 10.53,
          'percentageChangeTotal2': 8.89,
        }
      };

      final dashboard = DashboardModel.fromJson(json);

      expect(dashboard.month, '2026-10');
      expect(dashboard.total1, 4200.0);
      expect(dashboard.total2, 4900.0);
      expect(dashboard.sectionBreakdown.length, 2);
      expect(dashboard.sectionBreakdown[0].code, 'EXIM');
      expect(dashboard.sectionBreakdown[0].percentageShare, 20.41);
      expect(dashboard.accounts.ongoing, 15);
      expect(dashboard.accounts.newJobs, 4);
      expect(dashboard.accounts.outstanding, 7);
      expect(dashboard.dailyTrend.length, 2);
      expect(dashboard.dailyTrend[1].total1, 4200.0);
      expect(dashboard.today.morningDone, true);
      expect(dashboard.today.eveningDone, false);
      expect(dashboard.pendingDays, 3);
      expect(dashboard.previousMonth.diffTotal1, 400.0);
      expect(dashboard.previousMonth.percentageChangeTotal1, 10.53);
    });
  });
}

