import "package:flutter/material.dart";

import "data/ledger_repository.dart";

class RepoScope extends InheritedNotifier<LedgerRepository> {
  const RepoScope({
    required LedgerRepository super.notifier,
    required super.child,
    super.key,
  });

  static LedgerRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepoScope>();
    assert(scope != null, "RepoScope not found");
    return scope!.notifier!;
  }
}
