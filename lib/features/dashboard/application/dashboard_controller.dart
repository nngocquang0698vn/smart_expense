import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/features/dashboard/application/dashboard_view_model.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

final dashboardControllerProvider =
    AsyncNotifierProvider.autoDispose<DashboardController, DashboardState>(
      DashboardController.new,
    );

class DashboardState {
  const DashboardState({required this.filter, required this.viewModel});

  const DashboardState.initial()
    : filter = const DateFilterSelection(preset: DateFilterPreset.thisMonth),
      viewModel = const DashboardViewModel.initial();

  final DateFilterSelection filter;
  final DashboardViewModel viewModel;

  DashboardState copyWith({
    DateFilterSelection? filter,
    DashboardViewModel? viewModel,
  }) {
    return DashboardState(
      filter: filter ?? this.filter,
      viewModel: viewModel ?? this.viewModel,
    );
  }
}

class DashboardController extends AsyncNotifier<DashboardState> {
  final DashboardHistoryPager _pager = const DashboardHistoryPager();
  StreamSubscription<void>? _repoSubscription;

  LedgerRepository get _repo => ref.read(ledgerRepositoryProvider);

  @override
  Future<DashboardState> build() async {
    final initial = await _refresh(const DashboardState.initial());
    if (!ref.mounted) return initial;
    _repoSubscription?.cancel();
    _repoSubscription = _repo.changes.listen((_) => refresh());
    ref.onDispose(() => _repoSubscription?.cancel());
    return initial;
  }

  Future<void> refresh() async {
    final current = state.value ?? const DashboardState.initial();
    state = AsyncData(
      current.copyWith(viewModel: _pager.reset(current.viewModel)),
    );
    final next = await AsyncValue.guard(() => _refresh(current));
    if (ref.mounted) state = next;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null) return;
    final viewModel = current.viewModel;
    if (viewModel.loadingMore || viewModel.allLoaded) return;

    state = AsyncData(
      current.copyWith(viewModel: _pager.startLoading(viewModel)),
    );

    final batch = await _repo.historyPage(
      filter: current.filter,
      offset: viewModel.historyOffset,
      limit: AppPageSizes.historyPage,
    );
    if (!ref.mounted) return;

    final latest = state.value ?? current;
    state = AsyncData(
      latest.copyWith(
        viewModel: _pager.appendBatch(
          latest.viewModel,
          batch,
          pageSize: AppPageSizes.historyPage,
        ),
      ),
    );
  }

  Future<void> updateFilter(DateFilterSelection filter) async {
    final updated = DashboardState(
      filter: filter,
      viewModel: const DashboardViewModel.initial(),
    );
    state = AsyncData(updated);
    final next = await AsyncValue.guard(() => _refresh(updated));
    if (ref.mounted) state = next;
  }

  Future<DashboardState> _refresh(DashboardState current) async {
    final results = await Future.wait([
      _repo.homeSummary(current.filter),
      _repo.pendingAll(current.filter),
      _repo.categories(),
      _repo.historyPage(
        filter: current.filter,
        offset: 0,
        limit: AppPageSizes.historyPage,
      ),
    ]);

    final summary = results[0] as Map<String, int>;
    final base = current.viewModel.copyWith(
      summary: DashboardSummaryViewModel(
        income: summary["income"] ?? 0,
        expense: summary["expense"] ?? 0,
      ),
      pending: results[1] as List<LedgerTransaction>,
      categories: results[2] as List<LedgerCategory>,
      topLoading: false,
      history: const [],
      historyOffset: 0,
      allLoaded: false,
      loadingMore: false,
    );

    return current.copyWith(
      viewModel: _pager.appendBatch(
        base,
        results[3] as List<LedgerTransaction>,
        pageSize: AppPageSizes.historyPage,
      ),
    );
  }
}
