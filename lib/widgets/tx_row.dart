import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../core/constants.dart";
import "../core/strings.dart";
import "../data/models/category_model.dart";
import "../data/models/transaction_model.dart";
import "money.dart";

/// A single transaction card used in the home, pending, and any future list.
///
/// Handles disabled-category display ("Khác"), shows media attachment icons,
/// and renders an optional [trailing] widget (e.g. confirm/edit buttons).
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

  /// Optional widget rendered below the amount on the right side.
  /// Typically action buttons for pending transactions.
  final Widget? trailing;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final cat = category;

    // A disabled category falls back to a neutral "Khác" appearance.
    final disabled = cat != null && !cat.enabled;
    final icon = disabled
        ? Icons.category_outlined
        : (cat?.icon ?? Icons.category_outlined);
    final color = disabled ? Colors.grey : (cat?.color ?? Colors.grey);

    final hasAudio = (t.audioBase64 ?? "").isNotEmpty;
    final hasImages = t.imageBase64List.isNotEmpty;

    return Card(
      margin: AppInsets.cardMargin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: AppInsets.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),

              // Title + subtitle (category name · date + media icons)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Row(
                      children: [
                        if (disabled)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              AppStrings.otherCategory,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          )
                        else if (cat != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              cat.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: color.withValues(alpha: 0.8),
                                  ),
                            ),
                          ),
                        Text(
                          DateFormat.MMMd("vi").format(t.occurredAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (hasAudio || hasImages) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (hasAudio)
                            Icon(
                              Icons.audiotrack,
                              size: 14,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          if (hasAudio && hasImages) const SizedBox(width: 4),
                          if (hasImages)
                            Icon(
                              Icons.image_outlined,
                              size: 14,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Amount + optional action buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    t.amountVnd,
                    isIncome: t.isIncome,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (trailing != null) ...[
                    const SizedBox(height: 6),
                    trailing!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns the compact action buttons for a pending transaction row.
///
/// Shows both "Xác nhận" + "Cập nhật" when the transaction is complete
/// (amount > 0 and category set); otherwise shows only "Cập nhật".
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
      const SizedBox(width: 6),
      editBtn,
    ],
  );
}

/// Day-group header displayed above a cluster of same-day transactions.
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
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            "${formatMoneyVi(totalVnd)} · $count giao dịch",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Red superscript pill badge — used beside "Chờ đối soát".
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

/// Green superscript pill badge — used beside "Lịch sử giao dịch".
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

/// Internal pill badge. Floats 2 px upward to act as a superscript.
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
        ),
      ),
    );
  }
}
