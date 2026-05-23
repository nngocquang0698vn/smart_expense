import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/data/attachments/image_picker_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/transaction_image_limits.dart";
import "package:smart_expense/shared/components/app_notification.dart";

enum TransactionImagePickStatus {
  cancelled,
  limitReached,
  failed,
  added,
  addedPartial,
}

class TransactionImagePickOutcome {
  const TransactionImagePickOutcome({
    required this.status,
    this.images = const [],
    this.skippedCount = 0,
  });

  final TransactionImagePickStatus status;
  final List<ImageAttachmentModel> images;
  final int skippedCount;
}

/// Chọn và thêm ảnh vào draft giao dịch (tối đa [TransactionImageLimits.maxPerTransaction]).
class TransactionImageActions {
  const TransactionImageActions._();

  static Future<TransactionImagePickOutcome> pickAndAdd({
    required BuildContext context,
    required ImagePickerService picker,
    required ImageSource source,
    required int currentImageCount,
  }) async {
    final remaining = TransactionImageLimits.remainingSlots(currentImageCount);
    if (remaining <= 0) {
      return const TransactionImagePickOutcome(
        status: TransactionImagePickStatus.limitReached,
      );
    }

    try {
      if (source == ImageSource.camera) {
        final picked = await picker.pick(ImageSource.camera);
        if (picked == null) {
          return const TransactionImagePickOutcome(
            status: TransactionImagePickStatus.cancelled,
          );
        }
        return TransactionImagePickOutcome(
          status: TransactionImagePickStatus.added,
          images: [picked.image],
        );
      }

      final batch = await picker.pickMultipleFromGallery(limit: remaining);
      if (batch.picked.isEmpty) {
        return const TransactionImagePickOutcome(
          status: TransactionImagePickStatus.cancelled,
        );
      }

      final images = batch.picked.map((p) => p.image).toList();
      if (batch.truncatedByLimit) {
        return TransactionImagePickOutcome(
          status: TransactionImagePickStatus.addedPartial,
          images: images,
          skippedCount: batch.userSelectedCount - images.length,
        );
      }
      return TransactionImagePickOutcome(
        status: TransactionImagePickStatus.added,
        images: images,
      );
    } catch (_) {
      if (context.mounted) {
        showError(context, context.l10n.imageSaveFailed);
      }
      return const TransactionImagePickOutcome(
        status: TransactionImagePickStatus.failed,
      );
    }
  }

  static void notifyOutcome(BuildContext context, TransactionImagePickOutcome outcome) {
    switch (outcome.status) {
      case TransactionImagePickStatus.limitReached:
        showError(context, context.l10n.transactionImageLimitReached);
      case TransactionImagePickStatus.addedPartial:
        if (outcome.skippedCount > 0) {
          showError(
            context,
            context.l10n.transactionImagePartialPick(outcome.skippedCount),
          );
        }
      case TransactionImagePickStatus.cancelled:
      case TransactionImagePickStatus.failed:
      case TransactionImagePickStatus.added:
        break;
    }
  }
}
