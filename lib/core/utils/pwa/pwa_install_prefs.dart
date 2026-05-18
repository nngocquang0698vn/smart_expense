import "package:shared_preferences/shared_preferences.dart";

const _kNeverShow = "pwa_install_never_show";
const _kSnoozeUntilMs = "pwa_install_snooze_until_ms";

/// Persists dismiss/snooze state for the PWA install banner.
class PwaInstallPrefs {
  PwaInstallPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const snoozeDuration = Duration(days: 7);

  bool get neverShow => _prefs.getBool(_kNeverShow) ?? false;

  DateTime? get snoozeUntil {
    final ms = _prefs.getInt(_kSnoozeUntilMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool get isSnoozed {
    final until = snoozeUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  bool get canShowBanner => !neverShow && !isSnoozed;

  Future<void> snooze() async {
    final until = DateTime.now().add(snoozeDuration);
    await _prefs.setInt(_kSnoozeUntilMs, until.millisecondsSinceEpoch);
  }

  Future<void> setNeverShow() async {
    await _prefs.setBool(_kNeverShow, true);
  }

  Future<void> resetPrompt() async {
    await _prefs.remove(_kNeverShow);
    await _prefs.remove(_kSnoozeUntilMs);
  }
}
