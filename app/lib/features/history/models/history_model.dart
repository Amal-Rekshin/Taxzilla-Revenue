class HistoryDayItem {
  final String date;
  final bool morningDone;
  final bool eveningDone;
  final double total1;
  final double total2;
  final bool isPending;
  final bool isSunday;
  final bool isEdited;
  final String? lastUpdatedBy;
  final String? lastUpdatedAt;

  const HistoryDayItem({
    required this.date,
    required this.morningDone,
    required this.eveningDone,
    required this.total1,
    required this.total2,
    required this.isPending,
    required this.isSunday,
    required this.isEdited,
    this.lastUpdatedBy,
    this.lastUpdatedAt,
  });

  factory HistoryDayItem.fromJson(Map<String, dynamic> json) {
    return HistoryDayItem(
      date: json['date']?.toString() ?? '',
      morningDone: json['afternoonDone'] as bool? ?? (json['morningDone'] as bool? ?? false),
      eveningDone: json['eveningDone'] as bool? ?? false,
      total1: (json['total1'] as num?)?.toDouble() ?? 0.0,
      total2: (json['total2'] as num?)?.toDouble() ?? 0.0,
      isPending: json['isPending'] as bool? ?? false,
      isSunday: json['isSunday'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      lastUpdatedBy: json['lastUpdatedBy']?.toString(),
      lastUpdatedAt: json['lastUpdatedAt']?.toString(),
    );
  }
}

class HistoryAuditItem {
  final int id;
  final String entryDate;
  final int sectionId;
  final String sectionCode;
  final String sectionName;
  final String slot;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic> newValues;
  final String? changedByUsername;
  final String changedAt;

  const HistoryAuditItem({
    required this.id,
    required this.entryDate,
    required this.sectionId,
    required this.sectionCode,
    required this.sectionName,
    required this.slot,
    this.oldValues,
    required this.newValues,
    this.changedByUsername,
    required this.changedAt,
  });

  factory HistoryAuditItem.fromJson(Map<String, dynamic> json) {
    return HistoryAuditItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      entryDate: json['entry_date']?.toString() ?? '',
      sectionId: int.tryParse(json['section_id']?.toString() ?? '0') ?? 0,
      sectionCode: json['section_code']?.toString() ?? '',
      sectionName: json['section_name']?.toString() ?? '',
      slot: json['slot']?.toString() ?? '',
      oldValues: json['old_values'] is Map
          ? Map<String, dynamic>.from(json['old_values'] as Map)
          : null,
      newValues: json['new_values'] is Map
          ? Map<String, dynamic>.from(json['new_values'] as Map)
          : {},
      changedByUsername: json['changed_by_username']?.toString(),
      changedAt: json['changed_at']?.toString() ?? '',
    );
  }
}

class DayDetailSectionItem {
  final int sectionId;
  final String code;
  final String name;
  final bool inCoreTotal;
  final String countType;
  final double amount;
  final int? jobsCompleted;
  final int? ongoingJobs;
  final int? newJobs;
  final int? outstandingJobs;
  final bool isEntered;

  const DayDetailSectionItem({
    required this.sectionId,
    required this.code,
    required this.name,
    required this.inCoreTotal,
    required this.countType,
    required this.amount,
    this.jobsCompleted,
    this.ongoingJobs,
    this.newJobs,
    this.outstandingJobs,
    required this.isEntered,
  });

  factory DayDetailSectionItem.fromJson(Map<String, dynamic> json) {
    return DayDetailSectionItem(
      sectionId: int.tryParse(json['section_id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      inCoreTotal: json['in_core_total'] as bool? ?? false,
      countType: json['count_type']?.toString() ?? 'SINGLE',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      jobsCompleted: int.tryParse(json['jobs_completed']?.toString() ?? ''),
      ongoingJobs: int.tryParse(json['ongoing_jobs']?.toString() ?? ''),
      newJobs: int.tryParse(json['new_jobs']?.toString() ?? ''),
      outstandingJobs: int.tryParse(json['outstanding_jobs']?.toString() ?? ''),
      isEntered: json['is_entered'] as bool? ?? false,
    );
  }
}

class DayDetailModel {
  final String date;
  final List<DayDetailSectionItem> morning;
  final List<DayDetailSectionItem> evening;

  const DayDetailModel({
    required this.date,
    required this.morning,
    required this.evening,
  });

  factory DayDetailModel.fromJson(Map<String, dynamic> json) {
    final rawMorning = (json['afternoon'] ?? json['morning']) as List<dynamic>? ?? [];
    final rawEvening = json['evening'] as List<dynamic>? ?? [];

    return DayDetailModel(
      date: json['date']?.toString() ?? '',
      morning: rawMorning
          .map((m) => DayDetailSectionItem.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
      evening: rawEvening
          .map((e) => DayDetailSectionItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
