import "../../../../shared/core/date_range.dart";
import "../entities/finance_totals.dart";
import "../entities/ledger_transaction.dart";

class LedgerQueryService {
  const LedgerQueryService();

  FinanceTotals confirmedTotals(
    Iterable<LedgerTransaction> transactions,
    AppDateRange range,
  ) {
    var income = 0;
    var expense = 0;

    for (final transaction in _confirmedInRange(transactions, range)) {
      if (transaction.isIncome) {
        income += transaction.amountVnd;
      } else {
        expense += transaction.amountVnd;
      }
    }

    return FinanceTotals(income: income, expense: expense);
  }

  List<LedgerTransaction> pendingInRange(
    Iterable<LedgerTransaction> transactions,
    AppDateRange range, {
    int? limit,
  }) {
    final pending = _inRange(
      transactions,
      range,
    ).where((transaction) => transaction.pending).toList();
    _sortNewestFirst(pending);
    return limit == null ? pending : pending.take(limit).toList();
  }

  List<LedgerTransaction> confirmedHistoryPage(
    Iterable<LedgerTransaction> transactions,
    AppDateRange range, {
    required int offset,
    required int limit,
  }) {
    final confirmed = _confirmedInRange(transactions, range).toList();
    _sortNewestFirst(confirmed);
    if (offset >= confirmed.length) return const [];
    return confirmed.sublist(
      offset,
      (offset + limit).clamp(0, confirmed.length),
    );
  }

  Map<String, int> categoryBreakdown(
    Iterable<LedgerTransaction> transactions,
    AppDateRange range, {
    required bool incomeSide,
  }) {
    final result = <String, int>{};
    for (final transaction in _confirmedInRange(
      transactions,
      range,
    ).where((transaction) => transaction.isIncome == incomeSide)) {
      result[transaction.categoryId] =
          (result[transaction.categoryId] ?? 0) + transaction.amountVnd;
    }
    return result;
  }

  List<LedgerTransaction> transactionsForCategory(
    Iterable<LedgerTransaction> transactions,
    AppDateRange range, {
    required String categoryId,
  }) {
    final result = _confirmedInRange(
      transactions,
      range,
    ).where((transaction) => transaction.categoryId == categoryId).toList();
    _sortNewestFirst(result);
    return result;
  }

  Iterable<LedgerTransaction> _inRange(
    Iterable<LedgerTransaction> transactions,
    AppDateRange range,
  ) {
    return transactions.where(
      (transaction) => range.contains(transaction.occurredAt),
    );
  }

  Iterable<LedgerTransaction> _confirmedInRange(
    Iterable<LedgerTransaction> transactions,
    AppDateRange range,
  ) {
    return _inRange(
      transactions,
      range,
    ).where((transaction) => !transaction.pending);
  }

  void _sortNewestFirst(List<LedgerTransaction> transactions) {
    transactions.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }
}
