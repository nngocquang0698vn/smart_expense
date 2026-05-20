import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/shared/layouts/onboarding_page_layout.dart";

void main() {
  const padding = EdgeInsets.symmetric(horizontal: 8, vertical: 16);
  const viewportHeight = 500.0;
  const expectedMinHeight = 468.0; // viewport - vertical padding (16 * 2)

  testWidgets("centers child vertically using minHeight minus padding", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: viewportHeight,
            child: const OnboardingPageLayout(
              padding: padding,
              child: Text("centered"),
            ),
          ),
        ),
      ),
    );

    final constrainedFinder = find.descendant(
      of: find.byType(OnboardingPageLayout),
      matching: find.byWidgetPredicate(
        (w) =>
            w is ConstrainedBox && w.constraints.minHeight == expectedMinHeight,
      ),
    );
    expect(constrainedFinder, findsOneWidget);

    final column = tester.widget<Column>(
      find.descendant(of: constrainedFinder, matching: find.byType(Column)),
    );
    expect(column.mainAxisAlignment, MainAxisAlignment.center);
  });

  testWidgets("short content does not create extra vertical scroll extent", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, viewportHeight));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: viewportHeight,
            child: const OnboardingPageLayout(
              padding: padding,
              child: Text("hi"),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, 0);
  });
}
