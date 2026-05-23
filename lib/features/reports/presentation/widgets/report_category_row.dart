import "package:flutter/material.dart";

import "package:smart_expense/features/categories/presentation/category_visuals.dart";
import "package:smart_expense/core/utils/formatters/money.dart";
import "package:smart_expense/features/reports/application/report_view_model.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// One row in «Theo hạng mục» — icon, name, amount (no progress bar).
class ReportCategoryRow extends StatelessWidget {
  const ReportCategoryRow({
    super.key,
    required this.slice,
    required this.isIncome,
    required this.highlighted,
    required this.selected,
    required this.onTap,
  });

  final ReportCategorySlice slice;
  final bool isIncome;
  final bool highlighted;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cat = slice.category;

    final active = selected || highlighted;

    return Material(
      color: selected
          ? cat.color.withValues(alpha: 0.12)
          : highlighted
          ? cat.color.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: active
                      ? Border.all(
                          color: cat.color,
                          width: selected ? 2.5 : 2,
                        )
                      : null,
                ),
                child: Icon(cat.icon, color: cat.color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  cat.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              MoneyText(
                slice.amount,
                isIncome: isIncome,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
