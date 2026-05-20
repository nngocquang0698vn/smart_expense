import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_onboarding_card.dart";

/// Chọn hero thẻ cài PWA theo nền tảng (desktop ≠ mockup điện thoại).
PwaInstallCardVariant pwaInstallCardVariantFor(PwaPlatformKind platform) {
  return switch (platform) {
    PwaPlatformKind.androidChrome => PwaInstallCardVariant.phone,
    PwaPlatformKind.desktopChromium ||
    PwaPlatformKind.otherWeb => PwaInstallCardVariant.desktop,
    _ => PwaInstallCardVariant.desktop,
  };
}
