import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_image_attachments.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";

void main() {
  testWidgets("shows camera and gallery when showCamera is true", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale("vi", "VN"),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TransactionImageAttachments(
            images: const [],
            showCamera: true,
            onPick: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    expect(find.text("Chụp ảnh"), findsOneWidget);
    expect(find.text("Chọn ảnh"), findsOneWidget);
  });

  testWidgets("shows only gallery when showCamera is false", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale("vi", "VN"),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TransactionImageAttachments(
            images: const [],
            showCamera: false,
            onPick: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    expect(find.text("Chụp ảnh"), findsNothing);
    expect(find.text("Chọn ảnh"), findsOneWidget);
  });
}
