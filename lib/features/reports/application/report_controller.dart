import "dart:async";

import "package:flutter/material.dart" show DateTimeRange;
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/utils/date_range.dart";
import "package:smart_expense/features/reports/application/report_category_detail_args.dart";
import "package:smart_expense/features/reports/application/report_view_model.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

final reportControllerProvider =
    AsyncNotifierProvider.autoDispose<ReportController, ReportState>(
      ReportController.new,
    );

class ReportState {
  const ReportState({
    required this.period,
    required this.customRange,
    required this.incomeSide,
    required this.viewModel,
    required this.loading,
    this.selectedCategoryId,
  });

  const ReportState.initial()
    : period = AnalyticsPeriod.month,
      customRange = null,
      incomeSide = false,
      viewModel = const ReportViewModel.empty(),
      loading = true,
      selectedCategoryId = null;

  final AnalyticsPeriod period;
  final DateTimeRange? customRange;
  final bool incomeSide;
  final ReportViewModel viewModel;
  final bool loading;

  /// Hạng mục đang mở ở panel chi tiết (desktop master-detail).
  final String? selectedCategoryId;

  ReportState copyWith({
    AnalyticsPeriod? period,
    Object? customRange = _unset,
    bool? incomeSide,
    ReportViewModel? viewModel,
    bool? loading,
    Object? selectedCategoryId = _unset,
  }) {
    return ReportState(
      period: period ?? this.period,
      customRange: customRange == _unset
          ? this.customRange
          : customRange as DateTimeRange?,
      incomeSide: incomeSide ?? this.incomeSide,
      viewModel: viewModel ?? this.viewModel,
      loading: loading ?? this.loading,
      selectedCategoryId: selectedCategoryId == _unset
          ? this.selectedCategoryId
          : selectedCategoryId as String?,
    );
  }

  ReportCategoryDetailArgs? detailArgsForSelectedSlice() {
    final id = selectedCategoryId;
    if (id == null) return null;
    for (final slice in viewModel.slices) {
      if (slice.id == id) {
        return ReportCategoryDetailArgs(
          category: slice.category,
          isIncomeSide: incomeSide,
          period: period,
          customRange: customRange,
          totalAmountVnd: slice.amount,
        );
      }
    }
    return null;
  }

  static const _unset = Object();
}

class ReportController extends AsyncNotifier<ReportState> {
  final ReportViewModelBuilder _builder = const ReportViewModelBuilder();
  StreamSubscription<void>? _repoSubscription;

  LedgerRepository get _repo => ref.read(ledgerRepositoryProvider);

  @override
  Future<ReportState> build() async {
    final initial = await _load(const ReportState.initial());
    if (!ref.mounted) return initial;
    _repoSubscription?.cancel();
    _repoSubscription = _repo.changes.listen((_) => reload());
    ref.onDispose(() => _repoSubscription?.cancel());
    return initial;
  }

  Future<void> reload() async {
    final current = state.value ?? const ReportState.initial();
    state = AsyncData(current.copyWith(loading: true));
    final next = await AsyncValue.guard(() => _load(current));
    if (ref.mounted) state = next;
  }

  Future<void> selectPeriod(AnalyticsPeriod period) async {
    final current = state.value ?? const ReportState.initial();
    final updated = current.copyWith(
      period: period,
      customRange: null,
      loading: true,
    );
    state = AsyncData(updated);
    final next = await AsyncValue.guard(() => _load(updated));
    if (ref.mounted) state = next;
  }

  Future<void> selectCustomRange(DateTimeRange range) async {
    final current = state.value ?? const ReportState.initial();
    final updated = current.copyWith(
      period: AnalyticsPeriod.custom,
      customRange: range,
      loading: true,
    );
    state = AsyncData(updated);
    final next = await AsyncValue.guard(() => _load(updated));
    if (ref.mounted) state = next;
  }

  Future<void> selectIncomeSide(bool incomeSide) async {
    final current = state.value ?? const ReportState.initial();
    if (current.incomeSide == incomeSide) return;
    final updated = current.copyWith(
      incomeSide: incomeSide,
      loading: true,
      selectedCategoryId: null,
    );
    state = AsyncData(updated);
    final next = await AsyncValue.guard(() => _load(updated));
    if (ref.mounted) state = next;
  }

  void selectCategory(String? categoryId) {
    final current = state.value;
    if (current == null) return;
    if (current.selectedCategoryId == categoryId) return;
    state = AsyncData(current.copyWith(selectedCategoryId: categoryId));
  }

  void clearSelectedCategory() => selectCategory(null);

  Future<ReportState> _load(ReportState current) async {
    final results = await Future.wait([
      _repo.analyticsTotals(
        period: current.period,
        custom: current.customRange?.toAppDateRange(),
      ),
      _repo.categoryBreakdown(
        period: current.period,
        incomeSide: current.incomeSide,
        custom: current.customRange?.toAppDateRange(),
      ),
      _repo.categories(),
    ]);

    final viewModel = _builder.build(
      totals: results[0] as Map<String, int>,
      breakdown: results[1] as Map<String, int>,
      categories: results[2] as List<LedgerCategory>,
    );
    final selectedId = current.selectedCategoryId;
    final keepSelection =
        selectedId != null &&
        viewModel.slices.any((slice) => slice.id == selectedId);

    return current.copyWith(
      viewModel: viewModel,
      loading: false,
      selectedCategoryId: keepSelection ? selectedId : null,
    );
  }
}

extension on DateTimeRange {
  AppDateRange toAppDateRange() =>
      AppDateRange.daysInclusive(start: start, end: end);
}
