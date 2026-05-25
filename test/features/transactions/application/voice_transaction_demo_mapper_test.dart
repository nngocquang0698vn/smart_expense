import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/application/voice_transaction_demo_mapper.dart";
import "package:smart_expense/features/transactions/data/voice_transaction_demo_api_client.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

void main() {
  const mapper = VoiceTransactionDemoMapper();

  test("normalizes endpoint with trailing slash or full API path", () {
    expect(
      VoiceTransactionDemoEndpoint.normalize(
        "https://smart-expense-m8nm.onrender.com/",
      ),
      "https://smart-expense-m8nm.onrender.com",
    );
    expect(
      VoiceTransactionDemoEndpoint.normalize(
        "https://smart-expense-m8nm.onrender.com/voice-transaction-demo/",
      ),
      "https://smart-expense-m8nm.onrender.com",
    );
  });

  test("response parsing forces pending true and keeps missing date null", () {
    final response = VoiceTransactionDemoResponse.fromJson({
      "transcript": "Nạp điện thoại hết 100.000.",
      "transactionDraft": {
        "title": "Nạp điện thoại",
        "amountVnd": 100000,
        "isIncome": false,
        "categoryId": LedgerRepository.kOtherExpenseId,
        "transactionDate": null,
        "pending": false,
      },
      "warnings": ["date_uncertain"],
    });

    expect(response.transactionDraft.pending, isTrue);
    expect(response.transactionDraft.transactionDate, isNull);
  });

  test("maps system_khac_expense to local expense category", () {
    final patch = mapper.map(
      response: VoiceTransactionDemoResponse.fromJson({
        "transcript": "Nạp điện thoại hết 100.000.",
        "transactionDraft": {
          "title": "Nạp điện thoại",
          "amountVnd": 100000,
          "isIncome": false,
          "categoryId": LedgerRepository.kOtherExpenseId,
          "categoryKey": "other_expense",
          "categoryName": "Khác",
          "note": "Nạp điện thoại hết 100.000.",
          "pending": true,
        },
      }),
      categories: [
        _category(
          id: LedgerRepository.kDefaultExpenseFoodId,
          name: "Ăn uống",
          isIncome: false,
        ),
        _category(
          id: LedgerRepository.kOtherExpenseId,
          name: "Khác",
          isIncome: false,
        ),
        _category(
          id: LedgerRepository.kOtherIncomeId,
          name: "Khác",
          isIncome: true,
        ),
      ],
      currentCategoryId: LedgerRepository.kDefaultExpenseFoodId,
    );

    expect(patch.categoryId, LedgerRepository.kOtherExpenseId);
    expect(patch.pending, isTrue);
    expect(patch.occurredAt, isNull);
  });
}

LedgerCategory _category({
  required String id,
  required String name,
  required bool isIncome,
}) {
  return LedgerCategory(
    id: id,
    name: name,
    iconKey: "category",
    colorValue: 0,
    isIncome: isIncome,
  );
}
