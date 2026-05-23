import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";

/// Lọc danh sách chờ đối soát theo loại tệp đính kèm.
enum PendingAttachmentFilter {
  all,
  withImages,
  withAudio,
  withMedia,
  withoutAttachments,
}

List<LedgerTransaction> filterPendingByAttachment(
  List<LedgerTransaction> transactions,
  PendingAttachmentFilter filter,
) {
  return switch (filter) {
    PendingAttachmentFilter.all => transactions,
    PendingAttachmentFilter.withImages =>
      transactions.where((t) => t.hasImages).toList(),
    PendingAttachmentFilter.withAudio =>
      transactions.where((t) => t.hasAudio).toList(),
    PendingAttachmentFilter.withMedia =>
      transactions.where((t) => t.hasImages || t.hasAudio).toList(),
    PendingAttachmentFilter.withoutAttachments =>
      transactions.where((t) => !t.hasImages && !t.hasAudio).toList(),
  };
}

/// ID giao dịch kế tiếp trong danh sách đã lọc; `null` nếu đang ở cuối.
String? nextPendingTransactionId({
  required List<LedgerTransaction> filtered,
  required String? currentId,
}) {
  if (filtered.isEmpty || currentId == null) return null;
  final index = filtered.indexWhere((t) => t.id == currentId);
  if (index < 0) return filtered.length > 1 ? filtered[1].id : null;
  if (index + 1 < filtered.length) return filtered[index + 1].id;
  return null;
}

/// ID giao dịch trước đó trong danh sách đã lọc; `null` nếu đang ở đầu.
String? previousPendingTransactionId({
  required List<LedgerTransaction> filtered,
  required String? currentId,
}) {
  if (filtered.isEmpty || currentId == null) return null;
  final index = filtered.indexWhere((t) => t.id == currentId);
  if (index < 0) return null;
  if (index > 0) return filtered[index - 1].id;
  return null;
}

bool canGoToPreviousPending({
  required List<LedgerTransaction> filtered,
  required String? currentId,
}) =>
    previousPendingTransactionId(filtered: filtered, currentId: currentId) !=
    null;

bool canGoToNextPending({
  required List<LedgerTransaction> filtered,
  required String? currentId,
}) =>
    nextPendingTransactionId(filtered: filtered, currentId: currentId) != null;

/// Đồng bộ selection sau khi đổi filter hoặc reload.
String? reconcilePendingSelection({
  required List<LedgerTransaction> filtered,
  required String? selectedId,
}) {
  if (filtered.isEmpty) return null;
  if (selectedId != null && filtered.any((t) => t.id == selectedId)) {
    return selectedId;
  }
  return filtered.first.id;
}
