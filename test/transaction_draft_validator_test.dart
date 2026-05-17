import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/application/transaction_draft_validator.dart";

void main() {
  const validator = TransactionDraftValidator();

  test("allows pending drafts without amount or category", () {
    final errors = validator.validate(
      const TransactionDraft(amountVnd: 0, pending: true, categoryId: null),
    );

    expect(errors, isEmpty);
    expect(
      validator.isComplete(
        const TransactionDraft(amountVnd: 0, pending: true, categoryId: null),
      ),
      isFalse,
    );
  });

  test("requires amount and category for confirmed drafts", () {
    final errors = validator.validate(
      const TransactionDraft(amountVnd: 0, pending: false, categoryId: null),
    );

    expect(errors, [
      TransactionDraftValidationError.amountRequired,
      TransactionDraftValidationError.categoryRequired,
    ]);
  });

  test("marks a draft complete when it has positive amount and category", () {
    const draft = TransactionDraft(
      amountVnd: 120000,
      pending: true,
      categoryId: "food",
    );

    expect(validator.validate(draft), isEmpty);
    expect(validator.isComplete(draft), isTrue);
  });
}
