import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";
import "package:smart_expense/core/utils/pwa/pwa_providers.dart";
import "package:smart_expense/shared/components/pwa/pwa_android_install_sheet.dart";
import "package:smart_expense/shared/components/pwa/pwa_ios_install_guide_sheet.dart";

/// Routes install taps to native prompt or platform-specific guides.
abstract final class PwaInstallActions {
  static Future<void> requestInstall(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(pwaInstallControllerProvider.notifier);
    final state = ref.read(pwaInstallControllerProvider);
    final canNative = ref.read(pwaInstallServiceProvider).canNativePrompt;

    if (state.platform == PwaPlatformKind.iosSafari) {
      await PwaIosInstallGuideSheet.show(context);
      return;
    }

    if (state.platform == PwaPlatformKind.androidChrome ||
        state.platform == PwaPlatformKind.desktopChromium) {
      final proceed = await PwaAndroidInstallSheet.show(context);
      if (proceed != true || !context.mounted) return;
      if (canNative) {
        final result = await notifier.install();
        if (!context.mounted) return;
        if (result == PwaInstallPromptResult.accepted) {
          await notifier.onInstallAccepted();
        }
      }
      return;
    }

    await PwaAndroidInstallSheet.show(context);
  }

  static Future<void> showPostActionCtaIfNeeded(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(pwaInstallControllerProvider.notifier);
    final state = ref.read(pwaInstallControllerProvider);
    if (!state.showPostActionCta) return;

    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.pwaPostActionTitle,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pwaPostActionBody,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await requestInstall(context, ref);
                },
                child: Text(l10n.pwaInstallAction),
              ),
              TextButton(
                onPressed: () async {
                  await notifier.recordDismiss();
                  await notifier.consumePostActionCta();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(l10n.pwaInstallLater),
              ),
            ],
          ),
        ),
      ),
    );
    await notifier.consumePostActionCta();
  }
}
