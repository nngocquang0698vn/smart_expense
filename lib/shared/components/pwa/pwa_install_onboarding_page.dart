import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";
import "package:smart_expense/shared/layouts/onboarding_page_layout.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_actions.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_guide_content.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_onboarding_card.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_onboarding_variant.dart";

/// Màn onboarding thứ 3 — hướng dẫn cài PWA (web).
class PwaInstallOnboardingPage extends ConsumerWidget {
  const PwaInstallOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pwaInstallControllerProvider);

    if (state.platform == PwaPlatformKind.iosSafari) {
      return const OnboardingPageLayout(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: PwaInstallGuideContent(compact: true),
      );
    }

    return OnboardingPageLayout(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: PwaInstallOnboardingCard(
        variant: pwaInstallCardVariantFor(state.platform),
        onInstall: () => PwaInstallActions.requestInstall(context, ref),
      ),
    );
  }
}
