import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";

import "package:smart_expense/features/categories/presentation/category_visuals.dart";
import "package:smart_expense/core/utils/formatters/money.dart";
import "package:smart_expense/features/reports/application/report_view_model.dart";
import "package:smart_expense/features/reports/domain/report_calculations.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
/// Donut chart for báo cáo theo hạng mục.
class ReportPieChart extends StatelessWidget {
  const ReportPieChart({
    super.key,
    required this.slices,
    required this.sumSlice,
    required this.isIncome,
    required this.incomeLabel,
    required this.expenseLabel,
    required this.categoryNoun,
    required this.touchedIndex,
    required this.onTouchIndexChanged,
  });

  final List<ReportCategorySlice> slices;
  final int sumSlice;
  final bool isIncome;
  final String incomeLabel;
  final String expenseLabel;
  final String categoryNoun;
  final int touchedIndex;
  final ValueChanged<int> onTouchIndexChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 300,
        child: RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 72,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      final idx =
                          pieTouchResponse
                              ?.touchedSection
                              ?.touchedSectionIndex ??
                          -1;
                      if (event is FlLongPressEnd ||
                          event is FlPanEndEvent ||
                          event is FlTapUpEvent) {
                        onTouchIndexChanged(-1);
                      } else if (touchedIndex != idx) {
                        onTouchIndexChanged(idx);
                      }
                    },
                  ),
                  sections: _buildSections(),
                ),
                duration: const Duration(milliseconds: 400),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: touchedIndex >= 0 && touchedIndex < slices.length
                    ? _DonutCenter(
                        key: ValueKey(touchedIndex),
                        cat: slices[touchedIndex].category,
                        pct: ReportCalculations.categoryPercent(
                          slices[touchedIndex].amount,
                          sumSlice,
                        ),
                        amount: slices[touchedIndex].amount,
                        isIncome: isIncome,
                      )
                    : _DonutCenterIdle(
                        key: const ValueKey("idle"),
                        label: isIncome ? incomeLabel : expenseLabel,
                        total: sumSlice,
                        count: slices.length,
                        isIncome: isIncome,
                        categoryNoun: categoryNoun,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    var cumPct = 0.0;
    return List.generate(slices.length, (i) {
      final pct = ReportCalculations.categoryPercent(
        slices[i].amount,
        sumSlice,
      );
      cumPct += pct;
      final isTouched = touchedIndex == i;
      final showBadge = pct >= 5 || isTouched;
      return PieChartSectionData(
        color: slices[i].category.color,
        value: ReportCalculations.chartSectionValue(slices[i].amount),
        title: "",
        radius: isTouched ? 46 : 38,
        badgeWidget: showBadge
            ? _PieBadge(
                cat: slices[i].category,
                pct: pct,
                isTouched: isTouched,
                labelAbove: cumPct - pct / 2 < 50,
              )
            : null,
        badgePositionPercentageOffset: 1.15,
      );
    });
  }
}

class _DonutCenterIdle extends StatelessWidget {
  const _DonutCenterIdle({
    super.key,
    required this.label,
    required this.total,
    required this.count,
    required this.isIncome,
    required this.categoryNoun,
  });

  final String label;
  final int total;
  final int count;
  final bool isIncome;
  final String categoryNoun;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        FittedBox(
          child: MoneyText(
            total,
            isIncome: isIncome,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          "$count $categoryNoun",
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DonutCenter extends StatelessWidget {
  const _DonutCenter({
    super.key,
    required this.cat,
    required this.pct,
    required this.amount,
    required this.isIncome,
  });

  final LedgerCategory cat;
  final double pct;
  final int amount;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: cat.color.withValues(alpha: 0.15),
          child: Icon(cat.icon, size: 14, color: cat.color),
        ),
        const SizedBox(height: 4),
        Text(
          "${pct.toStringAsFixed(0)}%",
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        FittedBox(
          child: MoneyText(
            amount,
            isIncome: isIncome,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _PieBadge extends StatelessWidget {
  const _PieBadge({
    required this.cat,
    required this.pct,
    required this.isTouched,
    required this.labelAbove,
  });

  final LedgerCategory cat;
  final double pct;
  final bool isTouched;
  final bool labelAbove;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final color = cat.color;
    final label = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "${pct.toStringAsFixed(0)}%",
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );

    return AnimatedScale(
      scale: isTouched ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (labelAbove) ...[label, const SizedBox(height: 2)],
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: color, width: 2.5),
            ),
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(cat.icon, color: color, size: 16),
              ),
            ),
          ),
          if (!labelAbove) ...[const SizedBox(height: 2), label],
        ],
      ),
    );
  }
}
