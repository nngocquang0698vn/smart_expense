import "package:smart_expense/core/utils/pwa/pwa_platform_detector.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";

/// Pure rules for when the PWA install banner should appear (testable without [kIsWeb]).
abstract final class PwaInstallBannerLogic {
  static bool shouldShowBanner({
    required bool isWeb,
    required bool isStandalone,
    required bool canShowFromPrefs,
    required PwaPlatformKind platform,
  }) {
    if (!isWeb) return false;
    if (isStandalone) return false;
    if (!canShowFromPrefs) return false;
    if (!PwaPlatformDetector.showsInstallBanner(platform)) return false;
    return true;
  }
}
