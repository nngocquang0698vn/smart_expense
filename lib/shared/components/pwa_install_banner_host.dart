import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_listener.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";
import "package:smart_expense/core/utils/pwa/pwa_providers.dart";
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
  void _evaluateBannerSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pwaInstallControllerProvider.notifier).evaluateBanner();
    });
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    _evaluateBannerSoon();
    listenPwaInstallAvailable(_evaluateBannerSoon);
  }

  @override
  void dispose() {
    cancelPwaInstallAvailableListener();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PwaInstallBannerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kIsWeb && widget.pageIndex == 0 && oldWidget.pageIndex != 0) {
      _evaluateBannerSoon();
    }
  }

  Future<void> _onInstallTap(BuildContext context) async {
    final notifier = ref.read(pwaInstallControllerProvider.notifier);
    final state = ref.read(pwaInstallControllerProvider);
    final canNative = ref.read(pwaInstallServiceProvider).canNativePrompt;
    if (canNative) {
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
      showNativeInstall: canNative,
      onNativeInstall: () => _onInstallTap(context),
    );
  }

  void _onShowGuide(BuildContext context) {
    final state = ref.read(pwaInstallControllerProvider);
    final canNative = ref.read(pwaInstallServiceProvider).canNativePrompt;
    PwaInstallGuideSheet.show(
      context,
      platform: state.platform,
      showNativeInstall: canNative,
      onNativeInstall: () => _onInstallTap(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

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
