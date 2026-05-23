import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:smart_expense/core/utils/attachment_capture_policy.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/app_text_field.dart";
import "package:smart_expense/shared/components/form_amount_field.dart";
import "package:smart_expense/shared/design_system/design_system.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/shared/components/app_date_picker.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_image_attachments.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_type_toggle.dart";

/// Shared fields for quick entry and full transaction editor sheets.
///
/// Thứ tự: tiêu đề → Chi tiêu/Thu nhập → số tiền → danh mục → ngày → ghi chú
/// → [mediaSections] (ghi âm) → ảnh. Toggle chờ đối soát đặt riêng phía trên nút lưu.
class TransactionEntryForm extends StatelessWidget {
  const TransactionEntryForm({
    required this.initialAmount,
    required this.noteController,
    required this.isIncome,
    required this.onIncomeChanged,
    required this.date,
    required this.onDateChanged,
    required this.images,
    required this.onPickImage,
    required this.onDeleteImage,
    required this.categorySection,
    this.titleField,
    this.beforeAmount = const [],
    this.afterAmount = const [],
    this.mediaSections = const [],
    this.onSideChanged,
    this.dateStyle = AppDatePickerStyle.card,
    this.amountVariant = FormAmountFieldVariant.prominent,
    this.amountAlwaysShowKeypad = false,
    this.amountAutofocus = false,
    this.amountErrorText,
    this.amountKeypadOpen = false,
    this.onAmountTap,
    this.onAmountDone,
    this.imageThumbnailHeight = 80,
    this.showReceiptCamera,
    super.key,
  });

  /// Mặc định theo [AttachmentCapturePolicy] (mobile: chụp+chọn, desktop/web: chọn).
  final bool? showReceiptCamera;

  final int initialAmount;
  final TextEditingController noteController;
  final bool isIncome;
  final ValueChanged<bool> onIncomeChanged;
  final VoidCallback? onSideChanged;
  final FormAmountFieldVariant amountVariant;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final AppDatePickerStyle dateStyle;
  final List<ImageAttachmentModel> images;
  final ValueChanged<ImageSource> onPickImage;
  final ValueChanged<ImageAttachmentModel> onDeleteImage;
  final Widget categorySection;
  final Widget? titleField;
  final List<Widget> beforeAmount;
  final List<Widget> afterAmount;
  final List<Widget> mediaSections;
  final bool amountAlwaysShowKeypad;
  final bool amountAutofocus;
  final String? amountErrorText;
  final bool amountKeypadOpen;
  final VoidCallback? onAmountTap;
  final VoidCallback? onAmountDone;
  final double imageThumbnailHeight;

  bool get _showReceiptCamera =>
      showReceiptCamera ?? AttachmentCapturePolicy.showReceiptCameraButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...beforeAmount,
        if (titleField != null) ...[
          titleField!,
          const SizedBox(height: AppSpacing.sm),
        ],
        TransactionTypeToggle(
          isIncome: isIncome,
          onChanged: (income) {
            onIncomeChanged(income);
            onSideChanged?.call();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        FormAmountField(
          variant: amountVariant,
          initialAmount: initialAmount,
          isIncome: isIncome,
          alwaysShowKeypad: amountAlwaysShowKeypad,
          autofocus: amountAutofocus,
          errorText: amountErrorText,
          keypadOpen: amountKeypadOpen,
          onTap: onAmountTap,
          onDone: onAmountDone,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...afterAmount,
        categorySection,
        const SizedBox(height: AppSpacing.sm),
        AppDatePicker(
          date: date,
          style: dateStyle,
          onDateChanged: onDateChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: noteController,
          labelText: context.l10n.noteOptional,
          maxLines: 2,
        ),
        if (mediaSections.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ...mediaSections,
        ],
        const SizedBox(height: AppSpacing.sm),
        TransactionImageAttachments(
          images: images,
          showCamera: _showReceiptCamera,
          onPick: onPickImage,
          onDelete: onDeleteImage,
          thumbnailHeight: imageThumbnailHeight,
        ),
      ],
    );
  }
}

/// Toggle chờ đối soát — đặt ngay trên nút lưu giao dịch.
class TransactionPendingSwitch extends StatelessWidget {
  const TransactionPendingSwitch({
    required this.pending,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  final bool pending;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.l10n.pending),
      subtitle: Text(
        subtitle ?? context.l10n.pendingSubtitleDefault,
      ),
      value: pending,
      onChanged: onChanged,
    );
  }
}
