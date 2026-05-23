import "package:flutter/material.dart";

import "package:smart_expense/features/reports/application/report_view_model.dart";
import "package:smart_expense/features/reports/presentation/widgets/report_category_row.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Danh sách «Theo hạng mục» trong báo cáo.
class ReportCategoryList extends StatelessWidget {
  const ReportCategoryList({
    super.key,
    required this.header,
    required this.slices,
    required this.isIncome,
    required this.touchedIndex,
    required this.selectedCategoryId,
    required this.onSliceTap,
    required this.onHighlightIndex,
  });

  final String header;
  final List<ReportCategorySlice> slices;
  final bool isIncome;
  final int touchedIndex;
  final String? selectedCategoryId;
  final void Function(int index, ReportCategorySlice slice) onSliceTap;
  final ValueChanged<int> onHighlightIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          header,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var i = 0; i < slices.length; i++)
          ReportCategoryRow(
            slice: slices[i],
            isIncome: isIncome,
            highlighted: touchedIndex == i,
            selected: selectedCategoryId == slices[i].id,
            onTap: () {
              onHighlightIndex(i);
              onSliceTap(i, slices[i]);
            },
          ),
      ],
    );
  }
}
