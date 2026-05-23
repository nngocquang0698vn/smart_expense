import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/pwa/pwa_browser_install_hero.dart";
import "package:smart_expense/shared/components/pwa/pwa_phone_mockup.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Kiểu hero trên thẻ cài PWA onboarding.
enum PwaInstallCardVariant { phone, desktop }

/// Thẻ gợi ý cài PWA trên onboarding (gọn, không trùng nút Tiếp theo / Để sau).
class PwaInstallOnboardingCard extends StatelessWidget {
  const PwaInstallOnboardingCard({
    super.key,
    required this.onInstall,
    this.variant = PwaInstallCardVariant.phone,
  });

  final VoidCallback onInstall;
  final PwaInstallCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final isDesktop = variant == PwaInstallCardVariant.desktop;
    final installIcon = isDesktop
        ? Icons.install_desktop_rounded
        : Icons.install_mobile_rounded;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: isDesktop
                ? const PwaBrowserInstallHero()
                : const PwaPhoneMockup(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.pwaInstallCardTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          PwaInstallBenefitRow(
            icon: Icons.bolt_rounded,
            label: l10n.pwaInstallBenefitNative,
          ),
          const SizedBox(height: AppSpacing.sm),
          PwaInstallBenefitRow(
            icon: Icons.wifi_off_rounded,
            label: l10n.pwaInstallBenefitOffline,
          ),
          const SizedBox(height: AppSpacing.sm),
          PwaInstallBenefitRow(
            icon: Icons.notifications_active_outlined,
            label: l10n.pwaInstallBenefitNotify,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.center,
            child: FilledButton.icon(
              onPressed: onInstall,
              icon: Icon(installIcon, size: 18),
              label: Text(l10n.pwaInstallAction),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
