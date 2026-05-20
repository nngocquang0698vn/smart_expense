import "package:flutter/material.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_guide_content.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

/// Bottom sheet hướng dẫn cài PWA (Hồ sơ / Cài đặt lại).
class PwaIosInstallGuideSheet extends StatelessWidget {
  const PwaIosInstallGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => const PwaIosInstallGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        child: PwaInstallGuideContent(
          primaryButtonLabel: l10n.pwaIosGuideDone,
          onPrimaryPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
