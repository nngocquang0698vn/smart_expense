import "package:smart_expense/core/utils/pwa/pwa_platform_detector.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";

/// Pure rules for when PWA install UI may appear on web.
abstract final class PwaInstallBannerLogic {
  static bool isEligiblePlatform({
    required bool isWeb,
    required PwaPlatformKind platform,
  }) {
    if (!isWeb) return false;
    if (!PwaPlatformDetector.showsInstallBanner(platform)) return false;
    return true;
  }

  static bool shouldShowOnboardingHint({
    required bool isWeb,
    required bool isStandalone,
    required bool isInstalled,
    required PwaPlatformKind platform,
  }) {
    if (isStandalone || isInstalled) return false;
    return isEligiblePlatform(isWeb: isWeb, platform: platform);
  }

  static bool shouldShowOnboardingCard({
    required bool isWeb,
    required bool isStandalone,
    required bool isInstalled,
    required bool canShowAutoPrompt,
    required PwaPlatformKind platform,
  }) {
    if (isStandalone || isInstalled) return false;
    if (!isEligiblePlatform(isWeb: isWeb, platform: platform)) return false;
    return canShowAutoPrompt;
  }

  static bool shouldShowPostActionCta({
    required bool isWeb,
    required bool isStandalone,
    required bool isInstalled,
    required bool canShowAutoPrompt,
    required bool alreadyShown,
    required PwaPlatformKind platform,
  }) {
    if (alreadyShown || isStandalone || isInstalled) return false;
    if (!canShowAutoPrompt) return false;
    return isEligiblePlatform(isWeb: isWeb, platform: platform);
  }
}
