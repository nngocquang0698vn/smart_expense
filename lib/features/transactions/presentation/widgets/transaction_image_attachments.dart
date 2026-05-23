import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";

import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/utils/attachment_capture_policy.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/transaction_image_limits.dart";
import "package:smart_expense/features/transactions/presentation/widgets/attachments/image_attachment_list.dart";
import "package:smart_expense/shared/design_system/design_system.dart";

class TransactionImageAttachments extends StatelessWidget {
  const TransactionImageAttachments({
    super.key,
    required this.images,
    required this.onPick,
    required this.onDelete,
    this.showCamera,
    this.thumbnailHeight = 80,
    this.maxImages = TransactionImageLimits.maxPerTransaction,
  });

  final List<ImageAttachmentModel> images;
  final ValueChanged<ImageSource> onPick;
  final ValueChanged<ImageAttachmentModel> onDelete;

  /// `null` → [AttachmentCapturePolicy.showReceiptCameraButton].
  final bool? showCamera;
  final double thumbnailHeight;
  final int maxImages;

  @override
  Widget build(BuildContext context) {
    final showCameraButton =
        showCamera ?? AttachmentCapturePolicy.showReceiptCameraButton;
    final atLimit = images.length >= maxImages;

    if (images.isEmpty) {
      return _PickButtonsRow(
        showCamera: showCameraButton,
        atLimit: atLimit,
        onPick: onPick,
        expanded: true,
      );
    }

    final addTiles = atLimit
        ? const <Widget>[]
        : _inlineAddTiles(
            context,
            showCamera: showCameraButton,
            height: thumbnailHeight,
            onPick: onPick,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
          child: Text(
            context.l10n.transactionImageCount(images.length, maxImages),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.financeColors.textMuted,
            ),
          ),
        ),
        ImageAttachmentList(
          images: images,
          onDelete: onDelete,
          height: thumbnailHeight,
          trailing: addTiles,
        ),
      ],
    );
  }

  List<Widget> _inlineAddTiles(
    BuildContext context, {
    required bool showCamera,
    required double height,
    required ValueChanged<ImageSource> onPick,
  }) {
    return [
      if (showCamera)
        _AddImageTile(
          height: height,
          icon: Icons.photo_camera_outlined,
          label: context.l10n.takePhoto,
          onPressed: () => onPick(ImageSource.camera),
        ),
      _AddImageTile(
        height: height,
        icon: Icons.photo_library_outlined,
        label: context.l10n.pickPhoto,
        onPressed: () => onPick(ImageSource.gallery),
      ),
    ];
  }
}

class _PickButtonsRow extends StatelessWidget {
  const _PickButtonsRow({
    required this.showCamera,
    required this.atLimit,
    required this.onPick,
    required this.expanded,
  });

  final bool showCamera;
  final bool atLimit;
  final ValueChanged<ImageSource> onPick;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showCamera) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: atLimit ? null : () => onPick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined, size: 16),
              label: Text(context.l10n.takePhoto),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: atLimit ? null : () => onPick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, size: 16),
            label: Text(context.l10n.pickPhoto),
          ),
        ),
      ],
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({
    required this.height,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final double height;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final finance = context.financeColors;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: finance.fieldFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            height: height,
            width: height * 1.1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: finance.fieldText),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: finance.fieldText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
