import "package:flutter/material.dart";

import "../pwa/pwa_install_prompt_controller.dart";
import "../strings.dart";
import "app_finance_card.dart";
import "app_primary_button.dart";
import "app_secondary_button.dart";

class PwaInstallPromptCard extends StatelessWidget {
  const PwaInstallPromptCard({
    super.key,
    required this.controller,
    required this.onInstallTap,
    required this.onShowGuide,
  });

  final PwaInstallPromptController controller;
  final VoidCallback onInstallTap;
  final VoidCallback onShowGuide;

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
                      AppStrings.pwaInstallTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.pwaInstallSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.close,
                onPressed: () => controller.snooze(),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: AppStrings.pwaInstallNow,
            onPressed: onInstallTap,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: AppStrings.pwaInstallLater,
                  onPressed: () => controller.snooze(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSecondaryButton(
                  label: AppStrings.pwaInstallNever,
                  onPressed: () => controller.neverShowAgain(),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onShowGuide,
            child: const Text(AppStrings.pwaInstallGuideTitle),
          ),
        ],
      ),
    );
  }
}
