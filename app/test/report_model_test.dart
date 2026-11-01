import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_tracker/features/report/models/report_model.dart';

void main() {
  group('MonthlyReportModel Deserialization Tests', () {
    test('parses backend JSON payload correctly with pending and completed days', () {
      final json = {
        'month': '2026-10',
        'days': [
          {
            'date': '2026-10-01',
            'status': 'PENDING',
            'amounts': {'EXIM': 0.0, 'CRO': 0.0},
            'jobs': {'EXIM': 0, 'CRO': 0},
            'accounts': {'ongoing_jobs': 0, 'new_jobs': 0, 'outstanding_jobs': 0},
            'total1': 0.0,
            'total2': 0.0,
          },
          {
            'date': '2026-10-05',
            'status': 'COMPLETE',
            'amounts': {
              'EXIM': 1000.0,
              'CRO': 2000.0,
              'GST': 500.0,
              'ACCOUNTS': 300.0,
              'REGISTRATION': 700.0,
              'MARKETING': 400.0,
            },
            'jobs': {'EXIM': 2, 'CRO': 3, 'GST': 1, 'REGISTRATION': 4, 'MARKETING': 1},
            'accounts': {'ongoing_jobs': 15, 'new_jobs': 4, 'outstanding_jobs': 7},
            'total1': 4200.0,
            'total2': 4900.0,
          }
        ],
        'weeks': [
          {
            'weekNumber': 1,
            'label': 'Week 1',
            'startDate': '2026-10-01',
            'endDate': '2026-10-04',
            'dayCount': 4,
            'totals': {
              'total1': 0.0,
              'total2': 0.0,
              'amounts': {},
              'jobs': {},
              'accounts': {'ongoing_jobs': 0, 'new_jobs': 0, 'outstanding_jobs': 0},
            }
          }
        ],
        'monthTotals': {
          'total1': 4200.0,
          'total2': 4900.0,
          'amounts': {
            'EXIM': 1000.0,
            'CRO': 2000.0,
            'GST': 500.0,
            'ACCOUNTS': 300.0,
            'REGISTRATION': 700.0,
            'MARKETING': 400.0,
          },
          'jobs': {'EXIM': 2, 'CRO': 3, 'GST': 1, 'REGISTRATION': 4, 'MARKETING': 1},
          'accounts': {'ongoing_jobs': 15, 'new_jobs': 4, 'outstanding_jobs': 7},
        }
      };

      final report = MonthlyReportModel.fromJson(json);

      expect(report.month, '2026-10');
      expect(report.days.length, 2);
      expect(report.weeks.length, 1);
      expect(report.weeks[0].label, 'Week 1');
      expect(report.days[0].isPending, true);
      expect(report.days[1].isPending, false);
      expect(report.days[1].total1, 4200.0);
      expect(report.days[1].total2, 4900.0);
      expect(report.monthTotals.total1, 4200.0);
      expect(report.monthTotals.total2, 4900.0);
      expect(report.monthTotals.accounts.ongoingJobs, 15);
      expect(report.monthTotals.accounts.newJobs, 4);
      expect(report.monthTotals.accounts.outstandingJobs, 7);
    });
  });
}

