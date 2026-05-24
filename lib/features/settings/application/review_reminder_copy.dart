abstract final class ReviewReminderCopy {
  static const defaultTitle = "Bạn có giao dịch cần kiểm tra lại";
  static const fallbackBody = "Có giao dịch đang chờ bạn chốt lại thông tin.";

  static String bodyForCount(int count) {
    return "Bạn có $count giao dịch đang chờ đối soát. "
        "Mở app để kiểm tra lại nhé.";
  }
}
