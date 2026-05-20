import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/testing/pwa_install_test_support.dart";
import "package:smart_expense/core/testing/pwa_widget_test_helpers.dart";
import "package:smart_expense/shared/components/pwa/pwa_install_actions.dart";

class _InstallTrigger extends ConsumerWidget {
  const _InstallTrigger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => PwaInstallActions.requestInstall(context, ref),
      child: const Text("install"),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("desktop web opens Chromium sheet not iOS guide", (tester) async {
    await pumpPwaWidget(
      tester,
      service: FakePwaInstallService(userAgent: kDesktopChromeUa),
      child: const Center(child: _InstallTrigger()),
    );

    await tester.tap(find.text("install"));
    await tester.pumpAndSettle();

    expect(find.text("Cài Smart Expense?"), findsOneWidget);
    expect(find.text("Cài Smart Expense trên iPhone"), findsNothing);
  });

  testWidgets("iOS Safari opens iOS guide sheet", (tester) async {
    await pumpPwaWidget(
      tester,
      service: FakePwaInstallService(userAgent: kIosSafariUa),
      child: const Center(child: _InstallTrigger()),
    );

    await tester.tap(find.text("install"));
    await tester.pumpAndSettle();

    expect(find.text("Cài Smart Expense trên iPhone"), findsOneWidget);
    expect(find.text("Cài Smart Expense?"), findsNothing);
  });
}
