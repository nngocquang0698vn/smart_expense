import "package:smart_expense/features/settings/domain/review_reminder_settings.dart";

/// User-facing preferences persisted locally (not ledger data).
class UserPreferences {
  const UserPreferences({
    this.quickConfirmPending = true,
    this.reviewReminder = const ReviewReminderSettings(),
    this.aiVoiceRecognitionEnabled = false,
    this.aiVoiceApiEndpoint,
    this.aiVoiceDemoToken,
  });

  /// When true, confirming a pending transaction skips the confirmation sheet.
  final bool quickConfirmPending;
  final ReviewReminderSettings reviewReminder;
  final bool aiVoiceRecognitionEnabled;
  final String? aiVoiceApiEndpoint;
  final String? aiVoiceDemoToken;

  UserPreferences copyWith({
    bool? quickConfirmPending,
    ReviewReminderSettings? reviewReminder,
    bool? aiVoiceRecognitionEnabled,
    Object? aiVoiceApiEndpoint = _unset,
    Object? aiVoiceDemoToken = _unset,
  }) {
    return UserPreferences(
      quickConfirmPending: quickConfirmPending ?? this.quickConfirmPending,
      reviewReminder: reviewReminder ?? this.reviewReminder,
      aiVoiceRecognitionEnabled:
          aiVoiceRecognitionEnabled ?? this.aiVoiceRecognitionEnabled,
      aiVoiceApiEndpoint: identical(aiVoiceApiEndpoint, _unset)
          ? this.aiVoiceApiEndpoint
          : aiVoiceApiEndpoint as String?,
      aiVoiceDemoToken: identical(aiVoiceDemoToken, _unset)
          ? this.aiVoiceDemoToken
          : aiVoiceDemoToken as String?,
    );
  }

  static const _unset = Object();
  static const _quickConfirmPendingKey = "quickConfirmPending";
  static const _reviewReminderKey = "reviewReminder";
  static const _aiVoiceRecognitionEnabledKey = "aiVoiceRecognitionEnabled";
  static const _aiVoiceApiEndpointKey = "aiVoiceApiEndpoint";
  static const _aiVoiceDemoTokenKey = "aiVoiceDemoToken";

  Map<String, dynamic> toJson() => {
    _quickConfirmPendingKey: quickConfirmPending,
    _reviewReminderKey: reviewReminder.toJson(),
    _aiVoiceRecognitionEnabledKey: aiVoiceRecognitionEnabled,
    _aiVoiceApiEndpointKey: aiVoiceApiEndpoint,
    _aiVoiceDemoTokenKey: aiVoiceDemoToken,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      quickConfirmPending: json[_quickConfirmPendingKey] as bool? ?? true,
      reviewReminder: ReviewReminderSettings.fromJson(json[_reviewReminderKey]),
      aiVoiceRecognitionEnabled:
          json[_aiVoiceRecognitionEnabledKey] as bool? ?? false,
      aiVoiceApiEndpoint: _stringOrNull(json[_aiVoiceApiEndpointKey]),
      aiVoiceDemoToken: _stringOrNull(json[_aiVoiceDemoTokenKey]),
    );
  }

  static String? _stringOrNull(Object? raw) {
    if (raw is! String) return null;
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  @override
  bool operator ==(Object other) =>
      other is UserPreferences &&
      other.quickConfirmPending == quickConfirmPending &&
      other.reviewReminder == reviewReminder &&
      other.aiVoiceRecognitionEnabled == aiVoiceRecognitionEnabled &&
      other.aiVoiceApiEndpoint == aiVoiceApiEndpoint &&
      other.aiVoiceDemoToken == aiVoiceDemoToken;

  @override
  int get hashCode => Object.hash(
    quickConfirmPending,
    reviewReminder,
    aiVoiceRecognitionEnabled,
    aiVoiceApiEndpoint,
    aiVoiceDemoToken,
  );
}
