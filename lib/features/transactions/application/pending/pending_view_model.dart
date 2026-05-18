import "package:smart_expense/features/transactions/data/models/category_model.dart";
import "package:smart_expense/features/transactions/data/models/transaction_model.dart";

class PendingViewModel {
  const PendingViewModel({
    required this.transactions,
    required this.categories,
    required this.loading,
  });

  const PendingViewModel.initial()
    : transactions = const [],
      categories = const [],
      loading = true;

  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  final bool loading;

  bool get isEmpty => transactions.isEmpty;

  Map<String, CategoryModel> get categoryMap => {
    for (final category in categories) category.id: category,
  };

  PendingViewModel copyWith({
    List<TransactionModel>? transactions,
    List<CategoryModel>? categories,
    bool? loading,
  }) {
    return PendingViewModel(
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      loading: loading ?? this.loading,
    );
  }
}
