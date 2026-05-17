import "package:flutter/foundation.dart";

import "../../../core/constants.dart";
import "../../../data/date_filter.dart";
import "../../../data/ledger_repository.dart";
import "../../../data/models/category_model.dart";
import "../../../data/models/transaction_model.dart";
import "home_view_model.dart";

class HomeController extends ChangeNotifier {
  HomeController(
    this._repo, {
    HomeHistoryPager pager = const HomeHistoryPager(),
  }) : _pager = pager {
    _repo.addListener(refresh);
  }

  final LedgerRepository _repo;
  final HomeHistoryPager _pager;

  DateFilterSelection filter = const DateFilterSelection(
    preset: DateFilterPreset.thisMonth,
  );
  HomeViewModel viewModel = const HomeViewModel.initial();

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
      summary: HomeSummaryViewModel(
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
