import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/dashboard/application/dashboard_controller.dart";

final dashboardControllerProvider = Provider.autoDispose<DashboardController>((
  ref,
) {
  final controller = DashboardController(ref.watch(ledgerRepositoryProvider));
  ref.onDispose(controller.dispose);
  controller.bootstrap();
  return controller;
});
