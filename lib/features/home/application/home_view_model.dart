import "../../../data/models/category_model.dart";
import "../../../data/models/transaction_model.dart";

class HomeSummaryViewModel {
  const HomeSummaryViewModel({required this.income, required this.expense});

  const HomeSummaryViewModel.empty() : income = 0, expense = 0;

  final int income;
  final int expense;
}

class HomeViewModel {
  const HomeViewModel({
    required this.summary,
    required this.pending,
    required this.categories,
    required this.history,
    required this.historyOffset,
    required this.topLoading,
    required this.loadingMore,
    required this.allLoaded,
  });

  const HomeViewModel.initial()
    : summary = const HomeSummaryViewModel.empty(),
      pending = const [],
      categories = const [],
      history = const [],
      historyOffset = 0,
      topLoading = true,
      loadingMore = false,
      allLoaded = false;

  final HomeSummaryViewModel summary;
  final List<TransactionModel> pending;
  final List<CategoryModel> categories;
  final List<TransactionModel> history;
  final int historyOffset;
  final bool topLoading;
  final bool loadingMore;
  final bool allLoaded;

  bool get initialLoading =>
      topLoading && pending.isEmpty && categories.isEmpty;

  Map<String, CategoryModel> get categoryMap => {
    for (final category in categories) category.id: category,
  };

  HomeViewModel copyWith({
    HomeSummaryViewModel? summary,
    List<TransactionModel>? pending,
    List<CategoryModel>? categories,
    List<TransactionModel>? history,
    int? historyOffset,
    bool? topLoading,
    bool? loadingMore,
    bool? allLoaded,
  }) {
    return HomeViewModel(
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

class HomeHistoryPager {
  const HomeHistoryPager();

  HomeViewModel reset(HomeViewModel viewModel) {
    return viewModel.copyWith(
      history: const [],
      historyOffset: 0,
      allLoaded: false,
    );
  }

  HomeViewModel startLoading(HomeViewModel viewModel) {
    return viewModel.copyWith(loadingMore: true);
  }

  HomeViewModel appendBatch(
    HomeViewModel viewModel,
    List<TransactionModel> batch, {
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
