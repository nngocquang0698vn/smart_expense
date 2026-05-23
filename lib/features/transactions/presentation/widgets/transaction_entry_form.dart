import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:smart_expense/core/utils/attachment_capture_policy.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/shared/components/form_amount_field.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_note_input.dart";
import "package:smart_expense/shared/design_system/design_system.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/shared/components/app_date_picker.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_image_attachments.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_type_toggle.dart";

/// Khoảng cách giữa các khối trong form giao dịch.
enum TransactionFormDensity { comfortable, compact }

/// Shared fields for quick entry and full transaction editor sheets.
///
/// Thứ tự: tiêu đề → Chi tiêu/Thu nhập → số tiền → danh mục → ngày → ghi chú+ghi âm
/// → ảnh. Toggle chờ đối soát đặt riêng phía trên nút lưu.
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
    required this.onAudioChanged,
    required this.categorySection,
    this.audio,
    this.titleField,
    this.beforeAmount = const [],
    this.afterAmount = const [],
    this.onSideChanged,
    this.autoStartVoiceRecording = false,
    this.onDismissAmountKeypad,
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
    this.density = TransactionFormDensity.comfortable,
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
  final AudioAttachmentModel? audio;
  final ValueChanged<AudioAttachmentModel?> onAudioChanged;
  final bool autoStartVoiceRecording;
  final VoidCallback? onDismissAmountKeypad;
  final Widget categorySection;
  final Widget? titleField;
  final List<Widget> beforeAmount;
  final List<Widget> afterAmount;
  final bool amountAlwaysShowKeypad;
  final bool amountAutofocus;
  final String? amountErrorText;
  final bool amountKeypadOpen;
  final VoidCallback? onAmountTap;
  final VoidCallback? onAmountDone;
  final double imageThumbnailHeight;
  final TransactionFormDensity density;

  bool get _showReceiptCamera =>
      showReceiptCamera ?? AttachmentCapturePolicy.showReceiptCameraButton;

  double get _sectionGap =>
      density == TransactionFormDensity.compact
          ? AppSpacing.xs
          : AppSpacing.sm;

  bool get _compact => density == TransactionFormDensity.compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...beforeAmount,
        if (titleField != null) ...[
          titleField!,
          SizedBox(height: _sectionGap),
        ],
        TransactionTypeToggle(
          isIncome: isIncome,
          onChanged: (income) {
            onIncomeChanged(income);
            onSideChanged?.call();
          },
        ),
        SizedBox(height: _sectionGap),
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
          compact: _compact,
        ),
        SizedBox(height: _sectionGap),
        ...afterAmount,
        categorySection,
        SizedBox(height: _sectionGap),
        AppDatePicker(
          date: date,
          style: dateStyle,
          onDateChanged: onDateChanged,
        ),
        SizedBox(height: _sectionGap),
        TransactionNoteInput(
          noteController: noteController,
          audio: audio,
          onAudioChanged: onAudioChanged,
          autoStartRecording: autoStartVoiceRecording,
          amountKeypadOpen: amountKeypadOpen,
          onDismissAmountKeypad: onDismissAmountKeypad,
        ),
        SizedBox(height: _sectionGap),
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
