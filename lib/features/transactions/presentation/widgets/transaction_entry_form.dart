import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";

import "../../../../core/amount_input.dart";
import "../../../../core/strings.dart";
import "../../../../core/widgets/app_text_field.dart";
import "../../../../core/widgets/form_amount_field.dart";
import "../../../image_attachment/domain/image_attachment_model.dart";
import "../../../../core/widgets/app_date_picker.dart";
import "transaction_image_attachments.dart";
import "transaction_type_toggle.dart";

/// Shared fields for quick entry and full transaction editor sheets.
class TransactionEntryForm extends StatelessWidget {
  const TransactionEntryForm({
    required this.amountController,
    required this.noteController,
    required this.isIncome,
    required this.onIncomeChanged,
    required this.date,
    required this.onDateChanged,
    required this.pending,
    required this.onPendingChanged,
    required this.images,
    required this.showCamera,
    required this.onPickImage,
    required this.onDeleteImage,
    required this.categorySection,
    this.titleField,
    this.beforeAmount = const [],
    this.afterAmount = const [],
    this.mediaSections = const [],
    this.onSideChanged,
    this.showSelectedIcon = true,
    this.dateStyle = AppDatePickerStyle.card,
    this.pendingSubtitle,
    this.amountAlwaysShowKeypad = false,
    this.amountAutofocus = false,
    this.typeToggleFirst = false,
    this.imageThumbnailHeight = 80,
    super.key,
  });

  final AmountInputController amountController;
  final TextEditingController noteController;
  final bool isIncome;
  final ValueChanged<bool> onIncomeChanged;
  final VoidCallback? onSideChanged;
  final bool showSelectedIcon;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final AppDatePickerStyle dateStyle;
  final bool pending;
  final ValueChanged<bool> onPendingChanged;
  final String? pendingSubtitle;
  final List<ImageAttachmentModel> images;
  final bool showCamera;
  final ValueChanged<ImageSource> onPickImage;
  final ValueChanged<ImageAttachmentModel> onDeleteImage;
  final Widget categorySection;
  final Widget? titleField;
  final List<Widget> beforeAmount;
  final List<Widget> afterAmount;
  final List<Widget> mediaSections;
  final bool amountAlwaysShowKeypad;
  final bool amountAutofocus;
  final bool typeToggleFirst;
  final double imageThumbnailHeight;

  Widget _typeToggle() {
    return TransactionTypeToggle(
      isIncome: isIncome,
      showSelectedIcon: showSelectedIcon,
      onChanged: (income) {
        onIncomeChanged(income);
        onSideChanged?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final toggle = _typeToggle();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...beforeAmount,
        if (typeToggleFirst) ...[toggle, const SizedBox(height: 14)],
        if (titleField != null) ...[titleField!, const SizedBox(height: 12)],
        FormAmountField(
          controller: amountController,
          alwaysShowKeypad: amountAlwaysShowKeypad,
          autofocus: amountAutofocus,
        ),
        const SizedBox(height: 12),
        ...afterAmount,
        if (!typeToggleFirst) ...[toggle, const SizedBox(height: 12)],
        categorySection,
        const SizedBox(height: 12),
        AppDatePicker(
          date: date,
          style: dateStyle,
          onDateChanged: onDateChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(AppStrings.pending),
          subtitle: Text(
            pendingSubtitle ??
                "Bật nếu cần xem lại giao dịch này sau.",
          ),
          value: pending,
          onChanged: onPendingChanged,
        ),
        const SizedBox(height: 4),
        AppTextField(
          controller: noteController,
          labelText: AppStrings.noteOptional,
          maxLines: 2,
        ),
        ...mediaSections,
        const SizedBox(height: 10),
        TransactionImageAttachments(
          images: images,
          showCamera: showCamera,
          onPick: onPickImage,
          onDelete: onDeleteImage,
          thumbnailHeight: imageThumbnailHeight,
        ),
      ],
    );
  }
}
