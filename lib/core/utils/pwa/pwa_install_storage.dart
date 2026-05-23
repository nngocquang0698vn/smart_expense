import "package:shared_preferences/shared_preferences.dart";

const _kDismissedAtMs = "pwa_install_dismissed_at_ms";
const _kDismissCount = "pwa_install_dismiss_count";
const _kLastShownAtMs = "pwa_install_last_shown_at_ms";
const _kInstalled = "pwa_install_installed";
const _kSessionCount = "pwa_install_session_count";
const _kSessionsSinceDismiss = "pwa_install_sessions_since_dismiss";
const _kPostActionCtaShown = "pwa_install_post_action_cta_shown";
const _kFirstCompleteTxSaved = "pwa_install_first_complete_tx_saved";

/// Persists PWA install prompt dismiss, session, and installed state.
class PwaInstallStorage {
  PwaInstallStorage(this._prefs);

  final SharedPreferences _prefs;

  bool get isInstalled => _prefs.getBool(_kInstalled) ?? false;

  int get dismissCount => _prefs.getInt(_kDismissCount) ?? 0;

  int get sessionCount => _prefs.getInt(_kSessionCount) ?? 0;

  int get sessionsSinceDismiss => _prefs.getInt(_kSessionsSinceDismiss) ?? 0;

  bool get postActionCtaShown => _prefs.getBool(_kPostActionCtaShown) ?? false;

  bool get firstCompleteTransactionSaved =>
      _prefs.getBool(_kFirstCompleteTxSaved) ?? false;

  DateTime? get dismissedAt {
    final ms = _prefs.getInt(_kDismissedAtMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Automatic prompts (onboarding card extras, post-action) — not Settings.
  bool get canShowAutoPrompt {
    if (isInstalled) return false;
    final count = dismissCount;
    if (count >= 3) return false;
    final at = dismissedAt;
    if (at == null || count == 0) return true;
    final elapsed = DateTime.now().difference(at);
    return switch (count) {
      1 => elapsed.inDays >= 3 || sessionsSinceDismiss >= 5,
      2 => elapsed.inDays >= 14,
      _ => false,
    };
  }

  Future<void> recordSession() async {
    await _prefs.setInt(_kSessionCount, sessionCount + 1);
    if (dismissedAt != null) {
      await _prefs.setInt(_kSessionsSinceDismiss, sessionsSinceDismiss + 1);
    }
  }

  Future<void> recordDismiss() async {
    final next = dismissCount + 1;
    await _prefs.setInt(_kDismissCount, next);
    await _prefs.setInt(_kDismissedAtMs, DateTime.now().millisecondsSinceEpoch);
    await _prefs.setInt(_kSessionsSinceDismiss, 0);
    await _prefs.setInt(_kLastShownAtMs, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> markInstalled() async {
    await _prefs.setBool(_kInstalled, true);
  }

  Future<void> markPostActionCtaShown() async {
    await _prefs.setBool(_kPostActionCtaShown, true);
  }

  /// Returns true only the first time a complete transaction is saved.
  Future<bool> markFirstCompleteTransactionSaved() async {
    if (firstCompleteTransactionSaved) return false;
    await _prefs.setBool(_kFirstCompleteTxSaved, true);
    return true;
  }

  Future<void> resetForDebug() async {
    await _prefs.remove(_kDismissedAtMs);
    await _prefs.remove(_kDismissCount);
    await _prefs.remove(_kLastShownAtMs);
    await _prefs.remove(_kInstalled);
    await _prefs.remove(_kSessionCount);
    await _prefs.remove(_kSessionsSinceDismiss);
    await _prefs.remove(_kPostActionCtaShown);
    await _prefs.remove(_kFirstCompleteTxSaved);
  }
}
