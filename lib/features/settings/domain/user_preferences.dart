import "package:smart_expense/features/settings/domain/review_reminder_settings.dart";

/// User-facing preferences persisted locally (not ledger data).
class UserPreferences {
  const UserPreferences({
    this.quickConfirmPending = true,
    this.reviewReminder = const ReviewReminderSettings(),
  });

  /// When true, confirming a pending transaction skips the confirmation sheet.
  final bool quickConfirmPending;
  final ReviewReminderSettings reviewReminder;

  UserPreferences copyWith({
    bool? quickConfirmPending,
    ReviewReminderSettings? reviewReminder,
  }) {
    return UserPreferences(
      quickConfirmPending: quickConfirmPending ?? this.quickConfirmPending,
      reviewReminder: reviewReminder ?? this.reviewReminder,
    );
  }

  static const _quickConfirmPendingKey = "quickConfirmPending";
  static const _reviewReminderKey = "reviewReminder";

  Map<String, dynamic> toJson() => {
    _quickConfirmPendingKey: quickConfirmPending,
    _reviewReminderKey: reviewReminder.toJson(),
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      quickConfirmPending: json[_quickConfirmPendingKey] as bool? ?? true,
      reviewReminder: ReviewReminderSettings.fromJson(json[_reviewReminderKey]),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserPreferences &&
      other.quickConfirmPending == quickConfirmPending &&
      other.reviewReminder == reviewReminder;

  @override
  int get hashCode => Object.hash(quickConfirmPending, reviewReminder);
}
