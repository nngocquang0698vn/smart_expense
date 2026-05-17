import "package:flutter_test/flutter_test.dart";

import "fake_ledger_repository.dart";

void main() {
  test("createFakeLedgerRepository seeds default categories", () async {
    final repo = await createFakeLedgerRepository();
    final categories = await repo.categories();
    expect(categories, isNotEmpty);
  });
}
