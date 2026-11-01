import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_tracker/features/entry/models/section_model.dart';

void main() {
  group('Live Totals Calculation Logic', () {
    test('computes Total 1 and Total 2 matching business rules', () {
      final entries = [
        SectionEntryInput(sectionId: 1, code: 'EXIM', name: 'EXIM', inCoreTotal: true, countType: 'SINGLE', amount: 1000.0),
        SectionEntryInput(sectionId: 2, code: 'CRO', name: 'CRO', inCoreTotal: true, countType: 'SINGLE', amount: 2000.0),
        SectionEntryInput(sectionId: 3, code: 'GST', name: 'GST', inCoreTotal: true, countType: 'SINGLE', amount: 500.0),
        SectionEntryInput(sectionId: 4, code: 'ACCOUNTS', name: 'ACCOUNTS', inCoreTotal: false, countType: 'TRIPLE', amount: 300.0),
        SectionEntryInput(sectionId: 5, code: 'REGISTRATION', name: 'REGISTRATION', inCoreTotal: true, countType: 'SINGLE', amount: 700.0),
        SectionEntryInput(sectionId: 6, code: 'MARKETING', name: 'MARKETING', inCoreTotal: false, countType: 'SINGLE', amount: 400.0),
      ];

      double t1 = 0.0;
      double t2 = 0.0;

      for (final item in entries) {
        t2 += item.amount;
        if (item.inCoreTotal) {
          t1 += item.amount;
        }
      }

      expect(t1, 4200.0);
      expect(t2, 4900.0);
    });

    test('serializes SINGLE and TRIPLE entries correctly according to API constraints', () {
      final single = SectionEntryInput(
        sectionId: 1,
        code: 'EXIM',
        name: 'EXIM',
        inCoreTotal: true,
        countType: 'SINGLE',
        amount: 1500.0,
        jobsCompleted: 5,
        ongoingJobs: 10, // Should be omitted in json
      );

      final singleJson = single.toJson();
      expect(singleJson['section_id'], 1);
      expect(singleJson['amount'], 1500.0);
      expect(singleJson['jobs_completed'], 5);
      expect(singleJson.containsKey('ongoing_jobs'), false);

      final triple = SectionEntryInput(
        sectionId: 4,
        code: 'ACCOUNTS',
        name: 'ACCOUNTS',
        inCoreTotal: false,
        countType: 'TRIPLE',
        amount: 2500.0,
        newJobsAmount: 1500.0,
        outstandingJobsAmount: 1000.0,
        jobsCompleted: 99, // Should be omitted in json
      );

      final tripleJson = triple.toJson();
      expect(tripleJson['section_id'], 4);
      expect(tripleJson['amount'], 2500.0);
      expect(tripleJson['new_jobs_amount'], 1500.0);
      expect(tripleJson['outstanding_jobs_amount'], 1000.0);
      expect(tripleJson.containsKey('jobs_completed'), false);
      expect(tripleJson.containsKey('ongoing_jobs'), false);
    });
  });
}

