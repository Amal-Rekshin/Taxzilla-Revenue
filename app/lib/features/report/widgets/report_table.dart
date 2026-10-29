import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/report_model.dart';

class ReportTable extends StatelessWidget {
  final MonthlyReportModel report;

  const ReportTable({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Horizontally scrollable calendar days table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: AppTheme.border),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.primary),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  dataRowMinHeight: 38,
                  dataRowMaxHeight: 44,
                  columnSpacing: 18,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('EXIM')),
                    DataColumn(label: Text('CRO')),
                    DataColumn(label: Text('GST')),
                    DataColumn(label: Text('Accounts')),
                    DataColumn(label: Text('Registration')),
                    DataColumn(label: Text('Marketing')),
                    DataColumn(label: Text('Total 1')),
                    DataColumn(label: Text('Total 2')),
                    DataColumn(label: Text('EXIM Jobs')),
                    DataColumn(label: Text('CRO Jobs')),
                    DataColumn(label: Text('GST Jobs')),
                    DataColumn(label: Text('Reg Jobs')),
                    DataColumn(label: Text('Mkt Jobs')),
                    DataColumn(label: Text('Acc Ongoing')),
                    DataColumn(label: Text('Acc New')),
                    DataColumn(label: Text('Acc Outstanding')),
                  ],
                  rows: _buildAllRows(context),
                ),
              ),
            ),
          ),
        ),

        // Sticky "Month Total" summary row at the bottom
        _buildStickyTotalRow(context),
      ],
    );
  }

  List<DataRow> _buildAllRows(BuildContext context) {
    final rows = <DataRow>[];
    int weekIdx = 0;

    for (int i = 0; i < report.days.length; i++) {
      final day = report.days[i];
      rows.add(_buildDayRow(day));

      final isLastDay = i == report.days.length - 1;
      if (day.isSunday || isLastDay) {
        if (weekIdx < report.weeks.length) {
          final week = report.weeks[weekIdx];
          rows.add(_buildWeekTotalRow(week));
          weekIdx++;
        }
      }
    }
    return rows;
  }

  DataRow _buildDayRow(ReportDayModel day) {
    final isPending = day.isPending;
    final isSunday = day.isSunday;

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (isSunday) {
          return const Color(0xFFFBF8FD); // Very gentle tint for Sunday
        }
        if (isPending) {
          return AppTheme.pendingWarning.withValues(alpha: 0.06);
        }
        return null;
      }),
      cells: [
        DataCell(Text(
          day.date.substring(5), // 'MM-DD'
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSunday
                ? AppTheme.primary
                : (isPending ? AppTheme.textSecondary : AppTheme.textPrimary),
          ),
        )),
        DataCell(
          isSunday
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Sunday',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                )
              : (isPending
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.pendingWarning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    )
                  : const Icon(Icons.check_circle, color: AppTheme.success, size: 16)),
        ),
        DataCell(Text(isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['EXIM']))),
        DataCell(Text(isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['CRO']))),
        DataCell(Text(isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['GST']))),
        DataCell(Text(isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['ACCOUNTS']))),
        DataCell(Text(isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['REGISTRATION']))),
        DataCell(Text(isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['MARKETING']))),
        DataCell(Text(
          isPending || isSunday ? '-' : CurrencyFormatter.format(day.total1),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
        )),
        DataCell(Text(
          isPending || isSunday ? '-' : CurrencyFormatter.format(day.total2),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
        )),
        DataCell(Text(isPending || isSunday ? '-' : (day.jobs['EXIM'] ?? 0).toString())),
        DataCell(Text(isPending || isSunday ? '-' : (day.jobs['CRO'] ?? 0).toString())),
        DataCell(Text(isPending || isSunday ? '-' : (day.jobs['GST'] ?? 0).toString())),
        DataCell(Text(isPending || isSunday ? '-' : (day.jobs['REGISTRATION'] ?? 0).toString())),
        DataCell(Text(isPending || isSunday ? '-' : (day.jobs['MARKETING'] ?? 0).toString())),
        DataCell(Text(isPending || isSunday ? '-' : day.accounts.ongoingJobs.toString())),
        DataCell(Text(isPending || isSunday ? '-' : day.accounts.newJobs.toString())),
        DataCell(Text(isPending || isSunday ? '-' : day.accounts.outstandingJobs.toString())),
      ],
    );
  }

  DataRow _buildWeekTotalRow(ReportWeekModel week) {
    final totals = week.totals;

    return DataRow(
      color: WidgetStateProperty.all(const Color(0xFFF5EEF9)), // Brand lavender subtotal row
      cells: [
        DataCell(Text(
          '${week.label} Total',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
        )),
        DataCell(Text(
          '${week.startDate.substring(5)} to ${week.endDate.substring(5)}',
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
        )),
        DataCell(Text(CurrencyFormatter.format(totals.amounts['EXIM']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataCell(Text(CurrencyFormatter.format(totals.amounts['CRO']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataCell(Text(CurrencyFormatter.format(totals.amounts['GST']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataCell(Text(CurrencyFormatter.format(totals.amounts['ACCOUNTS']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataCell(Text(CurrencyFormatter.format(totals.amounts['REGISTRATION']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataCell(Text(CurrencyFormatter.format(totals.amounts['MARKETING']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataCell(Text(
          CurrencyFormatter.format(totals.total1),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
        )),
        DataCell(Text(
          CurrencyFormatter.format(totals.total2),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 12),
        )),
        DataCell(Text((totals.jobs['EXIM'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text((totals.jobs['CRO'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text((totals.jobs['GST'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text((totals.jobs['REGISTRATION'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text((totals.jobs['MARKETING'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(
          totals.accounts.ongoingJobs.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
        )),
        DataCell(Text(
          totals.accounts.newJobs.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        DataCell(Text(
          totals.accounts.outstandingJobs.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
        )),
      ],
    );
  }

  Widget _buildStickyTotalRow(BuildContext context) {
    final totals = report.monthTotals;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Light slate
        border: const Border(
          top: BorderSide(color: AppTheme.primary, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 0,
          dataRowMinHeight: 46,
          dataRowMaxHeight: 50,
          columnSpacing: 18,
          horizontalMargin: 12,
          columns: const [
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
          ],
          rows: [
            DataRow(
              cells: [
                const DataCell(Text(
                  'Month Total',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                )),
                const DataCell(Text('')),
                DataCell(Text(CurrencyFormatter.format(totals.amounts['EXIM']), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(CurrencyFormatter.format(totals.amounts['CRO']), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(CurrencyFormatter.format(totals.amounts['GST']), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(CurrencyFormatter.format(totals.amounts['ACCOUNTS']), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(CurrencyFormatter.format(totals.amounts['REGISTRATION']), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(CurrencyFormatter.format(totals.amounts['MARKETING']), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(
                  CurrencyFormatter.format(totals.total1),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                )),
                DataCell(Text(
                  CurrencyFormatter.format(totals.total2),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 13),
                )),
                DataCell(Text((totals.jobs['EXIM'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text((totals.jobs['CRO'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text((totals.jobs['GST'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text((totals.jobs['REGISTRATION'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text((totals.jobs['MARKETING'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(
                  totals.accounts.ongoingJobs.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                )),
                DataCell(Text(
                  totals.accounts.newJobs.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
                DataCell(Text(
                  totals.accounts.outstandingJobs.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

