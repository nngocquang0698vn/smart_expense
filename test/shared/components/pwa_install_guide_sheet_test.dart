import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";
import "package:smart_expense/app/theme/theme_settings.dart";
import "package:smart_expense/shared/components/pwa_install_guide_sheet.dart";

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

    expect(find.text(AppLocalizations.vi.pwaInstallGuideTitle), findsOneWidget);
    expect(
      find.textContaining(AppLocalizations.vi.pwaInstallIosStep1),
      findsOneWidget,
    );
    expect(
      find.textContaining(AppLocalizations.vi.pwaInstallIosStep2),
      findsOneWidget,
    );
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

    expect(
      find.textContaining(AppLocalizations.vi.pwaInstallAndroidStep1),
      findsOneWidget,
    );
    expect(
      find.textContaining(AppLocalizations.vi.pwaInstallAndroidStep2),
      findsOneWidget,
    );
  });
}
