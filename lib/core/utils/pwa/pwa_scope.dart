import "package:flutter/material.dart";

import "package:smart_expense/core/utils/pwa/pwa_install_prompt_controller.dart";

/// Exposes [PwaInstallPromptController] to the widget tree.
class PwaScope extends InheritedWidget {
  const PwaScope({super.key, required this.controller, required super.child});

  final PwaInstallPromptController controller;

  static PwaInstallPromptController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PwaScope>();
    assert(scope != null, "PwaScope not found");
    return scope!.controller;
  }

  static PwaInstallPromptController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PwaScope>()?.controller;
  }

  @override
  bool updateShouldNotify(PwaScope oldWidget) =>
      oldWidget.controller != controller;
}
