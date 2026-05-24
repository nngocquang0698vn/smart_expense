enum ReviewReminderMode { endOfDay, interval }

class ReviewReminderTime implements Comparable<ReviewReminderTime> {
  const ReviewReminderTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  String get label {
    final h = hour.toString().padLeft(2, "0");
    final m = minute.toString().padLeft(2, "0");
    return "$h:$m";
  }

  Map<String, dynamic> toJson() => {"hour": hour, "minute": minute};

  factory ReviewReminderTime.fromJson(
    Object? raw,
    ReviewReminderTime fallback,
  ) {
    if (raw is! Map) return fallback;
    final hour = (raw["hour"] as num?)?.toInt();
    final minute = (raw["minute"] as num?)?.toInt();
    if (hour == null || minute == null) return fallback;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return fallback;
    return ReviewReminderTime(hour: hour, minute: minute);
  }

  DateTime onDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  @override
  int compareTo(ReviewReminderTime other) {
    return minutesOfDay.compareTo(other.minutesOfDay);
  }

  @override
  bool operator ==(Object other) =>
      other is ReviewReminderTime &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

abstract final class ReviewReminderDefaults {
  static const enabled = false;
  static const mode = ReviewReminderMode.endOfDay;
  static const endOfDayReminderTime = ReviewReminderTime(hour: 20, minute: 30);
  static const intervalReminderStartTime = ReviewReminderTime(
    hour: 6,
    minute: 0,
  );
  static const intervalReminderEndTime = ReviewReminderTime(
    hour: 21,
    minute: 0,
  );
  static const intervalReminderHours = 4;
  static const minIntervalHours = 1;
  static const maxIntervalHours = 12;
}

class ReviewReminderSettings {
  const ReviewReminderSettings({
    this.enabled = ReviewReminderDefaults.enabled,
    this.mode = ReviewReminderDefaults.mode,
    this.endOfDayReminderTime = ReviewReminderDefaults.endOfDayReminderTime,
    this.intervalReminderStartTime =
        ReviewReminderDefaults.intervalReminderStartTime,
    this.intervalReminderEndTime =
        ReviewReminderDefaults.intervalReminderEndTime,
    this.intervalReminderHours = ReviewReminderDefaults.intervalReminderHours,
    this.lastDismissedReminderDate,
  });

  final bool enabled;
  final ReviewReminderMode mode;
  final ReviewReminderTime endOfDayReminderTime;
  final ReviewReminderTime intervalReminderStartTime;
  final ReviewReminderTime intervalReminderEndTime;
  final int intervalReminderHours;
  final DateTime? lastDismissedReminderDate;

  ReviewReminderSettings copyWith({
    bool? enabled,
    ReviewReminderMode? mode,
    ReviewReminderTime? endOfDayReminderTime,
    ReviewReminderTime? intervalReminderStartTime,
    ReviewReminderTime? intervalReminderEndTime,
    int? intervalReminderHours,
    Object? lastDismissedReminderDate = _unset,
  }) {
    return ReviewReminderSettings(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      endOfDayReminderTime: endOfDayReminderTime ?? this.endOfDayReminderTime,
      intervalReminderStartTime:
          intervalReminderStartTime ?? this.intervalReminderStartTime,
      intervalReminderEndTime:
          intervalReminderEndTime ?? this.intervalReminderEndTime,
      intervalReminderHours:
          intervalReminderHours ?? this.intervalReminderHours,
      lastDismissedReminderDate: lastDismissedReminderDate == _unset
          ? this.lastDismissedReminderDate
          : lastDismissedReminderDate as DateTime?,
    );
  }

  List<String> validate() {
    final errors = <String>[];
    if (intervalReminderHours < ReviewReminderDefaults.minIntervalHours ||
        intervalReminderHours > ReviewReminderDefaults.maxIntervalHours) {
      errors.add("Khoảng lặp nên từ 1 đến 12 tiếng.");
    }
    if (intervalReminderStartTime.compareTo(intervalReminderEndTime) >= 0) {
      errors.add("Giờ bắt đầu phải trước giờ kết thúc.");
    }
    return errors;
  }

  List<String> warnings() {
    final windowMinutes =
        intervalReminderEndTime.minutesOfDay -
        intervalReminderStartTime.minutesOfDay;
    if (windowMinutes > 0 && windowMinutes < intervalReminderHours * 60) {
      return ["Khung giờ này quá ngắn so với khoảng lặp đã chọn."];
    }
    return const [];
  }

  Map<String, dynamic> toJson() => {
    "enabled": enabled,
    "mode": mode.name,
    "endOfDayReminderTime": endOfDayReminderTime.toJson(),
    "intervalReminderStartTime": intervalReminderStartTime.toJson(),
    "intervalReminderEndTime": intervalReminderEndTime.toJson(),
    "intervalReminderHours": intervalReminderHours,
    "lastDismissedReminderDate": lastDismissedReminderDate?.toIso8601String(),
  };

  factory ReviewReminderSettings.fromJson(Object? raw) {
    if (raw is! Map) return const ReviewReminderSettings();
    final modeName = raw["mode"] as String?;
    final mode = ReviewReminderMode.values.firstWhere(
      (item) => item.name == modeName,
      orElse: () => ReviewReminderDefaults.mode,
    );
    return ReviewReminderSettings(
      enabled: raw["enabled"] as bool? ?? ReviewReminderDefaults.enabled,
      mode: mode,
      endOfDayReminderTime: ReviewReminderTime.fromJson(
        raw["endOfDayReminderTime"],
        ReviewReminderDefaults.endOfDayReminderTime,
      ),
      intervalReminderStartTime: ReviewReminderTime.fromJson(
        raw["intervalReminderStartTime"],
        ReviewReminderDefaults.intervalReminderStartTime,
      ),
      intervalReminderEndTime: ReviewReminderTime.fromJson(
        raw["intervalReminderEndTime"],
        ReviewReminderDefaults.intervalReminderEndTime,
      ),
      intervalReminderHours:
          (raw["intervalReminderHours"] as num?)?.toInt() ??
          ReviewReminderDefaults.intervalReminderHours,
      lastDismissedReminderDate: DateTime.tryParse(
        raw["lastDismissedReminderDate"] as String? ?? "",
      ),
    );
  }

  static const _unset = Object();

  @override
  bool operator ==(Object other) =>
      other is ReviewReminderSettings &&
      other.enabled == enabled &&
      other.mode == mode &&
      other.endOfDayReminderTime == endOfDayReminderTime &&
      other.intervalReminderStartTime == intervalReminderStartTime &&
      other.intervalReminderEndTime == intervalReminderEndTime &&
      other.intervalReminderHours == intervalReminderHours &&
      other.lastDismissedReminderDate == lastDismissedReminderDate;

  @override
  int get hashCode => Object.hash(
    enabled,
    mode,
    endOfDayReminderTime,
    intervalReminderStartTime,
    intervalReminderEndTime,
    intervalReminderHours,
    lastDismissedReminderDate,
  );
}
