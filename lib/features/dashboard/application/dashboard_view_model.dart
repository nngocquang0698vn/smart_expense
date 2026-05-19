import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";

class DashboardSummaryViewModel {
  const DashboardSummaryViewModel({
    required this.income,
    required this.expense,
  });

  const DashboardSummaryViewModel.empty() : income = 0, expense = 0;

  final int income;
  final int expense;
}

class DashboardViewModel {
  const DashboardViewModel({
    required this.summary,
    required this.pending,
    required this.categories,
    required this.history,
    required this.historyOffset,
    required this.topLoading,
    required this.loadingMore,
    required this.allLoaded,
  });

  const DashboardViewModel.initial()
    : summary = const DashboardSummaryViewModel.empty(),
      pending = const [],
      categories = const [],
      history = const [],
      historyOffset = 0,
      topLoading = true,
      loadingMore = false,
      allLoaded = false;

  final DashboardSummaryViewModel summary;
  final List<LedgerTransaction> pending;
  final List<LedgerCategory> categories;
  final List<LedgerTransaction> history;
  final int historyOffset;
  final bool topLoading;
  final bool loadingMore;
  final bool allLoaded;

  bool get initialLoading =>
      topLoading && pending.isEmpty && categories.isEmpty;

  Map<String, LedgerCategory> get categoryMap => {
    for (final category in categories) category.id: category,
  };

  DashboardViewModel copyWith({
    DashboardSummaryViewModel? summary,
    List<LedgerTransaction>? pending,
    List<LedgerCategory>? categories,
    List<LedgerTransaction>? history,
    int? historyOffset,
    bool? topLoading,
    bool? loadingMore,
    bool? allLoaded,
  }) {
    return DashboardViewModel(
      summary: summary ?? this.summary,
      pending: pending ?? this.pending,
      categories: categories ?? this.categories,
      history: history ?? this.history,
      historyOffset: historyOffset ?? this.historyOffset,
      topLoading: topLoading ?? this.topLoading,
      loadingMore: loadingMore ?? this.loadingMore,
      allLoaded: allLoaded ?? this.allLoaded,
    );
  }
}

class DashboardHistoryPager {
  const DashboardHistoryPager();

  DashboardViewModel reset(DashboardViewModel viewModel) {
    return viewModel.copyWith(
      history: const [],
      historyOffset: 0,
      allLoaded: false,
    );
  }

  DashboardViewModel startLoading(DashboardViewModel viewModel) {
    return viewModel.copyWith(loadingMore: true);
  }

  DashboardViewModel appendBatch(
    DashboardViewModel viewModel,
    List<LedgerTransaction> batch, {
    required int pageSize,
  }) {
    if (batch.isEmpty) {
      return viewModel.copyWith(loadingMore: false, allLoaded: true);
    }

    final history = [...viewModel.history, ...batch];
    return viewModel.copyWith(
      history: history,
      historyOffset: viewModel.historyOffset + batch.length,
      loadingMore: false,
      allLoaded: batch.length < pageSize,
    );
  }
}
