import "package:flutter/foundation.dart";

import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/features/transactions/data/date_filter.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/data/models/category_model.dart";
import "package:smart_expense/features/transactions/data/models/transaction_model.dart";
import "package:smart_expense/features/dashboard/application/dashboard_view_model.dart";

class DashboardController extends ChangeNotifier {
  DashboardController(
    this._repo, {
    DashboardHistoryPager pager = const DashboardHistoryPager(),
  }) : _pager = pager {
    _repo.addListener(refresh);
  }

  final LedgerRepository _repo;
  final DashboardHistoryPager _pager;

  DateFilterSelection filter = const DateFilterSelection(
    preset: DateFilterPreset.thisMonth,
  );
  DashboardViewModel viewModel = const DashboardViewModel.initial();

  bool _disposed = false;

  Future<void> bootstrap() {
    return Future.wait([refreshTop(), reloadHistory(reset: true)]);
  }

  Future<void> refresh() {
    return Future.wait([refreshTop(), reloadHistory(reset: true)]);
  }

  Future<void> refreshTop() async {
    viewModel = viewModel.copyWith(topLoading: true);
    _notifyIfActive();

    final results = await Future.wait([
      _repo.homeSummary(filter),
      _repo.pendingAll(filter),
      _repo.categories(),
    ]);
    if (_disposed) return;

    final summary = results[0] as Map<String, int>;
    viewModel = viewModel.copyWith(
      summary: DashboardSummaryViewModel(
        income: summary["income"] ?? 0,
        expense: summary["expense"] ?? 0,
      ),
      pending: results[1] as List<TransactionModel>,
      categories: results[2] as List<CategoryModel>,
      topLoading: false,
    );
    notifyListeners();
  }

  Future<void> reloadHistory({required bool reset}) async {
    if (reset) {
      viewModel = _pager.reset(viewModel);
      _notifyIfActive();
    }
    await loadMore();
  }

  Future<void> loadMore() async {
    if (viewModel.loadingMore || viewModel.allLoaded) return;

    viewModel = _pager.startLoading(viewModel);
    _notifyIfActive();

    final batch = await _repo.historyPage(
      filter: filter,
      offset: viewModel.historyOffset,
      limit: AppPageSizes.historyPage,
    );
    if (_disposed) return;

    viewModel = _pager.appendBatch(
      viewModel,
      batch,
      pageSize: AppPageSizes.historyPage,
    );
    notifyListeners();
  }

  Future<void> updateFilter(DateFilterSelection next) async {
    filter = next;
    await refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _repo.removeListener(refresh);
    super.dispose();
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }
}
