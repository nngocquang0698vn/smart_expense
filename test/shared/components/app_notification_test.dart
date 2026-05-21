import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/app_notification.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

void main() {
  tearDown(hideAppNotification);

  testWidgets("showAppNotification renders a top overlay notification", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppNotification(
                context,
                title: "Đã lưu",
                message: "Đã lưu giao dịch.",
                type: AppNotificationType.success,
              ),
              child: const Text("Show"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Show"));
    await tester.pump();

    expect(find.text("Đã lưu"), findsOneWidget);
    expect(find.text("Đã lưu giao dịch."), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    final notificationTop = tester.getTopLeft(find.text("Đã lưu")).dy;
    expect(notificationTop, lessThan(120));

    hideAppNotification();
    await tester.pump();
  });

  testWidgets("showAppNotification replaces the current notification", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showSuccess(context, "Giao dịch đã lưu"),
                  child: const Text("Success"),
                ),
                TextButton(
                  onPressed: () => showError(context, "Không thể lưu"),
                  child: const Text("Error"),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Success"));
    await tester.pump();
    expect(
      find.text(AppLocalizations.vi.notificationSuccessTitle),
      findsOneWidget,
    );

    await tester.tap(find.text("Error"));
    await tester.pump();

    expect(
      find.text(AppLocalizations.vi.notificationSuccessTitle),
      findsNothing,
    );
    expect(
      find.text(AppLocalizations.vi.notificationErrorTitle),
      findsOneWidget,
    );
    expect(find.text("Giao dịch đã lưu"), findsNothing);
    expect(find.text("Không thể lưu"), findsOneWidget);
    expect(find.byIcon(Icons.error_rounded), findsOneWidget);

    hideAppNotification();
    await tester.pump();
  });

  testWidgets("showAppNotification can be closed manually", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showInfo(context, "Đang xử lý dữ liệu"),
              child: const Text("Show"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Show"));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(find.text("Đang xử lý dữ liệu"), findsNothing);
  });
  testWidgets("showAppNotification fits a long Vietnamese message on mobile", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const message =
        "Không thể đồng bộ giao dịch vì kết nối mạng không ổn định, vui lòng "
        "kiểm tra lại Wi-Fi hoặc dữ liệu di động rồi thử lại sau.";

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showError(context, message),
              child: const Text("Show"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Show"));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(message), findsOneWidget);

    final cardRect = tester.getRect(
      find.byKey(const ValueKey("app-notification-card")),
    );
    final closeRect = tester.getRect(find.byIcon(Icons.close_rounded));

    expect(cardRect.left, greaterThanOrEqualTo(12));
    expect(cardRect.right, lessThanOrEqualTo(308));
    expect(cardRect.width, lessThanOrEqualTo(296));
    expect(closeRect.right, lessThanOrEqualTo(cardRect.right));
  });

  testWidgets("showAppNotification keeps controls aligned on regular mobile", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const message =
        "Giao dịch đã được lưu vào danh sách đối soát để bạn kiểm tra lại khi có thời gian.";

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSuccess(context, message),
              child: const Text("Show"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Show"));
    await tester.pumpAndSettle();

    final cardRect = tester.getRect(
      find.byKey(const ValueKey("app-notification-card")),
    );
    final iconRect = tester.getRect(find.byIcon(Icons.check_circle_rounded));
    final closeRect = tester.getRect(find.byIcon(Icons.close_rounded));

    expect(tester.takeException(), isNull);
    expect(cardRect.left, greaterThanOrEqualTo(16));
    expect(cardRect.right, lessThanOrEqualTo(414));
    expect(iconRect.top, greaterThanOrEqualTo(cardRect.top));
    expect(closeRect.top, greaterThanOrEqualTo(cardRect.top));
    expect(closeRect.right, lessThanOrEqualTo(cardRect.right));
  });

  testWidgets("showAppNotification respects SafeArea top padding", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: const EdgeInsets.only(top: 32)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showInfo(context, "Đang xử lý dữ liệu."),
              child: const Text("Show"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Show"));
    await tester.pumpAndSettle();

    final cardRect = tester.getRect(
      find.byKey(const ValueKey("app-notification-card")),
    );

    expect(tester.takeException(), isNull);
    expect(
      cardRect.top,
      greaterThanOrEqualTo(32 + AppNotificationTokens.topMargin),
    );
  });

  testWidgets("showAppNotification caps width and centers on tablet", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(768, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showWarning(
                context,
                "Số dư tháng này đang thấp hơn dự kiến, hãy kiểm tra lại các khoản chi lớn.",
              ),
              child: const Text("Show"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Show"));
    await tester.pumpAndSettle();

    final cardRect = tester.getRect(
      find.byKey(const ValueKey("app-notification-card")),
    );

    expect(tester.takeException(), isNull);
    expect(cardRect.width, lessThanOrEqualTo(AppNotificationTokens.maxWidth));
    expect(cardRect.center.dx, closeTo(384, 0.5));
  });

  testWidgets("showAppNotification is capped and centered on desktop", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showInfo(
                context,
                "Báo cáo tháng này đã sẵn sàng để xem trên màn hình lớn.",
              ),
              child: const Text("Show"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Show"));
    await tester.pumpAndSettle();

    final cardRect = tester.getRect(
      find.byKey(const ValueKey("app-notification-card")),
    );

    expect(tester.takeException(), isNull);
    expect(cardRect.width, lessThanOrEqualTo(AppNotificationTokens.maxWidth));
    expect(cardRect.center.dx, closeTo(600, 0.5));
  });

  testWidgets("showAppNotification responds to browser resize", (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showInfo(
                context,
                "Thông báo này cần giữ bố cục ổn định khi đổi hướng màn hình hoặc resize PWA.",
              ),
              child: const Text("Show"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Show"));
    await tester.pumpAndSettle();
    final mobileRect = tester.getRect(
      find.byKey(const ValueKey("app-notification-card")),
    );

    await tester.binding.setSurfaceSize(const Size(812, 390));
    await tester.pumpAndSettle();
    final landscapeRect = tester.getRect(
      find.byKey(const ValueKey("app-notification-card")),
    );

    expect(tester.takeException(), isNull);
    expect(mobileRect.width, closeTo(358, 0.5));
    expect(
      landscapeRect.width,
      lessThanOrEqualTo(AppNotificationTokens.maxWidth),
    );
    expect(landscapeRect.center.dx, closeTo(406, 0.5));
  });
}
