import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_actions.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Inline hint — tap để mở popup/sheet cài PWA.
class PwaInstallHint extends ConsumerWidget {
  const PwaInstallHint({super.key});

  static IconData _hintIcon(PwaPlatformKind platform) {
    return switch (platform) {
      PwaPlatformKind.iosSafari ||
      PwaPlatformKind.androidChrome => Icons.install_mobile_rounded,
      _ => Icons.install_desktop_rounded,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.watch(pwaInstallControllerProvider).platform;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => PwaInstallActions.requestInstall(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          margin: const EdgeInsets.only(top: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: cs.surface.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _hintIcon(platform),
                  size: 22,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.pwaInstallOnboardingHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
