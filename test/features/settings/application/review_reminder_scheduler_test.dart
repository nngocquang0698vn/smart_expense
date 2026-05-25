import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/testing/fake_ledger_repository.dart";
import "package:smart_expense/features/settings/application/notifications/review_notification_platform.dart";
import "package:smart_expense/features/settings/application/review_reminder_notification_service.dart";
import "package:smart_expense/features/settings/application/review_reminder_scheduler.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LedgerRepository repo;
  late SharedPreferences prefs;
  late _FakeReviewNotificationPlatform platform;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = await createFakeLedgerRepository();
    await repo.clearAllTransactions();
    platform = _FakeReviewNotificationPlatform();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ledgerRepositoryProvider.overrideWithValue(repo),
        reviewNotificationPlatformProvider.overrideWithValue(platform),
      ],
    );
    container.read(reviewReminderSchedulerProvider);
    await _flushAsync();
  });

  tearDown(() {
    container.dispose();
  });

  test(
    "demo notification is not scheduled when there is no pending review",
    () async {
      final scheduled = await container
          .read(reviewReminderSchedulerProvider.notifier)
          .scheduleDemoNotification(Duration.zero);
      await _flushAsync();

      expect(scheduled, isFalse);
      expect(platform.shown, isEmpty);
    },
  );

  test(
    "demo notification sends latest pending count when timer fires",
    () async {
      await _addPending(repo, "First");
      await _addPending(repo, "Second");

      final scheduled = await container
          .read(reviewReminderSchedulerProvider.notifier)
          .scheduleDemoNotification(Duration.zero);
      await _flushAsync();

      expect(scheduled, isTrue);
      expect(platform.shown, hasLength(1));
      expect(
        platform.shown.single.id,
        ReviewReminderNotificationService.demoNotificationId,
      );
      expect(platform.shown.single.body, contains("2 giao dịch"));
      expect(platform.shown.single.payload, "open_pending_review");
    },
  );

  test(
    "demo notification is skipped when pending is resolved before timer",
    () async {
      await _addPending(repo, "Review me");
      final pending = await repo.pendingAll(
        const DateFilterSelection(preset: DateFilterPreset.allTime),
      );

      final scheduled = await container
          .read(reviewReminderSchedulerProvider.notifier)
          .scheduleDemoNotification(const Duration(milliseconds: 20));
      await repo.confirmPending(pending.single.id);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await _flushAsync();

      expect(scheduled, isTrue);
      expect(platform.shown, isEmpty);
    },
  );

  test(
    "pendingReviewCount uses pending=true as the eligibility source",
    () async {
      final categories = await repo.categories();
      final expenseCategory = categories.firstWhere(
        (category) => !category.isIncome,
      );
      await repo.addQuick(
        title: "Confirmed with note",
        amountVnd: 20_000,
        isIncome: false,
        categoryId: expenseCategory.id,
        pending: false,
        note: "Has review-looking metadata but is already confirmed",
      );
      await _addPending(repo, "Actual pending");

      final count = await container
          .read(reviewReminderSchedulerProvider.notifier)
          .pendingReviewCount();

      expect(count, 1);
    },
  );
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Future<void> _addPending(LedgerRepository repo, String title) async {
  final categories = await repo.categories();
  final expenseCategory = categories.firstWhere(
    (category) => !category.isIncome,
  );
  await repo.addQuick(
    title: title,
    amountVnd: 10_000,
    isIncome: false,
    categoryId: expenseCategory.id,
    pending: true,
  );
}

class _ShownNotification {
  const _ShownNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}

class _FakeReviewNotificationPlatform implements ReviewNotificationPlatform {
  final _tapController = StreamController<void>.broadcast();
  final shown = <_ShownNotification>[];
  var status = ReviewNotificationPermissionStatus.granted;
  var initialized = false;
  var cancelCount = 0;
  var disposed = false;

  @override
  Stream<void> get taps => _tapController.stream;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<ReviewNotificationPermissionStatus> permissionStatus() async => status;

  @override
  Future<ReviewNotificationPermissionStatus> requestPermission() async =>
      status;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    shown.add(
      _ShownNotification(id: id, title: title, body: body, payload: payload),
    );
  }

  @override
  Future<void> cancelReviewReminders() async {
    cancelCount++;
  }

  @override
  void dispose() {
    disposed = true;
    _tapController.close();
  }
}
