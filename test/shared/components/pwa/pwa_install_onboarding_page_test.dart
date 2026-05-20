import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/testing/pwa_install_test_support.dart";
import "package:smart_expense/core/testing/pwa_widget_test_helpers.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_guide_content.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_onboarding_page.dart";
import "package:smart_expense/shared/components/pwa/pwa_phone_mockup.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpPage(
    WidgetTester tester,
    FakePwaInstallService service,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPwaWidget(
      tester,
      service: service,
      child: const PwaInstallOnboardingPage(),
    );
  }

  testWidgets("iOS Safari shows Safari guide not phone mockup", (tester) async {
    await pumpPage(tester, FakePwaInstallService(userAgent: kIosSafariUa));
    expect(find.byType(PwaInstallGuideContent), findsOneWidget);
    expect(find.byType(PwaPhoneMockup), findsNothing);
  });

  testWidgets("desktop Chromium shows browser hero not phone mockup", (
    tester,
  ) async {
    await pumpPage(tester, FakePwaInstallService(userAgent: kDesktopChromeUa));

    expect(find.byIcon(Icons.install_desktop_rounded), findsWidgets);
    expect(find.byType(PwaPhoneMockup), findsNothing);
  });

  testWidgets("Android Chrome shows phone mockup", (tester) async {
    await pumpPage(tester, FakePwaInstallService(userAgent: kAndroidChromeUa));

    expect(find.byType(PwaPhoneMockup), findsOneWidget);
  });
}
