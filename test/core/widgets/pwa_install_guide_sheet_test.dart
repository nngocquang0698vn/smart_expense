import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/pwa/pwa_platform_kind.dart";
import "package:smart_expense/core/strings.dart";
import "package:smart_expense/core/theme/app_theme.dart";
import "package:smart_expense/core/theme_settings.dart";
import "package:smart_expense/core/widgets/pwa_install_guide_sheet.dart";

void main() {
  testWidgets("shows iOS install steps in Vietnamese", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          const ThemeSettings(),
          brightness: Brightness.light,
        ),
        home: Scaffold(
          body: PwaInstallGuideSheet(platform: PwaPlatformKind.iosSafari),
        ),
      ),
    );

    expect(find.text(AppStrings.pwaInstallGuideTitle), findsOneWidget);
    expect(find.textContaining(AppStrings.pwaInstallIosStep1), findsOneWidget);
    expect(find.textContaining(AppStrings.pwaInstallIosStep2), findsOneWidget);
  });

  testWidgets("shows Android install steps in Vietnamese", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          const ThemeSettings(),
          brightness: Brightness.light,
        ),
        home: Scaffold(
          body: PwaInstallGuideSheet(platform: PwaPlatformKind.androidChrome),
        ),
      ),
    );

    expect(find.textContaining(AppStrings.pwaInstallAndroidStep1), findsOneWidget);
    expect(find.textContaining(AppStrings.pwaInstallAndroidStep2), findsOneWidget);
  });
}
