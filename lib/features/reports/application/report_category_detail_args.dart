import "package:flutter/material.dart";

import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";

/// Payload cho báo cáo chi tiết một hạng mục.
class ReportCategoryDetailArgs {
  const ReportCategoryDetailArgs({
    required this.category,
    required this.isIncomeSide,
    required this.period,
    required this.totalAmountVnd,
    this.customRange,
  });

  final LedgerCategory category;
  final bool isIncomeSide;
  final AnalyticsPeriod period;
  final DateTimeRange? customRange;

  /// Tổng từ breakdown báo cáo (khớp với hàng hạng mục).
  final int totalAmountVnd;

  String get categoryId => category.id;
  String get categoryName => category.name;

  ReportCategoryDetailArgs copyWith({
    LedgerCategory? category,
    bool? isIncomeSide,
    AnalyticsPeriod? period,
    DateTimeRange? customRange,
    int? totalAmountVnd,
  }) {
    return ReportCategoryDetailArgs(
      category: category ?? this.category,
      isIncomeSide: isIncomeSide ?? this.isIncomeSide,
      period: period ?? this.period,
      customRange: customRange ?? this.customRange,
      totalAmountVnd: totalAmountVnd ?? this.totalAmountVnd,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReportCategoryDetailArgs &&
      other.category == category &&
      other.isIncomeSide == isIncomeSide &&
      other.period == period &&
      other.customRange == customRange &&
      other.totalAmountVnd == totalAmountVnd;

  @override
  int get hashCode =>
      Object.hash(category, isIncomeSide, period, customRange, totalAmountVnd);
}
