import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../core/constants.dart";
import "../core/strings.dart";
import "../data/models/category_model.dart";
import "../data/models/transaction_model.dart";
import "../shared/widgets/app_transaction_tile.dart";
import "../theme/app_finance_colors.dart";
import "money.dart";

class TxRow extends StatelessWidget {
  const TxRow({
    super.key,
    required this.transaction,
    required this.category,
    this.trailing,
    this.onTap,
  });

  final TransactionModel transaction;
  final CategoryModel? category;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final finance = context.financeColors;
    final t = transaction;
    final cat = category;
    final disabled = cat != null && !cat.enabled;
    final icon = disabled
        ? Icons.category_outlined
        : (cat?.icon ?? Icons.category_outlined);
    final color = disabled
        ? cs.onSurfaceVariant
        : (cat?.color ?? cs.onSurfaceVariant);
    final hasAudio = t.hasAudio;
    final hasImages = t.hasImages;

    return AppTransactionTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.16),
        child: Icon(icon, color: color, size: 22),
      ),
      title: t.title,
      subtitle: Row(
        children: [
          if (disabled)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xxs),
              child: Text(
                AppStrings.otherCategory,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: finance.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else if (cat != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xxs),
              child: Text(
                cat.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Color.lerp(finance.textMuted, color, 0.5),
                ),
              ),
            ),
          Text(
            DateFormat.MMMd("vi").format(t.occurredAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: finance.textMuted),
          ),
        ],
      ),
      supporting: hasAudio || hasImages
          ? Row(
              children: [
                if (hasAudio)
                  Icon(
                    Icons.audiotrack,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                if (hasAudio && hasImages)
                  const SizedBox(width: AppSpacing.xxs),
                if (hasImages)
                  Icon(
                    Icons.image_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
              ],
            )
          : null,
      amount: MoneyText(
        t.amountVnd,
        isIncome: t.isIncome,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: AppTypography.bold),
      ),
      trailing: trailing,
    );
  }
}

Widget buildPendingActions({
  required TransactionModel transaction,
  required VoidCallback onConfirm,
  required VoidCallback onEdit,
}) {
  final isComplete =
      transaction.amountVnd > 0 && transaction.categoryId.isNotEmpty;

  final editBtn = OutlinedButton(
    style: OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10),
    ),
    onPressed: onEdit,
    child: const Text(AppStrings.update),
  );

  if (!isComplete) return editBtn;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FilledButton.tonal(
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: onConfirm,
        child: const Text(AppStrings.confirm),
      ),
      const SizedBox(width: AppSpacing.xs),
      editBtn,
    ],
  );
}

class TxDayHeader extends StatelessWidget {
  const TxDayHeader({
    super.key,
    required this.day,
    required this.totalVnd,
    required this.count,
  });

  final DateTime day;
  final int totalVnd;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.dayHeader,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMEd("vi").format(day),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: AppTypography.bold),
          ),
          Text(
            "${formatMoneyVi(totalVnd)} · $count ${AppStrings.transactionNoun}",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class PendingCountBadge extends StatelessWidget {
  const PendingCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _Badge(
      label: "$count",
      background: cs.error,
      foreground: cs.onError,
    );
  }
}

class HistoryCountBadge extends StatelessWidget {
  const HistoryCountBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _Badge(
      label: label,
      background: Theme.of(context).colorScheme.primary,
      foreground: Theme.of(context).colorScheme.onPrimary,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -2),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: AppTypography.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
