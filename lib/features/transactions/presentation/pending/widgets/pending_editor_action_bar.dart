import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Nút lưu / xoá gọn cho panel đối soát (tránh chồng FAB +).
class PendingEditorActionBar extends StatelessWidget {
  const PendingEditorActionBar({
    super.key,
    required this.onSave,
    required this.onDelete,
  });

  final VoidCallback onSave;
  final VoidCallback onDelete;

  /// Khoảng trống phía phải để không đè FAB shell.
  static const double fabClearance = 80;

  static ButtonStyle _compactFilled(BuildContext context) {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      textStyle: Theme.of(context).textTheme.labelLarge,
    );
  }

  static ButtonStyle _compactOutlined(BuildContext context, {Color? fg}) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      foregroundColor: fg,
      textStyle: Theme.of(context).textTheme.labelLarge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finance = context.financeColors;

    return Padding(
      padding: const EdgeInsets.only(right: fabClearance),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.icon(
            style: _compactFilled(context),
            onPressed: onSave,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(l10n.saveTransaction),
          ),
          OutlinedButton.icon(
            style: _compactOutlined(context, fg: finance.dangerAction),
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, size: 18, color: finance.dangerAction),
            label: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
