import "package:flutter/material.dart";

import "../constants.dart";
import "app_finance_card.dart";

class AppTransactionTile extends StatelessWidget {
  const AppTransactionTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.trailing,
    this.onTap,
    this.supporting,
  });

  final Widget leading;
  final String title;
  final Widget subtitle;
  final Widget amount;
  final Widget? trailing;
  final Widget? supporting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppFinanceCard(
      margin: AppInsets.cardMargin,
      padding: AppInsets.cardPadding,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle,
                if (supporting != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  supporting!,
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              amount,
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
