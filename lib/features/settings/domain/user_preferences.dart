/// User-facing preferences persisted locally (not ledger data).
class UserPreferences {
  const UserPreferences({this.quickConfirmPending = true});

  /// When true, confirming a pending transaction skips the confirmation sheet.
  final bool quickConfirmPending;

  UserPreferences copyWith({bool? quickConfirmPending}) {
    return UserPreferences(
      quickConfirmPending: quickConfirmPending ?? this.quickConfirmPending,
    );
  }

  static const _quickConfirmPendingKey = "quickConfirmPending";

  Map<String, dynamic> toJson() => {
    _quickConfirmPendingKey: quickConfirmPending,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      quickConfirmPending: json[_quickConfirmPendingKey] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserPreferences &&
      other.quickConfirmPending == quickConfirmPending;

  @override
  int get hashCode => quickConfirmPending.hashCode;
}
