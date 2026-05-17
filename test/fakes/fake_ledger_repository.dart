import "package:sembast/sembast_memory.dart";

import "package:smart_expense/data/ledger_repository.dart";

/// Opens an in-memory Sembast database and returns a ready [LedgerRepository].
Future<LedgerRepository> createFakeLedgerRepository() async {
  final db = await databaseFactoryMemory.openDatabase("fake_ledger_test.db");
  final repo = LedgerRepository(db);
  await repo.ensureDefaults();
  return repo;
}
