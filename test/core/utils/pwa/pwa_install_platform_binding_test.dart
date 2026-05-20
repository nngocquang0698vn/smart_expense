import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/testing/pwa_install_test_support.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_controller.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";
import "package:smart_expense/core/utils/pwa/pwa_providers.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    "FakePwaInstallService iOS UA resolves to iosSafari in controller",
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          pwaInstallServiceProvider.overrideWithValue(
            FakePwaInstallService(userAgent: kIosSafariUa),
          ),
        ],
      );
      addTearDown(container.dispose);

      final platform = container.read(pwaInstallControllerProvider).platform;
      expect(platform, PwaPlatformKind.iosSafari);
    },
  );

  test("FakePwaInstallService Android UA resolves to androidChrome", () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pwaInstallServiceProvider.overrideWithValue(
          FakePwaInstallService(userAgent: kAndroidChromeUa),
        ),
      ],
    );
    addTearDown(container.dispose);

    final platform = container.read(pwaInstallControllerProvider).platform;
    expect(platform, PwaPlatformKind.androidChrome);
  });
}
