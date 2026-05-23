import "dart:convert";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/settings/domain/user_preferences.dart";

const _kPrefsKey = "userPreferences";

class UserPreferencesController extends Notifier<UserPreferences> {
  @override
  UserPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_kPrefsKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return UserPreferences.fromJson(decoded);
      } catch (_) {
        return const UserPreferences();
      }
    }
    return const UserPreferences();
  }

  Future<void> update(UserPreferences next) async {
    if (next == state) return;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kPrefsKey, jsonEncode(next.toJson()));
    state = next;
  }
}

final userPreferencesControllerProvider =
    NotifierProvider<UserPreferencesController, UserPreferences>(
      UserPreferencesController.new,
    );
