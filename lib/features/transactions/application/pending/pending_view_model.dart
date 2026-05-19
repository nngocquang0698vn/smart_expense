import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";

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

  final List<LedgerTransaction> transactions;
  final List<LedgerCategory> categories;
  final bool loading;

  bool get isEmpty => transactions.isEmpty;

  Map<String, LedgerCategory> get categoryMap => {
    for (final category in categories) category.id: category,
  };

  PendingViewModel copyWith({
    List<LedgerTransaction>? transactions,
    List<LedgerCategory>? categories,
    bool? loading,
  }) {
    return PendingViewModel(
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      loading: loading ?? this.loading,
    );
  }
}
