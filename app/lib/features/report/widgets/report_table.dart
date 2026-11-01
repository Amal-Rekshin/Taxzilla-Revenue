import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/report_model.dart';

class _ColumnSpec {
  final String title;
  final double width;
  final Alignment alignment;

  const _ColumnSpec({
    required this.title,
    required this.width,
    this.alignment = Alignment.centerRight,
  });
}

class ReportTable extends StatefulWidget {
  final MonthlyReportModel report;

  const ReportTable({super.key, required this.report});

  @override
  State<ReportTable> createState() => _ReportTableState();
}

class _ReportTableState extends State<ReportTable> {
  late final ScrollController _horizontalController;
  late final ScrollController _verticalController;

  static const List<_ColumnSpec> _columns = [
    _ColumnSpec(title: 'Date', width: 105, alignment: Alignment.centerLeft),
    _ColumnSpec(title: 'Status', width: 80, alignment: Alignment.center),
    _ColumnSpec(title: 'EXIM', width: 115, alignment: Alignment.centerRight),
    _ColumnSpec(title: 'GST', width: 115, alignment: Alignment.centerRight),
    _ColumnSpec(title: 'Registration', width: 115, alignment: Alignment.centerRight),
    _ColumnSpec(title: 'CRO', width: 115, alignment: Alignment.centerRight),
    _ColumnSpec(title: 'Accounts', width: 115, alignment: Alignment.centerRight),
    _ColumnSpec(title: 'Marketing', width: 115, alignment: Alignment.centerRight),
    _ColumnSpec(title: 'Total 1', width: 125, alignment: Alignment.centerRight),
    _ColumnSpec(title: 'Total 2', width: 125, alignment: Alignment.centerRight),
    _ColumnSpec(title: 'EXIM Jobs', width: 85, alignment: Alignment.center),
    _ColumnSpec(title: 'GST Jobs', width: 85, alignment: Alignment.center),
    _ColumnSpec(title: 'Reg Jobs', width: 85, alignment: Alignment.center),
    _ColumnSpec(title: 'CRO Jobs', width: 85, alignment: Alignment.center),
    _ColumnSpec(title: 'Mkt Jobs', width: 85, alignment: Alignment.center),
    _ColumnSpec(title: 'Acc New (₹)', width: 125, alignment: Alignment.centerRight),
    _ColumnSpec(title: 'Acc Outstanding (₹)', width: 145, alignment: Alignment.centerRight),
  ];

  static final double _totalTableWidth = _columns.fold(0.0, (sum, col) => sum + col.width);

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildTableItems();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _totalTableWidth,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  // 1. FLOATING / STICKY HEADER (Fixed at top while scrolling)
                  _buildHeaderRow(),

