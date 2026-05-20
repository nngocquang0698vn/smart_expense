import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/testing/pwa_install_test_support.dart";
import "package:smart_expense/core/testing/pwa_widget_test_helpers.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_hint.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("tapping hint opens iOS install guide on Safari", (tester) async {
    await pumpPwaWidget(
      tester,
      service: FakePwaInstallService(userAgent: kIosSafariUa),
      child: const Center(child: PwaInstallHint()),
    );

    await tester.tap(find.byType(PwaInstallHint));
    await tester.pumpAndSettle();

    expect(find.text("Cài Smart Expense trên iPhone"), findsOneWidget);
    expect(find.text("Cài Smart Expense?"), findsNothing);
  });

  testWidgets("tapping hint opens Chromium install sheet on desktop", (
    tester,
  ) async {
    await pumpPwaWidget(
      tester,
      service: FakePwaInstallService(userAgent: kDesktopChromeUa),
      child: const Center(child: PwaInstallHint()),
    );

    await tester.tap(find.byType(PwaInstallHint));
    await tester.pumpAndSettle();

    expect(find.text("Cài Smart Expense?"), findsOneWidget);
    expect(find.text("Cài Smart Expense trên iPhone"), findsNothing);
  });

  testWidgets("shows desktop install icon on desktop web", (tester) async {
    await pumpPwaWidget(
      tester,
      service: FakePwaInstallService(userAgent: kDesktopChromeUa),
      child: const Center(child: PwaInstallHint()),
    );

    expect(find.byIcon(Icons.install_desktop_rounded), findsOneWidget);
    expect(find.byIcon(Icons.install_mobile_rounded), findsNothing);
  });
}
