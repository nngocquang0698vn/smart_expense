import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";

/// A group of [LedgerTransaction]s that share the same calendar day.
class TxDayBucket {
  const TxDayBucket({required this.day, required this.items});

  /// Midnight of the shared day (no time component).
  final DateTime day;

  /// Transactions on [day], sorted newest-first within the day.
  final List<LedgerTransaction> items;
}

/// Groups [transactions] by calendar day and sorts groups newest-first.
///
/// Within each day, items are sorted by [LedgerTransaction.occurredAt]
/// descending. The returned list is safe to iterate directly for rendering.
List<TxDayBucket> groupByDay(List<LedgerTransaction> transactions) {
  final map = <DateTime, List<LedgerTransaction>>{};
  for (final t in transactions) {
    final day = DateTime(
      t.occurredAt.year,
      t.occurredAt.month,
      t.occurredAt.day,
    );
    map.putIfAbsent(day, () => []).add(t);
  }
  final days = map.keys.toList()..sort((a, b) => b.compareTo(a));
  return days.map((day) {
    return TxDayBucket(
      day: day,
      items: map[day]!..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)),
    );
  }).toList();
}
