class SectionModel {
  final int id;
  final String code;
  final String name;
  final bool inCoreTotal;
  final String countType; // 'SINGLE' | 'TRIPLE'
  final int sortOrder;

  const SectionModel({
    required this.id,
    required this.code,
    required this.name,
    required this.inCoreTotal,
    required this.countType,
    required this.sortOrder,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      inCoreTotal: json['in_core_total'] as bool? ?? false,
      countType: json['count_type'] as String? ?? 'SINGLE',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  bool get isTriple => countType == 'TRIPLE' || code == 'ACCOUNTS';
}

class SectionEntryInput {
  final int sectionId;
  final String code;
  final String name;
  final bool inCoreTotal;
  final String countType;
  double amount;
  int? jobsCompleted;
  double? newJobsAmount;
  double? outstandingJobsAmount;
  int? ongoingJobs;
  int? newJobs;
  int? outstandingJobs;

  bool get isTriple => countType == 'TRIPLE' || code == 'ACCOUNTS';

  SectionEntryInput({
    required this.sectionId,
    required this.code,
    required this.name,
    required this.inCoreTotal,
    required this.countType,
    this.amount = 0.0,
    this.jobsCompleted,
    this.newJobsAmount,
    this.outstandingJobsAmount,
    this.ongoingJobs,
    this.newJobs,
    this.outstandingJobs,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'section_id': sectionId,
      'amount': amount,
    };

    if (countType == 'SINGLE') {
      map['jobs_completed'] = jobsCompleted ?? 0;
    } else if (countType == 'TRIPLE' || code == 'ACCOUNTS') {
      map['new_jobs_amount'] = newJobsAmount ?? 0.0;
      map['outstanding_jobs_amount'] = outstandingJobsAmount ?? 0.0;
    }

    return map;
  }
}
