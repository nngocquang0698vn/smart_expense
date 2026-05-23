import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/utils/formatters/money.dart";
import "package:smart_expense/features/categories/presentation/category_visuals.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/shared/components/app_finance_card.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Card tổng tiền của một hạng mục trong báo cáo chi tiết.
class CategoryReportSummaryCard extends StatelessWidget {
  const CategoryReportSummaryCard({
    super.key,
    required this.category,
    required this.totalAmountVnd,
    required this.isIncome,
  });

  final LedgerCategory category;
  final int totalAmountVnd;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppFinanceCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: category.color.withValues(alpha: 0.14),
            child: Icon(category.icon, color: category.color, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  context.l10n.reportCategoryTotalLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: MoneyText(
              totalAmountVnd,
              isIncome: isIncome,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
