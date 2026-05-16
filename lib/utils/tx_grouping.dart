import "../data/models/transaction_model.dart";

/// A group of [TransactionModel]s that share the same calendar day.
class TxDayBucket {
  const TxDayBucket({required this.day, required this.items});

  /// Midnight of the shared day (no time component).
  final DateTime day;

  /// Transactions on [day], sorted newest-first within the day.
  final List<TransactionModel> items;
}

/// Groups [transactions] by calendar day and sorts groups newest-first.
///
/// Within each day, items are sorted by [TransactionModel.occurredAt]
/// descending. The returned list is safe to iterate directly for rendering.
List<TxDayBucket> groupByDay(List<TransactionModel> transactions) {
  final map = <DateTime, List<TransactionModel>>{};
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
