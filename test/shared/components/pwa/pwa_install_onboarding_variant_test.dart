import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_onboarding_card.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_onboarding_variant.dart";

void main() {
  test("desktop Chromium uses desktop hero not phone mockup", () {
    expect(
      pwaInstallCardVariantFor(PwaPlatformKind.desktopChromium),
      PwaInstallCardVariant.desktop,
    );
  });

  test("Android Chrome uses phone variant", () {
    expect(
      pwaInstallCardVariantFor(PwaPlatformKind.androidChrome),
      PwaInstallCardVariant.phone,
    );
  });

  test("iOS Safari maps to desktop card variant when card is shown", () {
    // iOS onboarding page uses guide content, not card — fallback still desktop.
    expect(
      pwaInstallCardVariantFor(PwaPlatformKind.iosSafari),
      PwaInstallCardVariant.desktop,
    );
  });
}
