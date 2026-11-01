import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_error.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/section_model.dart';

// Currently selected date for Daily Entry (Defaults to today in YYYY-MM-DD)
final selectedDateProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return DateFormat('yyyy-MM-dd').format(now);
});

// Currently selected slot ('AFTERNOON' or 'EVENING')
final selectedSlotProvider = StateProvider<String>((ref) => 'EVENING');

// Sections provider: loads the ordered list of 6 sections from backend
final sectionsProvider = FutureProvider<List<SectionModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/sections');
    final list = response.data as List<dynamic>;
    return list.map((item) => SectionModel.fromJson(item as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw ApiError.fromDioException(e);
  }
});

// Form state for daily entries
class EntryFormState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final List<SectionEntryInput> entries;
  final List<SectionEntryInput> initialEntries;
  final double liveTotal1;
  final double liveTotal2;
  final bool isDirty;

  const EntryFormState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.entries = const [],
    this.initialEntries = const [],
    this.liveTotal1 = 0.0,
    this.liveTotal2 = 0.0,
    this.isDirty = false,
  });

  EntryFormState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    List<SectionEntryInput>? entries,
    List<SectionEntryInput>? initialEntries,
    double? liveTotal1,
    double? liveTotal2,
    bool? isDirty,
  }) {
    return EntryFormState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      entries: entries ?? this.entries,
      initialEntries: initialEntries ?? this.initialEntries,
      liveTotal1: liveTotal1 ?? this.liveTotal1,
      liveTotal2: liveTotal2 ?? this.liveTotal2,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

class EntryFormNotifier extends StateNotifier<EntryFormState> {
  final Dio _dio;
  final List<SectionModel> _sections;

  EntryFormNotifier(this._dio, this._sections) : super(const EntryFormState()) {
    initEmptyForm();
  }

  void initEmptyForm() {
    final list = _sections.map((sec) {
      return SectionEntryInput(
        sectionId: sec.id,
        code: sec.code,
        name: sec.name,
        inCoreTotal: sec.inCoreTotal,
        countType: sec.countType,
        amount: 0.0,
        jobsCompleted: sec.isTriple ? null : 0,
        newJobsAmount: sec.isTriple ? 0.0 : null,
        outstandingJobsAmount: sec.isTriple ? 0.0 : null,
      );
    }).toList();

    state = EntryFormState(
      entries: list,
      liveTotal1: 0.0,
      liveTotal2: 0.0,
      isDirty: false,
    );
  }

  Future<void> loadEntriesForDateAndSlot(String date, String slot) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    try {
      final response = await _dio.get('/entries/$date');
      final data = response.data as Map<String, dynamic>;
      final slotKey = slot.toLowerCase();
      final rawList = (data[slotKey] ?? (slotKey == 'afternoon' ? data['morning'] : (slotKey == 'morning' ? data['afternoon'] : null))) as List<dynamic>? ?? [];

      final rawMap = <int, Map<String, dynamic>>{};
      for (final item in rawList) {
        final secId = item['section_id'] as int;
        rawMap[secId] = item as Map<String, dynamic>;
      }

      final updatedEntries = _sections.map((sec) {
        final saved = rawMap[sec.id];
        final rawAmount = saved != null && saved['amount'] != null
            ? double.tryParse(saved['amount'].toString()) ?? 0.0
            : 0.0;
        final nja = saved != null && saved['new_jobs_amount'] != null
            ? double.tryParse(saved['new_jobs_amount'].toString()) ?? 0.0
            : (sec.isTriple ? rawAmount : 0.0);
        final oja = saved != null && saved['outstanding_jobs_amount'] != null
            ? double.tryParse(saved['outstanding_jobs_amount'].toString()) ?? 0.0
            : 0.0;
        final amount = sec.isTriple ? (nja + oja) : rawAmount;

        return SectionEntryInput(
          sectionId: sec.id,
          code: sec.code,
          name: sec.name,
          inCoreTotal: sec.inCoreTotal,
          countType: sec.countType,
          amount: amount,
          jobsCompleted: sec.isTriple
              ? null
              : (saved != null ? saved['jobs_completed'] as int? ?? 0 : 0),
          newJobsAmount: sec.isTriple ? nja : null,
          outstandingJobsAmount: sec.isTriple ? oja : null,
        );
      }).toList();

      final totals = _computeTotals(updatedEntries);

      // Deep copy to store initial snapshot for diff calculation
      final initialSnapshot = updatedEntries.map((e) => SectionEntryInput(
        sectionId: e.sectionId,
        code: e.code,
        name: e.name,
        inCoreTotal: e.inCoreTotal,
        countType: e.countType,
        amount: e.amount,
        jobsCompleted: e.jobsCompleted,
        newJobsAmount: e.newJobsAmount,
        outstandingJobsAmount: e.outstandingJobsAmount,
      )).toList();

      state = state.copyWith(
        isLoading: false,
        entries: updatedEntries,
        initialEntries: initialSnapshot,
        liveTotal1: totals['total1'] ?? 0.0,
        liveTotal2: totals['total2'] ?? 0.0,
        isDirty: false,
      );
    } on DioException catch (e) {
      final err = ApiError.fromDioException(e);
      state = state.copyWith(isLoading: false, errorMessage: err.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load entries');
    }
  }

  List<Map<String, dynamic>> getChangedFields() {
    final changes = <Map<String, dynamic>>[];
    for (final current in state.entries) {
      final initial = state.initialEntries.firstWhere(
        (e) => e.sectionId == current.sectionId,
        orElse: () => current,
      );
      final fieldChanges = <String, Map<String, dynamic>>{};

      if (current.amount != initial.amount) {
        fieldChanges['Amount'] = {'old': initial.amount, 'new': current.amount};
      }
      if (current.countType == 'SINGLE') {
        if (current.jobsCompleted != initial.jobsCompleted) {
          fieldChanges['Jobs Completed'] = {
            'old': initial.jobsCompleted ?? 0,
            'new': current.jobsCompleted ?? 0,
          };
        }
      } else {
        if (current.newJobsAmount != initial.newJobsAmount) {
          fieldChanges['New Job Amount'] = {
            'old': initial.newJobsAmount ?? 0.0,
            'new': current.newJobsAmount ?? 0.0,
          };
        }
        if (current.outstandingJobsAmount != initial.outstandingJobsAmount) {
          fieldChanges['Outstanding Amount'] = {
            'old': initial.outstandingJobsAmount ?? 0.0,
            'new': current.outstandingJobsAmount ?? 0.0,
          };
        }
      }

      if (fieldChanges.isNotEmpty) {
        changes.add({
          'sectionName': current.name,
          'code': current.code,
          'changes': fieldChanges,
        });
      }
    }
    return changes;
  }

  void updateAmount(int sectionId, double newAmount) {
    final updatedList = state.entries.map((item) {
      if (item.sectionId == sectionId) {
        item.amount = newAmount;
      }
      return item;
    }).toList();

    final totals = _computeTotals(updatedList);
    state = state.copyWith(
      entries: updatedList,
      liveTotal1: totals['total1'] ?? 0.0,
      liveTotal2: totals['total2'] ?? 0.0,
      isDirty: true,
    );
  }

  void updateAccountsAmounts(int sectionId, {double? newJobsAmount, double? outstandingJobsAmount}) {
    final updatedList = state.entries.map((item) {
      if (item.sectionId == sectionId) {
        if (newJobsAmount != null) item.newJobsAmount = newJobsAmount;
        if (outstandingJobsAmount != null) item.outstandingJobsAmount = outstandingJobsAmount;
        item.amount = (item.newJobsAmount ?? 0.0) + (item.outstandingJobsAmount ?? 0.0);
      }
      return item;
    }).toList();

    final totals = _computeTotals(updatedList);
    state = state.copyWith(
      entries: updatedList,
      liveTotal1: totals['total1'] ?? 0.0,
      liveTotal2: totals['total2'] ?? 0.0,
      isDirty: true,
    );
  }

  void updateJobCount(int sectionId, {int? jobsCompleted, int? ongoing, int? newJobs, int? outstanding}) {
    final updatedList = state.entries.map((item) {
      if (item.sectionId == sectionId) {
        if (jobsCompleted != null) item.jobsCompleted = jobsCompleted;
      }
      return item;
    }).toList();

    state = state.copyWith(
      entries: updatedList,
      isDirty: true,
    );
  }

  Map<String, double> _computeTotals(List<SectionEntryInput> list) {
    double t1 = 0.0;
    double t2 = 0.0;
    for (final item in list) {
      t2 += item.amount;
      if (item.inCoreTotal) {
        t1 += item.amount;
      }
    }
    return {
      'total1': double.parse(t1.toStringAsFixed(2)),
      'total2': double.parse(t2.toStringAsFixed(2)),
    };
  }

  Future<bool> saveEntries(String date, String slot) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);

    try {
      final payload = {
        'entries': state.entries.map((e) => e.toJson()).toList(),
      };

      await _dio.put('/entries/$date/$slot', data: payload);

      state = state.copyWith(
        isSaving: false,
        isDirty: false,
        successMessage: 'Entries for $date ($slot) saved successfully.',
      );
      return true;
    } on DioException catch (e) {
      final err = ApiError.fromDioException(e);
      state = state.copyWith(isSaving: false, errorMessage: err.message);
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to save entries: $e');
      return false;
    }
  }

  void resetDirty() {
    state = state.copyWith(isDirty: false);
  }
}

// Provider for EntryFormNotifier parameterized by sections
final entryFormNotifierProvider = StateNotifierProvider<EntryFormNotifier, EntryFormState>((ref) {
  final dio = ref.watch(dioProvider);
  final sectionsAsync = ref.watch(sectionsProvider);

  final sections = sectionsAsync.value ?? [];
  return EntryFormNotifier(dio, sections);
});
