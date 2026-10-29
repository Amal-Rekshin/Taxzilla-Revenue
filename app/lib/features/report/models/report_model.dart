class ReportAccountsModel {
  final int ongoingJobs;
  final int newJobs;
  final int outstandingJobs;

  const ReportAccountsModel({
    required this.ongoingJobs,
    required this.newJobs,
    required this.outstandingJobs,
  });

  factory ReportAccountsModel.fromJson(Map<String, dynamic> json) {
    return ReportAccountsModel(
      ongoingJobs: (json['ongoing_jobs'] as num?)?.toInt() ?? 0,
      newJobs: (json['new_jobs'] as num?)?.toInt() ?? 0,
      outstandingJobs: (json['outstanding_jobs'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReportDayModel {
  final String date;
  final String status; // 'COMPLETE' | 'PENDING' | 'SUNDAY'
  final bool isSunday;
  final Map<String, double> amounts;
  final Map<String, int> jobs;
  final ReportAccountsModel accounts;
  final double total1;
  final double total2;

  const ReportDayModel({
    required this.date,
    required this.status,
    required this.isSunday,
    required this.amounts,
    required this.jobs,
    required this.accounts,
    required this.total1,
    required this.total2,
  });

  bool get isPending => status == 'PENDING';

  factory ReportDayModel.fromJson(Map<String, dynamic> json) {
    final rawAmounts = json['amounts'] is Map ? Map<String, dynamic>.from(json['amounts'] as Map) : <String, dynamic>{};
    final amounts = rawAmounts.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));

    final rawJobs = json['jobs'] is Map ? Map<String, dynamic>.from(json['jobs'] as Map) : <String, dynamic>{};
    final jobs = rawJobs.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));

    final rawAccounts = json['accounts'] is Map ? Map<String, dynamic>.from(json['accounts'] as Map) : <String, dynamic>{};
    final status = json['status']?.toString() ?? 'PENDING';
    final isSun = json['isSunday'] as bool? ?? (status == 'SUNDAY');

    return ReportDayModel(
      date: json['date']?.toString() ?? '',
      status: status,
      isSunday: isSun,
      amounts: amounts,
      jobs: jobs,
      accounts: ReportAccountsModel.fromJson(rawAccounts),
      total1: (json['total1'] as num?)?.toDouble() ?? 0.0,
      total2: (json['total2'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReportWeekModel {
  final int weekNumber;
  final String label;
  final String startDate;
  final String endDate;
  final int dayCount;
  final MonthTotalsModel totals;

  const ReportWeekModel({
    required this.weekNumber,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.dayCount,
    required this.totals,
  });

  factory ReportWeekModel.fromJson(Map<String, dynamic> json) {
    final rawTotals = json['totals'] is Map ? Map<String, dynamic>.from(json['totals'] as Map) : <String, dynamic>{};
    return ReportWeekModel(
      weekNumber: (json['weekNumber'] as num?)?.toInt() ?? 1,
      label: json['label']?.toString() ?? 'Week',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      dayCount: (json['dayCount'] as num?)?.toInt() ?? 0,
      totals: MonthTotalsModel.fromJson(rawTotals),
    );
  }
}

class MonthTotalsModel {
  final double total1;
  final double total2;
  final Map<String, double> amounts;
  final Map<String, int> jobs;
  final ReportAccountsModel accounts;

  const MonthTotalsModel({
    required this.total1,
    required this.total2,
    required this.amounts,
    required this.jobs,
    required this.accounts,
  });

  factory MonthTotalsModel.fromJson(Map<String, dynamic> json) {
    final rawAmounts = json['amounts'] is Map ? Map<String, dynamic>.from(json['amounts'] as Map) : <String, dynamic>{};
    final amounts = rawAmounts.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));

    final rawJobs = json['jobs'] is Map ? Map<String, dynamic>.from(json['jobs'] as Map) : <String, dynamic>{};
    final jobs = rawJobs.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));

    final rawAccounts = json['accounts'] is Map ? Map<String, dynamic>.from(json['accounts'] as Map) : <String, dynamic>{};

    return MonthTotalsModel(
      total1: (json['total1'] as num?)?.toDouble() ?? 0.0,
      total2: (json['total2'] as num?)?.toDouble() ?? 0.0,
      amounts: amounts,
      jobs: jobs,
      accounts: ReportAccountsModel.fromJson(rawAccounts),
    );
  }
}

class MonthlyReportModel {
  final String month;
  final List<ReportDayModel> days;
  final List<ReportWeekModel> weeks;
  final MonthTotalsModel monthTotals;

  const MonthlyReportModel({
    required this.month,
    required this.days,
    required this.weeks,
    required this.monthTotals,
  });

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? [];
    final rawWeeks = json['weeks'] as List<dynamic>? ?? [];
    final rawTotals = json['monthTotals'] is Map ? Map<String, dynamic>.from(json['monthTotals'] as Map) : <String, dynamic>{};

    return MonthlyReportModel(
      month: json['month']?.toString() ?? '',
      days: rawDays.map((d) => ReportDayModel.fromJson(Map<String, dynamic>.from(d as Map))).toList(),
      weeks: rawWeeks.map((w) => ReportWeekModel.fromJson(Map<String, dynamic>.from(w as Map))).toList(),
      monthTotals: MonthTotalsModel.fromJson(rawTotals),
    );
  }
}

