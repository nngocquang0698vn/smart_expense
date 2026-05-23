/// Giới hạn ảnh đính kèm trên một giao dịch.
abstract final class TransactionImageLimits {
  static const int maxPerTransaction = 5;

  static int remainingSlots(int currentCount) =>
      (maxPerTransaction - currentCount).clamp(0, maxPerTransaction);

  static bool canAddMore(int currentCount) => currentCount < maxPerTransaction;
}