                  // 2. SCROLLABLE BODY (Scrolls vertically under the floating header)
                  Expanded(
                    child: Scrollbar(
                      controller: _verticalController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _verticalController,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          if (item.isDay) {
                            return _buildDayRow(item.day!);
                          } else {
                            return _buildWeekTotalRow(item.week!);
                          }
                        },
                      ),
                    ),
                  ),

                  // 3. STICKY MONTH TOTAL ROW (Fixed at bottom)
                  _buildStickyTotalRow(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<_TableItem> _buildTableItems() {
    final items = <_TableItem>[];
    int weekIdx = 0;

    for (int i = 0; i < widget.report.days.length; i++) {
      final day = widget.report.days[i];
      items.add(_TableItem.day(day));

      final isLastDay = i == widget.report.days.length - 1;
      if (day.isSunday || isLastDay) {
        if (weekIdx < widget.report.weeks.length) {
          final week = widget.report.weeks[weekIdx];
          items.add(_TableItem.week(week));
          weekIdx++;
        }
      }
    }
    return items;
  }

  Widget _buildCell({
    required Widget child,
    required double width,
    required Alignment alignment,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  }) {
    return SizedBox(
      width: width,
      child: Container(
        alignment: alignment,
        padding: padding,
        child: child,
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _columns.map((col) {
          return SizedBox(
            width: col.width,
            child: Container(
              alignment: col.alignment,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                col.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayRow(ReportDayModel day) {
    final isPending = day.isPending;
    final isSunday = day.isSunday;

    Color? rowBg;
    if (isSunday) {
      rowBg = const Color(0xFFFBF8FD); // Gentle tint for Sunday
    } else if (isPending) {
      rowBg = AppTheme.pendingWarning.withValues(alpha: 0.06);
    }

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: rowBg ?? Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Date
          _buildCell(
            width: _columns[0].width,
            alignment: _columns[0].alignment,
            child: Text(
              day.date,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isSunday
                    ? AppTheme.primary
                    : (isPending ? AppTheme.textSecondary : AppTheme.textPrimary),
              ),
            ),
          ),
          // Status
          _buildCell(
            width: _columns[1].width,
            alignment: _columns[1].alignment,
            child: isSunday
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
          // EXIM
          _buildCell(
            width: _columns[2].width,
            alignment: _columns[2].alignment,
            child: Text(
              isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['EXIM']),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // GST
          _buildCell(
            width: _columns[3].width,
            alignment: _columns[3].alignment,
            child: Text(
              isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['GST']),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Registration
          _buildCell(
            width: _columns[4].width,
            alignment: _columns[4].alignment,
            child: Text(
              isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['REGISTRATION']),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // CRO
          _buildCell(
            width: _columns[5].width,
            alignment: _columns[5].alignment,
            child: Text(
              isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['CRO']),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Accounts
          _buildCell(
            width: _columns[6].width,
            alignment: _columns[6].alignment,
            child: Text(
              isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['ACCOUNTS']),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Marketing
          _buildCell(
            width: _columns[7].width,
            alignment: _columns[7].alignment,
            child: Text(
              isPending || isSunday ? '-' : CurrencyFormatter.format(day.amounts['MARKETING']),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Total 1
          _buildCell(
            width: _columns[8].width,
            alignment: _columns[8].alignment,
            child: Text(
              isPending || isSunday ? '-' : CurrencyFormatter.format(day.total1),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
            ),
          ),
          // Total 2
          _buildCell(
            width: _columns[9].width,
            alignment: _columns[9].alignment,
            child: Text(
              isPending || isSunday ? '-' : CurrencyFormatter.format(day.total2),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 12),
            ),
          ),
          // EXIM Jobs
          _buildCell(
            width: _columns[10].width,
            alignment: _columns[10].alignment,
            child: Text(
              isPending || isSunday ? '-' : (day.jobs['EXIM'] ?? 0).toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // GST Jobs
          _buildCell(
            width: _columns[11].width,
            alignment: _columns[11].alignment,
            child: Text(
              isPending || isSunday ? '-' : (day.jobs['GST'] ?? 0).toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Reg Jobs
          _buildCell(
            width: _columns[12].width,
            alignment: _columns[12].alignment,
            child: Text(
              isPending || isSunday ? '-' : (day.jobs['REGISTRATION'] ?? 0).toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // CRO Jobs
          _buildCell(
            width: _columns[13].width,
            alignment: _columns[13].alignment,
            child: Text(
              isPending || isSunday ? '-' : (day.jobs['CRO'] ?? 0).toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Mkt Jobs
          _buildCell(
            width: _columns[14].width,
            alignment: _columns[14].alignment,
            child: Text(
              isPending || isSunday ? '-' : (day.jobs['MARKETING'] ?? 0).toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Acc New
          _buildCell(
            width: _columns[15].width,
            alignment: _columns[15].alignment,
            child: Text(
              isPending || isSunday ? '-' : CurrencyFormatter.format(day.accounts.newJobsAmount),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Acc Outstanding
          _buildCell(
            width: _columns[16].width,
            alignment: _columns[16].alignment,
            child: Text(
              isPending || isSunday ? '-' : CurrencyFormatter.format(day.accounts.outstandingJobsAmount),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTotalRow(ReportWeekModel week) {
    final totals = week.totals;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF5EEF9), // Brand lavender subtotal row
        border: Border(
          top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.25), width: 1),
          bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.25), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Week Label
          _buildCell(
            width: _columns[0].width,
            alignment: _columns[0].alignment,
            child: Text(
              week.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                fontSize: 12,
              ),
            ),
          ),
          // Status (empty)
          _buildCell(
            width: _columns[1].width,
            alignment: _columns[1].alignment,
            child: const SizedBox(),
          ),
          // EXIM
          _buildCell(
            width: _columns[2].width,
            alignment: _columns[2].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['EXIM']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // GST
          _buildCell(
            width: _columns[3].width,
            alignment: _columns[3].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['GST']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // Registration
          _buildCell(
            width: _columns[4].width,
            alignment: _columns[4].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['REGISTRATION']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // CRO
          _buildCell(
            width: _columns[5].width,
            alignment: _columns[5].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['CRO']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // Accounts
          _buildCell(
            width: _columns[6].width,
            alignment: _columns[6].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['ACCOUNTS']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // Marketing
          _buildCell(
            width: _columns[7].width,
            alignment: _columns[7].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['MARKETING']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // Total 1
          _buildCell(
            width: _columns[8].width,
            alignment: _columns[8].alignment,
            child: Text(
              CurrencyFormatter.format(totals.total1),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
            ),
          ),
          // Total 2
          _buildCell(
            width: _columns[9].width,
            alignment: _columns[9].alignment,
            child: Text(
              CurrencyFormatter.format(totals.total2),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 12),
            ),
          ),
          // EXIM Jobs
          _buildCell(
            width: _columns[10].width,
            alignment: _columns[10].alignment,
            child: Text((totals.jobs['EXIM'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // GST Jobs
          _buildCell(
            width: _columns[11].width,
            alignment: _columns[11].alignment,
            child: Text((totals.jobs['GST'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // Reg Jobs
          _buildCell(
            width: _columns[12].width,
            alignment: _columns[12].alignment,
            child: Text((totals.jobs['REGISTRATION'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // CRO Jobs
          _buildCell(
            width: _columns[13].width,
            alignment: _columns[13].alignment,
            child: Text((totals.jobs['CRO'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // Mkt Jobs
          _buildCell(
            width: _columns[14].width,
            alignment: _columns[14].alignment,
            child: Text((totals.jobs['MARKETING'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          // Acc New
          _buildCell(
            width: _columns[15].width,
            alignment: _columns[15].alignment,
            child: Text(
              CurrencyFormatter.format(totals.accounts.newJobsAmount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          // Acc Outstanding
          _buildCell(
            width: _columns[16].width,
            alignment: _columns[16].alignment,
            child: Text(
              CurrencyFormatter.format(totals.accounts.outstandingJobsAmount),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyTotalRow(BuildContext context) {
    final totals = widget.report.monthTotals;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Light slate
        border: const Border(
          top: BorderSide(color: AppTheme.primary, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Month Total Label
          _buildCell(
            width: _columns[0].width,
            alignment: _columns[0].alignment,
            child: const Text(
              'Month Total',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
            ),
          ),
          // Status (empty)
          _buildCell(
            width: _columns[1].width,
            alignment: _columns[1].alignment,
            child: const SizedBox(),
          ),
          // EXIM
          _buildCell(
            width: _columns[2].width,
            alignment: _columns[2].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['EXIM']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          // GST
          _buildCell(
            width: _columns[3].width,
            alignment: _columns[3].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['GST']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          // Registration
          _buildCell(
            width: _columns[4].width,
            alignment: _columns[4].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['REGISTRATION']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          // CRO
          _buildCell(
            width: _columns[5].width,
            alignment: _columns[5].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['CRO']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          // Accounts
          _buildCell(
            width: _columns[6].width,
            alignment: _columns[6].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['ACCOUNTS']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          // Marketing
          _buildCell(
            width: _columns[7].width,
            alignment: _columns[7].alignment,
            child: Text(CurrencyFormatter.format(totals.amounts['MARKETING']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          // Total 1
          _buildCell(
            width: _columns[8].width,
            alignment: _columns[8].alignment,
            child: Text(
              CurrencyFormatter.format(totals.total1),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
            ),
          ),
          // Total 2
          _buildCell(
            width: _columns[9].width,
            alignment: _columns[9].alignment,
            child: Text(
              CurrencyFormatter.format(totals.total2),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary, fontSize: 13),
            ),
          ),
          // EXIM Jobs
          _buildCell(
            width: _columns[10].width,
            alignment: _columns[10].alignment,
            child: Text((totals.jobs['EXIM'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          // GST Jobs
          _buildCell(
            width: _columns[11].width,
            alignment: _columns[11].alignment,
            child: Text((totals.jobs['GST'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          // Reg Jobs
          _buildCell(
            width: _columns[12].width,
            alignment: _columns[12].alignment,
            child: Text((totals.jobs['REGISTRATION'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          // CRO Jobs
          _buildCell(
            width: _columns[13].width,
            alignment: _columns[13].alignment,
            child: Text((totals.jobs['CRO'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          // Mkt Jobs
          _buildCell(
            width: _columns[14].width,
            alignment: _columns[14].alignment,
            child: Text((totals.jobs['MARKETING'] ?? 0).toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          // Acc New
          _buildCell(
            width: _columns[15].width,
            alignment: _columns[15].alignment,
            child: Text(
              CurrencyFormatter.format(totals.accounts.newJobsAmount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
          // Acc Outstanding
          _buildCell(
            width: _columns[16].width,
            alignment: _columns[16].alignment,
            child: Text(
              CurrencyFormatter.format(totals.accounts.outstandingJobsAmount),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0369A1), fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableItem {
  final ReportDayModel? day;
  final ReportWeekModel? week;

  bool get isDay => day != null;

  _TableItem.day(this.day) : week = null;
  _TableItem.week(this.week) : day = null;
}
