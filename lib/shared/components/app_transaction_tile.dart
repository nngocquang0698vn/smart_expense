import "package:flutter/material.dart";

import "package:smart_expense/shared/design_system/design_system.dart";
import "package:smart_expense/shared/components/app_finance_card.dart";

class AppTransactionTile extends StatelessWidget {
  const AppTransactionTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.trailing,
    this.onTap,
    this.footer,
  });

  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget amount;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppFinanceCard(
      margin: AppInsets.cardMargin,
      padding: AppInsets.cardPadding,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.center, child: leading),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 2),
                  subtitle,
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    footer!,
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (trailing != null) ...[
                  amount,
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: trailing!,
                    ),
                  ),
                ] else
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: amount,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
