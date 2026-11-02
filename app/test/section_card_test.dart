import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_tracker/features/entry/models/section_model.dart';
import 'package:revenue_tracker/features/entry/widgets/section_card.dart';

void main() {
  group('SectionCard Multi-Digit Input Tests', () {
    testWidgets('allows entering multiple digits without resetting or blocking after 1 digit', (tester) async {
      var currentEntry = SectionEntryInput(
        sectionId: 1,
        code: 'EXIM',
        name: 'Export Import',
        inCoreTotal: true,
        countType: 'SINGLE',
        amount: 0.0,
        jobsCompleted: 0,
      );

      double recordedAmount = 0.0;
      int recordedJobs = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SectionCard(
                  key: const ValueKey('section_1'),
                  entry: currentEntry,
                  onAmountChanged: (amt) {
                    recordedAmount = amt;
                    setState(() {
                      currentEntry = SectionEntryInput(
                        sectionId: currentEntry.sectionId,
                        code: currentEntry.code,
                        name: currentEntry.name,
                        inCoreTotal: currentEntry.inCoreTotal,
                        countType: currentEntry.countType,
                        amount: amt,
                        jobsCompleted: currentEntry.jobsCompleted,
                      );
                    });
                  },
                  onJobCountsChanged: ({jobsCompleted, ongoing, newJobs, outstanding}) {
                    recordedJobs = jobsCompleted ?? 0;
                    setState(() {
                      currentEntry = SectionEntryInput(
                        sectionId: currentEntry.sectionId,
                        code: currentEntry.code,
                        name: currentEntry.name,
                        inCoreTotal: currentEntry.inCoreTotal,
                        countType: currentEntry.countType,
                        amount: currentEntry.amount,
                        jobsCompleted: jobsCompleted ?? currentEntry.jobsCompleted,
                      );
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Find the Amount text field (first TextFormField)
      final amountFinder = find.widgetWithText(TextFormField, 'Amount (₹)');
      expect(amountFinder, findsOneWidget);

      // Focus and enter first digit '1'
      await tester.enterText(amountFinder, '1');
      await tester.pumpAndSettle();
      expect(recordedAmount, 1.0);
      expect(find.descendant(of: amountFinder, matching: find.text('1')), findsOneWidget);

      // Enter second digit '12'
      await tester.enterText(amountFinder, '12');
      await tester.pumpAndSettle();
      expect(recordedAmount, 12.0);
      expect(find.descendant(of: amountFinder, matching: find.text('12')), findsOneWidget);

      // Enter more digits '1250'
      await tester.enterText(amountFinder, '1250');
      await tester.pumpAndSettle();
      expect(recordedAmount, 1250.0);
      expect(find.descendant(of: amountFinder, matching: find.text('1250')), findsOneWidget);

      // Enter decimal places '1250.75'
      await tester.enterText(amountFinder, '1250.75');
      await tester.pumpAndSettle();
      expect(recordedAmount, 1250.75);
      expect(find.descendant(of: amountFinder, matching: find.text('1250.75')), findsOneWidget);

      // Find Jobs Completed field
      final jobsFinder = find.widgetWithText(TextFormField, 'Jobs Completed');
      expect(jobsFinder, findsOneWidget);

      // Enter first digit '2'
      await tester.enterText(jobsFinder, '2');
      await tester.pumpAndSettle();
      expect(recordedJobs, 2);
      expect(find.descendant(of: jobsFinder, matching: find.text('2')), findsOneWidget);

      // Enter second digit '25'
      await tester.enterText(jobsFinder, '25');
      await tester.pumpAndSettle();
      expect(recordedJobs, 25);
      expect(find.descendant(of: jobsFinder, matching: find.text('25')), findsOneWidget);
    });

    testWidgets('allows multi-digit entry in ACCOUNTS breakdown fields', (tester) async {
      var currentEntry = SectionEntryInput(
        sectionId: 4,
        code: 'ACCOUNTS',
        name: 'Accounts',
        inCoreTotal: false,
        countType: 'TRIPLE',
        amount: 0.0,
        newJobsAmount: 0.0,
        outstandingJobsAmount: 0.0,
      );

      double recordedNewJobs = 0.0;
      double recordedOutstanding = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SectionCard(
                  key: const ValueKey('section_accounts'),
                  entry: currentEntry,
                  onAmountChanged: (_) {},
                  onJobCountsChanged: ({jobsCompleted, ongoing, newJobs, outstanding}) {},
                  onAccountsAmountsChanged: ({newJobsAmount, outstandingJobsAmount}) {
                    if (newJobsAmount != null) recordedNewJobs = newJobsAmount;
                    if (outstandingJobsAmount != null) recordedOutstanding = outstandingJobsAmount;
                    setState(() {
                      final nja = newJobsAmount ?? currentEntry.newJobsAmount ?? 0.0;
                      final oja = outstandingJobsAmount ?? currentEntry.outstandingJobsAmount ?? 0.0;
                      currentEntry = SectionEntryInput(
                        sectionId: currentEntry.sectionId,
                        code: currentEntry.code,
                        name: currentEntry.name,
                        inCoreTotal: currentEntry.inCoreTotal,
                        countType: currentEntry.countType,
                        amount: nja + oja,
                        newJobsAmount: nja,
                        outstandingJobsAmount: oja,
                      );
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      final newJobsFinder = find.widgetWithText(TextFormField, 'New Job Amount (₹)');
      final outstandingFinder = find.widgetWithText(TextFormField, 'Outstanding Amount (₹)');
      final totalFinder = find.widgetWithText(TextFormField, 'Total Amount (₹) [Auto-calculated]');

      expect(newJobsFinder, findsOneWidget);
      expect(outstandingFinder, findsOneWidget);
      expect(totalFinder, findsOneWidget);

      // Enter multi-digit new jobs amount
      await tester.enterText(newJobsFinder, '5');
      await tester.pumpAndSettle();
      expect(recordedNewJobs, 5.0);

      await tester.enterText(newJobsFinder, '500');
      await tester.pumpAndSettle();
      expect(recordedNewJobs, 500.0);
      expect(find.descendant(of: newJobsFinder, matching: find.text('500')), findsOneWidget);

      // Enter multi-digit outstanding amount
      await tester.enterText(outstandingFinder, '350');
      await tester.pumpAndSettle();
      expect(recordedOutstanding, 350.0);
      expect(find.descendant(of: outstandingFinder, matching: find.text('350')), findsOneWidget);

      // Check auto-calculated total is 850
      expect(find.descendant(of: totalFinder, matching: find.text('850')), findsOneWidget);
    });
  });
}

