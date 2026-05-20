import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/pwa/pwa_ios_install_guide_sheet.dart";

void main() {
  testWidgets("shows iOS guide with Material share and add_box icons", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale("vi", "VN"),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => PwaIosInstallGuideSheet.show(context),
                child: const Text("open"),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    expect(find.textContaining("Chia sẻ"), findsWidgets);
    expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_box_outlined), findsOneWidget);
    expect(find.text("Thêm"), findsOneWidget);
    expect(find.text("Tôi đã hiểu"), findsOneWidget);
  });
}
