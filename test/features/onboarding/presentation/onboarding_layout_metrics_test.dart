import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/onboarding/presentation/onboarding_layout_metrics.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";
import "package:smart_expense/shared/design_system/tokens/app_spacing.dart";

void main() {
  testWidgets("onboarding footer spacing follows design tokens", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale("vi", "VN"),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            final section = onboardingNameSectionHeight(context);
            final footer = onboardingFooterHeight(context);
            expect(kOnboardingNameFieldTopGap, AppSpacing.md);
            expect(kOnboardingNameFieldToDotsGap, AppSpacing.md);
            expect(kOnboardingDotsToButtonsGap, AppSpacing.sm);
            expect(section, greaterThan(48));
            expect(footer, greaterThan(section));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
