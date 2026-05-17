import "package:flutter/material.dart";

import "../pwa/pwa_platform_kind.dart";
import "../strings.dart";
import "app_primary_button.dart";

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

  List<String> _steps() {
    return switch (platform) {
      PwaPlatformKind.androidChrome => [
        AppStrings.pwaInstallAndroidStep1,
        AppStrings.pwaInstallAndroidStep2,
        AppStrings.pwaInstallAndroidStep3,
      ],
      PwaPlatformKind.iosSafari => [
        AppStrings.pwaInstallIosStep1,
        AppStrings.pwaInstallIosStep2,
        AppStrings.pwaInstallIosStep3,
      ],
      PwaPlatformKind.desktopChromium => [
        AppStrings.pwaInstallDesktopStep1,
        AppStrings.pwaInstallDesktopStep2,
        AppStrings.pwaInstallDesktopStep3,
      ],
      _ => [
        AppStrings.pwaInstallAndroidStep1,
        AppStrings.pwaInstallAndroidStep2,
        AppStrings.pwaInstallAndroidStep3,
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
    final steps = _steps();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.pwaInstallGuideTitle,
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
                label: AppStrings.pwaInstallNow,
                onPressed: () {
                  Navigator.pop(context);
                  onNativeInstall!();
                },
              ),
            ],
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.close),
            ),
          ],
        ),
      ),
    );
  }
}
