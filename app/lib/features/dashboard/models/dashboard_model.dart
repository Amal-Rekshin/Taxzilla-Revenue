class DashboardSectionItem {
  final String code;
  final String name;
  final bool inCoreTotal;
  final String countType;
  final double amount;
  final int jobs;
  final double percentageShare;

  const DashboardSectionItem({
    required this.code,
    required this.name,
    required this.inCoreTotal,
    required this.countType,
    required this.amount,
    required this.jobs,
    required this.percentageShare,
  });

  factory DashboardSectionItem.fromJson(Map<String, dynamic> json) {
    return DashboardSectionItem(
      code: json['code'] as String,
      name: json['name'] as String,
      inCoreTotal: json['in_core_total'] as bool? ?? false,
      countType: json['count_type'] as String? ?? 'SINGLE',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      jobs: (json['jobs'] as num?)?.toInt() ?? 0,
      percentageShare: (json['percentageShare'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardAccountsModel {
  final int ongoing;
  final int newJobs;
  final int outstanding;

  const DashboardAccountsModel({
    required this.ongoing,
    required this.newJobs,
    required this.outstanding,
  });

  factory DashboardAccountsModel.fromJson(Map<String, dynamic> json) {
    return DashboardAccountsModel(
      ongoing: json['ongoing'] as int? ?? 0,
      newJobs: json['newJobs'] as int? ?? 0,
      outstanding: json['outstanding'] as int? ?? 0,
    );
  }
}

class DashboardTrendPoint {
  final String date;
  final double total1;
  final double total2;
  final String status;

  const DashboardTrendPoint({
    required this.date,
    required this.total1,
    required this.total2,
    required this.status,
  });

  factory DashboardTrendPoint.fromJson(Map<String, dynamic> json) {
    return DashboardTrendPoint(
      date: json['date'] as String,
      total1: (json['total1'] as num?)?.toDouble() ?? 0.0,
      total2: (json['total2'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}

class DashboardTodayModel {
  final String date;
  final bool morningDone;
  final bool eveningDone;

  const DashboardTodayModel({
    required this.date,
    required this.morningDone,
    required this.eveningDone,
  });

  factory DashboardTodayModel.fromJson(Map<String, dynamic> json) {
    return DashboardTodayModel(
      date: json['date'] as String,
      morningDone: json['morningDone'] as bool? ?? false,
      eveningDone: json['eveningDone'] as bool? ?? false,
    );
  }
}

class DashboardPreviousMonthModel {
  final String month;
  final double total1;
  final double total2;
  final double diffTotal1;
  final double diffTotal2;
  final double? percentageChangeTotal1;
  final double? percentageChangeTotal2;

  const DashboardPreviousMonthModel({
    required this.month,
    required this.total1,
    required this.total2,
    required this.diffTotal1,
    required this.diffTotal2,
    this.percentageChangeTotal1,
    this.percentageChangeTotal2,
  });

  factory DashboardPreviousMonthModel.fromJson(Map<String, dynamic> json) {
    return DashboardPreviousMonthModel(
      month: json['month'] as String,
      total1: (json['total1'] as num?)?.toDouble() ?? 0.0,
      total2: (json['total2'] as num?)?.toDouble() ?? 0.0,
      diffTotal1: (json['diffTotal1'] as num?)?.toDouble() ?? 0.0,
      diffTotal2: (json['diffTotal2'] as num?)?.toDouble() ?? 0.0,
      percentageChangeTotal1: (json['percentageChangeTotal1'] as num?)?.toDouble(),
      percentageChangeTotal2: (json['percentageChangeTotal2'] as num?)?.toDouble(),
    );
  }
}

class DashboardModel {
  final String month;
  final double total1;
  final double total2;
  final List<DashboardSectionItem> sectionBreakdown;
  final DashboardAccountsModel accounts;
  final List<DashboardTrendPoint> dailyTrend;
  final DashboardTodayModel today;
  final int pendingDays;
  final DashboardPreviousMonthModel previousMonth;

  const DashboardModel({
    required this.month,
    required this.total1,
    required this.total2,
    required this.sectionBreakdown,
    required this.accounts,
    required this.dailyTrend,
    required this.today,
    required this.pendingDays,
    required this.previousMonth,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? {};
    final rawSections = json['sectionBreakdown'] as List<dynamic>? ?? [];
    final rawTrend = json['dailyTrend'] as List<dynamic>? ?? [];

    return DashboardModel(
      month: json['month'] as String,
      total1: (totals['total1'] as num?)?.toDouble() ?? 0.0,
      total2: (totals['total2'] as num?)?.toDouble() ?? 0.0,
      sectionBreakdown: rawSections
          .map((s) => DashboardSectionItem.fromJson(s as Map<String, dynamic>))
          .toList(),
      accounts: DashboardAccountsModel.fromJson(
          json['accounts'] as Map<String, dynamic>? ?? {}),
      dailyTrend: rawTrend
          .map((t) => DashboardTrendPoint.fromJson(t as Map<String, dynamic>))
          .toList(),
      today: DashboardTodayModel.fromJson(
          json['today'] as Map<String, dynamic>? ?? {}),
      pendingDays: (json['pendingDays'] as num?)?.toInt() ?? 0,
      previousMonth: DashboardPreviousMonthModel.fromJson(
          json['previousMonth'] as Map<String, dynamic>? ?? {}),
    );
  }
}

