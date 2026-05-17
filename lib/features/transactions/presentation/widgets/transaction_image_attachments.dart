import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";

import "../../../../core/strings.dart";
import "../../../image_attachment/domain/image_attachment_model.dart";
import "../../../image_attachment/presentation/widgets/image_attachment_list.dart";

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
                  label: const Text(AppStrings.takePhoto),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text(AppStrings.pickPhoto),
              ),
            ),
          ],
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 10),
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
