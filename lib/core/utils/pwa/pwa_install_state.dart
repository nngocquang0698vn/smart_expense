import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";

/// Immutable PWA install state for Riverpod.
class PwaInstallState {
  const PwaInstallState({
    required this.platform,
    required this.canNativeInstall,
    required this.isStandalone,
    required this.isInstalled,
    required this.canShowAutoPrompt,
    required this.dismissCount,
    this.showPostActionCta = false,
  });

  final PwaPlatformKind platform;
  final bool canNativeInstall;
  final bool isStandalone;
  final bool isInstalled;
  final bool canShowAutoPrompt;
  final int dismissCount;
  final bool showPostActionCta;

  bool get isInstalledMode => isStandalone || isInstalled;

  PwaInstallState copyWith({
    PwaPlatformKind? platform,
    bool? canNativeInstall,
    bool? isStandalone,
    bool? isInstalled,
    bool? canShowAutoPrompt,
    int? dismissCount,
    bool? showPostActionCta,
  }) {
    return PwaInstallState(
      platform: platform ?? this.platform,
      canNativeInstall: canNativeInstall ?? this.canNativeInstall,
      isStandalone: isStandalone ?? this.isStandalone,
      isInstalled: isInstalled ?? this.isInstalled,
      canShowAutoPrompt: canShowAutoPrompt ?? this.canShowAutoPrompt,
      dismissCount: dismissCount ?? this.dismissCount,
      showPostActionCta: showPostActionCta ?? this.showPostActionCta,
    );
  }
}
