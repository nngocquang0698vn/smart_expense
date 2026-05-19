import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";
import "package:smart_expense/shared/components/pwa_install_guide_sheet.dart";
import "package:smart_expense/shared/components/pwa_install_prompt_card.dart";

/// Shows the PWA install banner on the home tab when appropriate.
class PwaInstallBannerHost extends ConsumerStatefulWidget {
  const PwaInstallBannerHost({
    super.key,
    required this.pageIndex,
    required this.child,
  });

  final int pageIndex;
  final Widget child;

  @override
  ConsumerState<PwaInstallBannerHost> createState() =>
      _PwaInstallBannerHostState();
}

class _PwaInstallBannerHostState extends ConsumerState<PwaInstallBannerHost> {
  bool _evaluated = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pwaInstallControllerProvider.notifier).evaluateBanner();
    });
  }

  Future<void> _onInstallTap(BuildContext context) async {
    final notifier = ref.read(pwaInstallControllerProvider.notifier);
    final state = ref.read(pwaInstallControllerProvider);
    if (state.canNativeInstall) {
      final result = await notifier.install();
      if (!context.mounted) return;
      if (result == PwaInstallPromptResult.accepted) {
        await notifier.onInstallAccepted();
        return;
      }
    }
    if (!context.mounted) return;
    await PwaInstallGuideSheet.show(
      context,
      platform: state.platform,
      showNativeInstall: state.canNativeInstall,
      onNativeInstall: () => _onInstallTap(context),
    );
  }

  void _onShowGuide(BuildContext context) {
    final state = ref.read(pwaInstallControllerProvider);
    PwaInstallGuideSheet.show(
      context,
      platform: state.platform,
      showNativeInstall: state.canNativeInstall,
      onNativeInstall: () => _onInstallTap(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    if (!_evaluated) {
      _evaluated = true;
    }

    final state = ref.watch(pwaInstallControllerProvider);
    final showBanner = widget.pageIndex == 0 && state.bannerVisible;

    if (!showBanner) return widget.child;

    final notifier = ref.read(pwaInstallControllerProvider.notifier);

    return Column(
      children: [
        PwaInstallPromptCard(
          onSnooze: notifier.snooze,
          onNeverShow: notifier.neverShowAgain,
          onInstallTap: () => _onInstallTap(context),
          onShowGuide: () => _onShowGuide(context),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
