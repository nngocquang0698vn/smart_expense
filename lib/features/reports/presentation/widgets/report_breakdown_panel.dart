import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/reports/application/report_view_model.dart";
import "package:smart_expense/features/reports/presentation/widgets/report_category_list.dart";
import "package:smart_expense/features/reports/presentation/widgets/report_pie_chart.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Pie chart + category list with responsive layout.
class ReportBreakdownPanel extends StatelessWidget {
  const ReportBreakdownPanel({
    super.key,
    required this.slices,
    required this.sumSlice,
    required this.isIncome,
    required this.touchedIndex,
    required this.onTouchIndexChanged,
    required this.onSliceTap,
    required this.wideLayout,
    this.selectedCategoryId,
  });

  final List<ReportCategorySlice> slices;
  final int sumSlice;
  final bool isIncome;
  final int touchedIndex;
  final String? selectedCategoryId;
  final ValueChanged<int> onTouchIndexChanged;
  final void Function(int index, ReportCategorySlice slice) onSliceTap;
  final bool wideLayout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final emptyMessage = l10n.noDataForPeriod;

    if (slices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xl,
        ),
        child: AppEmptyState(
          message: emptyMessage,
          icon: Icons.bar_chart_outlined,
        ),
      );
    }

    final chart = ReportPieChart(
      slices: slices,
      sumSlice: sumSlice,
      isIncome: isIncome,
      incomeLabel: l10n.income,
      expenseLabel: l10n.expense,
      categoryNoun: l10n.categoryNoun,
      touchedIndex: touchedIndex,
      onTouchIndexChanged: onTouchIndexChanged,
    );

    final list = ReportCategoryList(
      header:
          "${l10n.reportByCategory} · ${isIncome ? l10n.income : l10n.expense}",
      slices: slices,
      isIncome: isIncome,
      touchedIndex: touchedIndex,
      selectedCategoryId: selectedCategoryId,
      onHighlightIndex: onTouchIndexChanged,
      onSliceTap: onSliceTap,
    );

    if (wideLayout) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: chart),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 6, child: list),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chart,
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: list,
        ),
      ],
    );
  }
}
