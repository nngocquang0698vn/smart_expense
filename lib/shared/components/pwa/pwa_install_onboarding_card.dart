import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/app_primary_button.dart";
import "package:smart_expense/shared/components/app_secondary_button.dart";
import "package:smart_expense/shared/components/pwa/pwa_phone_mockup.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Soft install card — Stitch «Onboarding - Thẻ cài đặt app».
class PwaInstallOnboardingCard extends StatelessWidget {
  const PwaInstallOnboardingCard({
    super.key,
    required this.onInstall,
    required this.onLater,
  });

  final VoidCallback onInstall;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: PwaPhoneMockup()),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.pwaInstallCardTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.pwaInstallCardBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: l10n.pwaInstallAction,
            onPressed: onInstall,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppSecondaryButton(
            label: l10n.pwaInstallLater,
            onPressed: onLater,
          ),
        ],
      ),
    );
  }
}
