import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/presentation/widgets/attachments/image_attachment_list.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

class TransactionImageAttachments extends StatelessWidget {
  const TransactionImageAttachments({
    super.key,
    required this.images,
    required this.onPick,
    required this.onDelete,
    this.showCamera = true,
    this.thumbnailHeight = 80,
  });

  final List<ImageAttachmentModel> images;
  final ValueChanged<ImageSource> onPick;
  final ValueChanged<ImageAttachmentModel> onDelete;
  final bool showCamera;
  final double thumbnailHeight;

  @override
  Widget build(BuildContext context) {
    final showCameraButton = showCamera && !kIsWeb;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (showCameraButton) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onPick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 16),
                  label: Text(context.l10n.takePhoto),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(context.l10n.pickPhoto),
              ),
            ),
          ],
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          ImageAttachmentList(
            images: images,
            onDelete: onDelete,
            height: thumbnailHeight,
          ),
        ],
      ],
    );
  }
}
