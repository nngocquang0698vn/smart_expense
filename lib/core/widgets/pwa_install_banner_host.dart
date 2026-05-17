import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "../pwa/pwa_install_prompt_controller.dart";
import "../pwa/pwa_install_service.dart";
import "../pwa/pwa_scope.dart";
import "pwa_install_guide_sheet.dart";
import "pwa_install_prompt_card.dart";

/// Shows the PWA install banner on the home tab when appropriate.
class PwaInstallBannerHost extends StatefulWidget {
  const PwaInstallBannerHost({
    super.key,
    required this.pageIndex,
    required this.child,
  });

  final int pageIndex;
  final Widget child;

  @override
  State<PwaInstallBannerHost> createState() => _PwaInstallBannerHostState();
}

class _PwaInstallBannerHostState extends State<PwaInstallBannerHost> {
  PwaInstallPromptController? _controller;
  bool _evaluated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb || _evaluated) return;
    _evaluated = true;
    _controller = PwaScope.maybeOf(context);
    _controller?.addListener(_onController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller?.evaluateBanner();
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  Future<void> _onInstallTap(BuildContext context) async {
    final controller = PwaScope.of(context);
    if (controller.canNativeInstall) {
      final result = await controller.install();
      if (!context.mounted) return;
      if (result == PwaInstallPromptResult.accepted) {
        await controller.onInstallAccepted();
        return;
      }
    }
    if (!context.mounted) return;
    await PwaInstallGuideSheet.show(
      context,
      platform: controller.platform,
      showNativeInstall: controller.canNativeInstall,
      onNativeInstall: () => _onInstallTap(context),
    );
  }

  void _onShowGuide(BuildContext context) {
    final controller = PwaScope.of(context);
    PwaInstallGuideSheet.show(
      context,
      platform: controller.platform,
      showNativeInstall: controller.canNativeInstall,
      onNativeInstall: () => _onInstallTap(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;

    final controller = PwaScope.maybeOf(context);
    final showBanner =
        widget.pageIndex == 0 &&
        controller != null &&
        controller.bannerVisible;

    if (!showBanner) return widget.child;

    return Column(
      children: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (!controller.bannerVisible) return const SizedBox.shrink();
            return PwaInstallPromptCard(
              controller: controller,
              onInstallTap: () => _onInstallTap(context),
              onShowGuide: () => _onShowGuide(context),
            );
          },
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
