class ReportAccountsModel {
  final double newJobsAmount;
  final double outstandingJobsAmount;
  final int ongoingJobs;
  final int newJobs;
  final int outstandingJobs;

  const ReportAccountsModel({
    required this.newJobsAmount,
    required this.outstandingJobsAmount,
    this.ongoingJobs = 0,
    this.newJobs = 0,
    this.outstandingJobs = 0,
  });

  factory ReportAccountsModel.fromJson(Map<String, dynamic> json) {
    return ReportAccountsModel(
      newJobsAmount: (json['new_jobs_amount'] as num?)?.toDouble() ?? 0.0,
      outstandingJobsAmount: (json['outstanding_jobs_amount'] as num?)?.toDouble() ?? 0.0,
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

    return ReportDayModel(
      date: json['date'] as String,
      status: json['status'] as String,
      isSunday: json['isSunday'] as bool? ?? false,
      amounts: amounts,
      jobs: jobs,
      accounts: ReportAccountsModel.fromJson(json['accounts'] is Map ? Map<String, dynamic>.from(json['accounts'] as Map) : {}),
      total1: (json['total1'] as num?)?.toDouble() ?? 0.0,
      total2: (json['total2'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReportWeekTotals {
  final double total1;
  final double total2;
  final Map<String, double> amounts;
  final Map<String, int> jobs;
  final ReportAccountsModel accounts;

  const ReportWeekTotals({
    required this.total1,
    required this.total2,
    required this.amounts,
    required this.jobs,
    required this.accounts,
  });

  factory ReportWeekTotals.fromJson(Map<String, dynamic> json) {
    final rawAmounts = json['amounts'] is Map ? Map<String, dynamic>.from(json['amounts'] as Map) : <String, dynamic>{};
    final amounts = rawAmounts.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));

    final rawJobs = json['jobs'] is Map ? Map<String, dynamic>.from(json['jobs'] as Map) : <String, dynamic>{};
    final jobs = rawJobs.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));

    return ReportWeekTotals(
      total1: (json['total1'] as num?)?.toDouble() ?? 0.0,
      total2: (json['total2'] as num?)?.toDouble() ?? 0.0,
      amounts: amounts,
      jobs: jobs,
      accounts: ReportAccountsModel.fromJson(json['accounts'] is Map ? Map<String, dynamic>.from(json['accounts'] as Map) : {}),
    );
  }
}

class ReportWeekModel {
  final int weekNumber;
  final String label;
  final String startDate;
  final String endDate;
  final int dayCount;
  final ReportWeekTotals totals;

  const ReportWeekModel({
    required this.weekNumber,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.dayCount,
    required this.totals,
  });

  factory ReportWeekModel.fromJson(Map<String, dynamic> json) {
    return ReportWeekModel(
      weekNumber: json['weekNumber'] as int? ?? 1,
      label: json['label'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      dayCount: json['dayCount'] as int? ?? 0,
      totals: ReportWeekTotals.fromJson(json['totals'] is Map ? Map<String, dynamic>.from(json['totals'] as Map) : {}),
    );
  }
}

class MonthlyReportModel {
  final String month;
  final List<ReportDayModel> days;
  final List<ReportWeekModel> weeks;
  final ReportWeekTotals monthTotals;

  const MonthlyReportModel({
    required this.month,
    required this.days,
    required this.weeks,
    required this.monthTotals,
  });

  factory MonthlyReportModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? [];
    final days = rawDays.map((d) => ReportDayModel.fromJson(d as Map<String, dynamic>)).toList();

    final rawWeeks = json['weeks'] as List<dynamic>? ?? [];
    final weeks = rawWeeks.map((w) => ReportWeekModel.fromJson(w as Map<String, dynamic>)).toList();

    return MonthlyReportModel(
      month: json['month'] as String? ?? '',
      days: days,
      weeks: weeks,
      monthTotals: ReportWeekTotals.fromJson(json['monthTotals'] is Map ? Map<String, dynamic>.from(json['monthTotals'] as Map) : {}),
    );
  }
}
