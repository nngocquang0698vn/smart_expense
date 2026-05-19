import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";

/// Immutable PWA install prompt state for Riverpod.
class PwaInstallState {
  const PwaInstallState({
    required this.platform,
    this.bannerVisible = false,
    required this.canNativeInstall,
    required this.isStandalone,
  });

  final PwaPlatformKind platform;
  final bool bannerVisible;
  final bool canNativeInstall;
  final bool isStandalone;

  PwaInstallState copyWith({
    PwaPlatformKind? platform,
    bool? bannerVisible,
    bool? canNativeInstall,
    bool? isStandalone,
  }) {
    return PwaInstallState(
      platform: platform ?? this.platform,
      bannerVisible: bannerVisible ?? this.bannerVisible,
      canNativeInstall: canNativeInstall ?? this.canNativeInstall,
      isStandalone: isStandalone ?? this.isStandalone,
    );
  }
}
