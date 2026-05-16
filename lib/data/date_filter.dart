import "package:flutter/material.dart" show DateTimeRange;

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
  final DateTimeRange? custom;

  DateFilterSelection copyWith({
    DateFilterPreset? preset,
    DateTime? month,
    int? year,
    DateTimeRange? custom,
  }) {
    return DateFilterSelection(
      preset: preset ?? this.preset,
      month: month ?? this.month,
      year: year ?? this.year,
      custom: custom ?? this.custom,
    );
  }

  DateTimeRange resolveRange(DateTime now) {
    final startOfDay = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case DateFilterPreset.last30Days:
        final start = startOfDay.subtract(const Duration(days: 29));
        return DateTimeRange(start: start, end: now);
      case DateFilterPreset.thisWeek:
        final weekday = now.weekday;
        final start = startOfDay.subtract(Duration(days: weekday - 1));
        return DateTimeRange(start: start, end: now);
      case DateFilterPreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case DateFilterPreset.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case DateFilterPreset.allTime:
        return DateTimeRange(
          start: DateTime(1970, 1, 1),
          end: DateTime(now.year + 1, 12, 31),
        );
      case DateFilterPreset.pickMonth:
        final m = month ?? now;
        final start = DateTime(m.year, m.month, 1);
        final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case DateFilterPreset.pickYear:
        final y = year ?? now.year;
        return DateTimeRange(
          start: DateTime(y, 1, 1),
          end: DateTime(y, 12, 31, 23, 59, 59),
        );
      case DateFilterPreset.custom:
        final c = custom;
        if (c == null) {
          return DateTimeRange(start: startOfDay, end: now);
        }
        return DateTimeRange(
          start: DateTime(
            c.start.year,
            c.start.month,
            c.start.day,
          ),
          end: DateTime(
            c.end.year,
            c.end.month,
            c.end.day,
            23,
            59,
            59,
          ),
        );
    }
  }

  /// Human-readable label for the current filter selection.
  /// Pure function — no [BuildContext] needed.
  String label() {
    switch (preset) {
      case DateFilterPreset.last30Days:
        return "30 ngày vừa qua";
      case DateFilterPreset.thisWeek:
        return "Tuần này";
      case DateFilterPreset.thisMonth:
        return "Tháng này";
      case DateFilterPreset.thisYear:
        return "Năm này";
      case DateFilterPreset.allTime:
        return "Toàn bộ";
      case DateFilterPreset.pickMonth:
        final m = month ?? DateTime.now();
        return "Tháng ${m.month}/${m.year}";
      case DateFilterPreset.pickYear:
        return "Năm ${year ?? DateTime.now().year}";
      case DateFilterPreset.custom:
        return "Tuỳ chọn";
    }
  }
}

enum AnalyticsPeriod { week, month, quarter, year, custom }

extension AnalyticsPeriodX on AnalyticsPeriod {
  DateTimeRange resolve(DateTime now, {DateTimeRange? custom}) {
    switch (this) {
      case AnalyticsPeriod.week:
        final startOfDay = DateTime(now.year, now.month, now.day);
        final weekday = now.weekday;
        final start = startOfDay.subtract(Duration(days: weekday - 1));
        return DateTimeRange(start: start, end: now);
      case AnalyticsPeriod.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case AnalyticsPeriod.quarter:
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(
          start: DateTime(now.year, q, 1),
          end: now,
        );
      case AnalyticsPeriod.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case AnalyticsPeriod.custom:
        final c = custom;
        if (c == null) {
          return DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          );
        }
        return c;
    }
  }

  String get labelVi {
    switch (this) {
      case AnalyticsPeriod.week:
        return "Tuần";
      case AnalyticsPeriod.month:
        return "Tháng";
      case AnalyticsPeriod.quarter:
        return "Quý";
      case AnalyticsPeriod.year:
        return "Năm";
      case AnalyticsPeriod.custom:
        return "Tuỳ chọn";
    }
  }
}
