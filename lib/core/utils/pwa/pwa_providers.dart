import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_prefs.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";

final pwaInstallServiceProvider = Provider<PwaInstallService>(
  (ref) => createPwaInstallService(),
);

final pwaInstallPrefsProvider = Provider<PwaInstallPrefs>(
  (ref) => PwaInstallPrefs(ref.watch(sharedPreferencesProvider)),
);
