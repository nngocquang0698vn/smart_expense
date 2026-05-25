class AppDateRange {
  const AppDateRange({required this.start, required this.end});

  factory AppDateRange.daysInclusive({
    required DateTime start,
    required DateTime end,
  }) {
    return AppDateRange(start: startOfDay(start), end: endOfDay(end));
  }

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) {
    return !value.isBefore(start) && !value.isAfter(end);
  }

  static DateTime startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime endOfDay(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day + 1,
    ).subtract(const Duration(microseconds: 1));
  }
}
