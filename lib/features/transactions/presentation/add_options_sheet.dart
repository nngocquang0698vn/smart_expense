import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "package:smart_expense/core/constants/app_constants.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/presentation/quick_entry_sheet.dart";

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
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
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
                    ctx.l10n.quickTransactionTitle,
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _OptionCard(
                icon: Icons.touch_app,
                title: ctx.l10n.quickEntryTap,
                subtitle: ctx.l10n.quickEntryTapSubtitle,
                background: cs.primary,
                foreground: cs.onPrimary,
                onTap: () => Navigator.pop(ctx, QuickEntryMode.tap),
              ),
              const SizedBox(height: 10),
              _OptionCard(
                icon: Icons.mic,
                title: ctx.l10n.record,
                subtitle: ctx.l10n.quickEntryVoiceSubtitle,
                background: cs.primaryContainer,
                foreground: cs.onPrimaryContainer,
                onTap: () => Navigator.pop(ctx, QuickEntryMode.voice),
              ),
              const SizedBox(height: 10),
              // Show receipt on all platforms; web gets gallery-only picker
              _OptionCard(
                icon: kIsWeb
                    ? Icons.photo_library_outlined
                    : Icons.photo_camera,
                title: kIsWeb
                    ? ctx.l10n.quickEntryReceiptPickTitle
                    : ctx.l10n.quickEntryReceiptCaptureTitle,
                subtitle: kIsWeb
                    ? ctx.l10n.quickEntryReceiptPickSubtitle
                    : ctx.l10n.quickEntryReceiptCaptureSubtitle,
                background: cs.primaryContainer,
                foreground: cs.onPrimaryContainer,
                onTap: () => Navigator.pop(ctx, QuickEntryMode.receipt),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarBg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.92);
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
                backgroundColor: avatarBg,
                child: Icon(icon, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.85),
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
