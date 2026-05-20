import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/onboarding/presentation/onboarding_nav_row.dart";

void main() {
  testWidgets("first page shows only compact next button", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingNavRow(
            showPrevious: false,
            onPrevious: () {},
            onNext: () {},
            previousLabel: "Trước",
            nextLabel: "Tiếp theo",
          ),
        ),
      ),
    );

    expect(find.text("Tiếp theo"), findsOneWidget);
    expect(find.text("Trước"), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);

    final next = tester.getSize(find.byType(FilledButton));
    expect(next.height, lessThanOrEqualTo(48));
  });

  testWidgets("later pages show previous and next on one row", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingNavRow(
            showPrevious: true,
            onPrevious: () {},
            onNext: () {},
            previousLabel: "Trước",
            nextLabel: "Tiếp theo",
          ),
        ),
      ),
    );

    expect(find.text("Trước"), findsOneWidget);
    expect(find.text("Tiếp theo"), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    final navRowBox = tester.getRect(find.byType(OnboardingNavRow));
    final prevBox = tester.getRect(find.byType(OutlinedButton));
    final nextBox = tester.getRect(find.byType(FilledButton));
    expect(prevBox.top, closeTo(nextBox.top, 2));
    expect(prevBox.bottom, closeTo(nextBox.bottom, 2));
    expect(prevBox.left, greaterThanOrEqualTo(navRowBox.left));
    expect(nextBox.right, lessThanOrEqualTo(navRowBox.right + 1));
  });

  testWidgets("last page row aligns back and start buttons", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingLastNavRow(
            onBack: () {},
            onStart: () {},
            backLabel: "Quay lại",
            startLabel: "Bắt đầu",
          ),
        ),
      ),
    );

    final navRowBox = tester.getRect(find.byType(OnboardingLastNavRow));
    final backBox = tester.getRect(find.text("Quay lại"));
    final startBox = tester.getRect(find.byType(FilledButton));
    expect(backBox.center.dy, closeTo(startBox.center.dy, 4));
    expect(backBox.top, greaterThanOrEqualTo(navRowBox.top - 1));
    expect(backBox.bottom, lessThanOrEqualTo(navRowBox.bottom + 1));
  });

  testWidgets("calls onNext when next tapped", (tester) async {
    var nextTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingNavRow(
            showPrevious: true,
            onPrevious: () {},
            onNext: () => nextTapped = true,
            previousLabel: "Trước",
            nextLabel: "Tiếp theo",
          ),
        ),
      ),
    );

    await tester.tap(find.text("Tiếp theo"));
    expect(nextTapped, isTrue);
  });
}
