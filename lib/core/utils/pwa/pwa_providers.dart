import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_storage.dart";

final pwaInstallServiceProvider = Provider<PwaInstallService>(
  (ref) => createPwaInstallService(),
);

final pwaInstallStorageProvider = Provider<PwaInstallStorage>(
  (ref) => PwaInstallStorage(ref.watch(sharedPreferencesProvider)),
);
