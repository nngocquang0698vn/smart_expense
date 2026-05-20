import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/components/app_text_field.dart";
import "package:smart_expense/shared/components/form_amount_field.dart";
import "package:smart_expense/shared/design_system/design_system.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/shared/components/app_date_picker.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_image_attachments.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_type_toggle.dart";

/// Shared fields for quick entry and full transaction editor sheets.
class TransactionEntryForm extends StatelessWidget {
  const TransactionEntryForm({
    required this.initialAmount,
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
    this.amountErrorText,
    this.amountKeypadOpen = false,
    this.onAmountTap,
    this.onAmountDone,
    this.typeToggleFirst = false,
    this.imageThumbnailHeight = 80,
    super.key,
  });

  final int initialAmount;
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
  final String? amountErrorText;
  final bool amountKeypadOpen;
  final VoidCallback? onAmountTap;
  final VoidCallback? onAmountDone;
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
        if (typeToggleFirst) ...[toggle, const SizedBox(height: AppSpacing.sm)],
        if (titleField != null) ...[
          titleField!,
          const SizedBox(height: AppSpacing.sm),
        ],
        FormAmountField(
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
        if (!typeToggleFirst) ...[
          toggle,
          const SizedBox(height: AppSpacing.sm),
        ],
        categorySection,
        const SizedBox(height: AppSpacing.sm),
        AppDatePicker(
          date: date,
          style: dateStyle,
          onDateChanged: onDateChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.pending),
          subtitle: Text(
            pendingSubtitle ?? "Bật nếu cần xem lại giao dịch này sau.",
          ),
          value: pending,
          onChanged: onPendingChanged,
        ),
        const SizedBox(height: AppSpacing.xxs),
        AppTextField(
          controller: noteController,
          labelText: context.l10n.noteOptional,
          maxLines: 2,
        ),
        if (mediaSections.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          ...mediaSections,
        ],
        const SizedBox(height: AppSpacing.xs),
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
