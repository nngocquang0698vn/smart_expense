import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/presentation/quick_entry_sheet.dart";
import "package:smart_expense/shared/design_system/tokens/app_transaction_entry_tokens.dart";

Future<void> handleAddFab(BuildContext context, LedgerRepository repo) async {
  final choice = await _showAddOptionsSheet(context);
  if (!context.mounted || choice == null) return;

  await showQuickEntrySheet(context, repo, mode: choice);
}

Future<QuickEntryMode?> _showAddOptionsSheet(BuildContext context) {
  final surface = Theme.of(context).colorScheme.surface;
  return showModalBottomSheet<QuickEntryMode>(
    context: context,
    showDragHandle: true,
    backgroundColor: surface,
    builder: (ctx) => QuickAddOptionsSheet(
      onSelected: (mode) => Navigator.pop(ctx, mode),
      onClose: () => Navigator.pop(ctx),
    ),
  );
}

/// Nội dung bottom sheet Thêm nhanh (Stitch — thẻ nền lợt).
class QuickAddOptionsSheet extends StatelessWidget {
  const QuickAddOptionsSheet({
    super.key,
    required this.onSelected,
    required this.onClose,
  });

  final ValueChanged<QuickEntryMode> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cs = Theme.of(context).colorScheme;
    final cardBg = AppTransactionEntryTokens.quickAddCard(brightness);
    final titleColor = cs.primary;
    final subtitleColor = AppTransactionEntryTokens.quickAddSubtitle(brightness);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.quickTransactionTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _OptionCard(
              icon: Icons.touch_app_rounded,
              title: context.l10n.quickEntryTap,
              subtitle: context.l10n.quickEntryTapSubtitle,
              background: cardBg,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => onSelected(QuickEntryMode.tap),
            ),
            const SizedBox(height: 10),
            _OptionCard(
              icon: Icons.mic_rounded,
              title: context.l10n.record,
              subtitle: context.l10n.quickEntryVoiceSubtitle,
              background: cardBg,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => onSelected(QuickEntryMode.voice),
            ),
            const SizedBox(height: 10),
            _OptionCard(
              icon: kIsWeb
                  ? Icons.photo_library_outlined
                  : Icons.photo_camera_outlined,
              title: kIsWeb
                  ? context.l10n.quickEntryReceiptPickTitle
                  : context.l10n.quickEntryReceiptCaptureTitle,
              subtitle: kIsWeb
                  ? context.l10n.quickEntryReceiptPickSubtitle
                  : context.l10n.quickEntryReceiptCaptureSubtitle,
              background: cardBg,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => onSelected(QuickEntryMode.receipt),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                radius: 24,
                child: Icon(icon, color: titleColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
