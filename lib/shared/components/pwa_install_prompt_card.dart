import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/app_finance_card.dart";
import "package:smart_expense/shared/components/app_primary_button.dart";
import "package:smart_expense/shared/components/app_secondary_button.dart";

class PwaInstallPromptCard extends StatelessWidget {
  const PwaInstallPromptCard({
    super.key,
    required this.onInstallTap,
    required this.onShowGuide,
    required this.onSnooze,
    required this.onNeverShow,
  });

  final VoidCallback onInstallTap;
  final VoidCallback onShowGuide;
  final Future<void> Function() onSnooze;
  final Future<void> Function() onNeverShow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppFinanceCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.install_mobile_rounded, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.pwaInstallTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.pwaInstallSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.close,
                onPressed: () => onSnooze(),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: context.l10n.pwaInstallNow,
            onPressed: onInstallTap,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: context.l10n.pwaInstallLater,
                  onPressed: () => onSnooze(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSecondaryButton(
                  label: context.l10n.pwaInstallNever,
                  onPressed: () => onNeverShow(),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onShowGuide,
            child: Text(context.l10n.pwaInstallGuideTitle),
          ),
        ],
      ),
    );
  }
}
