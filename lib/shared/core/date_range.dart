class AppDateRange {
  const AppDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) {
    return !value.isBefore(start) && !value.isAfter(end);
  }
}
