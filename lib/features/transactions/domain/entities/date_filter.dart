import "package:smart_expense/core/utils/date_range.dart";

enum DateFilterPreset {
  last30Days,
  thisWeek,
  thisMonth,
  thisYear,
  allTime,
  pickMonth,
  pickYear,
  custom,
}

class DateFilterSelection {
  const DateFilterSelection({
    required this.preset,
    this.month,
    this.year,
    this.custom,
  });

  final DateFilterPreset preset;
  final DateTime? month;
  final int? year;
  final AppDateRange? custom;

  DateFilterSelection copyWith({
    DateFilterPreset? preset,
    DateTime? month,
    int? year,
    AppDateRange? custom,
  }) {
    return DateFilterSelection(
      preset: preset ?? this.preset,
      month: month ?? this.month,
      year: year ?? this.year,
      custom: custom ?? this.custom,
    );
  }

  AppDateRange resolveRange(DateTime now) {
    final startOfDay = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case DateFilterPreset.last30Days:
        final start = startOfDay.subtract(const Duration(days: 29));
        return AppDateRange(start: start, end: now);
      case DateFilterPreset.thisWeek:
        final weekday = now.weekday;
        final start = startOfDay.subtract(Duration(days: weekday - 1));
        return AppDateRange(start: start, end: now);
      case DateFilterPreset.thisMonth:
        return AppDateRange(start: DateTime(now.year, now.month, 1), end: now);
      case DateFilterPreset.thisYear:
        return AppDateRange(start: DateTime(now.year, 1, 1), end: now);
      case DateFilterPreset.allTime:
        return AppDateRange(
          start: DateTime(1970, 1, 1),
          end: DateTime(now.year + 1, 12, 31),
        );
      case DateFilterPreset.pickMonth:
        final m = month ?? now;
        final start = DateTime(m.year, m.month, 1);
        final end = AppDateRange.endOfDay(DateTime(m.year, m.month + 1, 0));
        return AppDateRange(start: start, end: end);
      case DateFilterPreset.pickYear:
        final y = year ?? now.year;
        return AppDateRange(
          start: DateTime(y, 1, 1),
          end: AppDateRange.endOfDay(DateTime(y, 12, 31)),
        );
      case DateFilterPreset.custom:
        final c = custom;
        if (c == null) {
          return AppDateRange(start: startOfDay, end: now);
        }
        return AppDateRange.daysInclusive(start: c.start, end: c.end);
    }
  }
}

enum AnalyticsPeriod { week, month, quarter, year, custom }

extension AnalyticsPeriodX on AnalyticsPeriod {
  AppDateRange resolve(DateTime now, {AppDateRange? custom}) {
    switch (this) {
      case AnalyticsPeriod.week:
        final startOfDay = DateTime(now.year, now.month, now.day);
        final weekday = now.weekday;
        final start = startOfDay.subtract(Duration(days: weekday - 1));
        return AppDateRange(start: start, end: now);
      case AnalyticsPeriod.month:
        return AppDateRange(start: DateTime(now.year, now.month, 1), end: now);
      case AnalyticsPeriod.quarter:
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        return AppDateRange(start: DateTime(now.year, q, 1), end: now);
      case AnalyticsPeriod.year:
        return AppDateRange(start: DateTime(now.year, 1, 1), end: now);
      case AnalyticsPeriod.custom:
        final c = custom;
        if (c == null) {
          return AppDateRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          );
        }
        return AppDateRange.daysInclusive(start: c.start, end: c.end);
    }
  }
}
