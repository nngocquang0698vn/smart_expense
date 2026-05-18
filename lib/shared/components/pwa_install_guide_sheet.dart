import "package:flutter/material.dart";

import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/app_primary_button.dart";

class PwaInstallGuideSheet extends StatelessWidget {
  const PwaInstallGuideSheet({
    super.key,
    required this.platform,
    this.showNativeInstall = false,
    this.onNativeInstall,
  });

  final PwaPlatformKind platform;
  final bool showNativeInstall;
  final VoidCallback? onNativeInstall;

  static Future<void> show(
    BuildContext context, {
    required PwaPlatformKind platform,
    bool showNativeInstall = false,
    VoidCallback? onNativeInstall,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => PwaInstallGuideSheet(
        platform: platform,
        showNativeInstall: showNativeInstall,
        onNativeInstall: onNativeInstall,
      ),
    );
  }

  List<String> _steps(BuildContext context) {
    final l10n = context.l10n;
    return switch (platform) {
      PwaPlatformKind.androidChrome => [
        l10n.pwaInstallAndroidStep1,
        l10n.pwaInstallAndroidStep2,
        l10n.pwaInstallAndroidStep3,
      ],
      PwaPlatformKind.iosSafari => [
        l10n.pwaInstallIosStep1,
        l10n.pwaInstallIosStep2,
        l10n.pwaInstallIosStep3,
      ],
      PwaPlatformKind.desktopChromium => [
        l10n.pwaInstallDesktopStep1,
        l10n.pwaInstallDesktopStep2,
        l10n.pwaInstallDesktopStep3,
      ],
      _ => [
        l10n.pwaInstallAndroidStep1,
        l10n.pwaInstallAndroidStep2,
        l10n.pwaInstallAndroidStep3,
      ],
    };
  }

  IconData _leadingIcon(int index, PwaPlatformKind kind) {
    if (kind == PwaPlatformKind.iosSafari) {
      return switch (index) {
        0 => Icons.ios_share_rounded,
        1 => Icons.add_to_home_screen_rounded,
        _ => Icons.check_circle_outline_rounded,
      };
    }
    if (kind == PwaPlatformKind.desktopChromium) {
      return switch (index) {
        0 => Icons.install_desktop_rounded,
        1 => Icons.apps_rounded,
        _ => Icons.open_in_new_rounded,
      };
    }
    return switch (index) {
      0 => Icons.more_vert_rounded,
      1 => Icons.install_mobile_rounded,
      _ => Icons.check_circle_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.pwaInstallGuideTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        _leadingIcon(e.key, platform),
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "${e.key + 1}. ${e.value}",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showNativeInstall && onNativeInstall != null) ...[
              const SizedBox(height: 8),
              AppPrimaryButton(
                label: context.l10n.pwaInstallNow,
                onPressed: () {
                  Navigator.pop(context);
                  onNativeInstall!();
                },
              ),
            ],
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
            ),
          ],
        ),
      ),
    );
  }
}
