import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/core/theme/app_colors.dart';
import 'package:siaheh/core/theme/app_fonts.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/features/sms/domain/entities/custom_category.dart';
import 'package:siaheh/presentation/bloc/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance_event.dart';
import 'package:siaheh/presentation/mapper/finance_mapper.dart';
import 'package:siaheh/presentation/models/finance_ui_models.dart';

/// Liquid Glass bottom sheet to inspect raw SMS, create custom categories,
/// learn rules for similar transactions, and edit or delete a parsed transaction.
Future<void> showTransactionEditSheet(BuildContext context, UiTransaction tx) {
  final ThemeData capturedTheme = Theme.of(context);
  final FinanceBloc capturedBloc = context.read<FinanceBloc>();

  return GlassSheet.show<void>(
    context: context,
    settings: SiahehGlass.sheetSettings(capturedTheme.brightness),
    topBorderRadius: 34,
    margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
    isScrollable: true,
    interactionScale: 1.0,
    stretch: 0.12,
    enableInteractionGlow: false,
    enableSaturationGlow: false,
    suppressInteractionOnChildren: true,
    dragIndicatorColor: capturedTheme.colorScheme.onSurface.withValues(
      alpha: 0.28,
    ),
    builder: (_) => BlocProvider.value(
      value: capturedBloc,
      child: Theme(
        data: capturedTheme,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            type: MaterialType.transparency,
            child: _TransactionEditSheet(tx: tx),
          ),
        ),
      ),
    ),
  );
}

class _TransactionEditSheet extends StatefulWidget {
  const _TransactionEditSheet({required this.tx});

  final UiTransaction tx;

  @override
  State<_TransactionEditSheet> createState() => _TransactionEditSheetState();
}

class _TransactionEditSheetState extends State<_TransactionEditSheet> {
  late UiTxType _type = widget.tx.type;
  late UiCategory _category = widget.tx.category;
  bool _applyToSimilar = true;
  late final TextEditingController _title = TextEditingController(
    text: widget.tx.title,
  );
  late final TextEditingController _amount = TextEditingController(
    text: '${widget.tx.amountRial ~/ 10}',
  );

  static const Set<String> _genericTitles = {
    'برداشت از حساب',
    'واریز به حساب',
    'انتقال بین حساب‌ها',
    'خرید فروشگاهی',
  };

  bool get _canLearnRule {
    final hasMerchant =
        widget.tx.merchantName != null && widget.tx.merchantName!.trim().length >= 2;
    final trimmedTitle = _title.text.trim();
    final hasSpecificTitle =
        trimmedTitle.length >= 2 && !_genericTitles.contains(trimmedTitle);
    return hasMerchant || hasSpecificTitle;
  }

  String get _learnLabel {
    final target = widget.tx.merchantName ?? _title.text.trim();
    return 'اعمال روی تراکنش‌های مشابه «$target» و یادگیری برای آینده';
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final bloc = context.read<FinanceBloc>();
    final BankTransaction? original = bloc.state.transactions
        .where((t) => t.id == widget.tx.id)
        .firstOrNull;
    if (original == null) return;
    final toman = int.tryParse(_amount.text.replaceAll(',', '').trim());
    final newType = switch (_type) {
      UiTxType.income => TransactionType.income,
      UiTxType.expense => TransactionType.expense,
      UiTxType.transfer => TransactionType.transfer,
    };
    bloc.add(
      FinanceTransactionUpdated(
        original.copyWith(
          type: newType,
          amountRial: toman == null ? null : toman * 10,
          title: _title.text.trim().isEmpty ? null : _title.text.trim(),
          categoryId: _category.name,
          needsReview: false,
          clearLinkedTransfer: newType != TransactionType.transfer,
          userEdited: true,
        ),
        applyToSimilar: _canLearnRule && _applyToSimilar,
      ),
    );
    Navigator.pop(context);
  }

  void _delete() {
    context.read<FinanceBloc>().add(FinanceTransactionDeleted(widget.tx.id));
    Navigator.pop(context);
  }

  Future<void> _openCreateCategoryDialog() async {
    final CustomCategory? created = await showDialog<CustomCategory>(
      context: context,
      builder: (_) => const _CreateCategoryDialog(),
    );
    if (created == null || !mounted) return;
    context.read<FinanceBloc>().add(FinanceCustomCategoryAdded(created));
    setState(() {
      _category = AppCategories.fromCustom(created);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<UiCategory> categories =
        FinanceMapper.of(context.watch<FinanceBloc>().state).allCategories;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text('ویرایش تراکنش', style: theme.textTheme.titleLarge),
            if (widget.tx.merchantName != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: scheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'پذیرنده شناسایی‌شده: ${widget.tx.merchantName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.tx.rawBody.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'متن اصلی پیامک (${widget.tx.account.bank.name})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.tx.rawBody,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            GlassInteractionSilence(
              child: GlassSegmentedControl(
                useOwnLayer: true,
                height: 44,
                borderRadius: 22,
                selectedIndex: switch (_type) {
                  UiTxType.expense => 0,
                  UiTxType.income => 1,
                  UiTxType.transfer => 2,
                },
                onSegmentSelected: (idx) => setState(() {
                  _type = switch (idx) {
                    0 => UiTxType.expense,
                    1 => UiTxType.income,
                    _ => UiTxType.transfer,
                  };
                }),
                backgroundColor: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                indicatorColor: theme.brightness == Brightness.dark
                    ? scheme.primary.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.94),
                selectedTextStyle: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.brightness == Brightness.dark
                      ? scheme.primary
                      : scheme.onSurface,
                ),
                unselectedTextStyle: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.68),
                ),
                segments: const [
                  GlassSegment(label: 'برداشت'),
                  GlassSegment(label: 'واریز'),
                  GlassSegment(label: 'انتقال'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ (تومان)',
                prefixIcon: Icon(Icons.payments_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'عنوان',
                prefixIcon: Icon(Icons.edit_note_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('دسته‌بندی', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final UiCategory c in categories)
                  ChoiceChip(
                    selected: c == _category,
                    onSelected: (_) => setState(() => _category = c),
                    avatar: Icon(c.icon, size: 18, color: c.color),
                    label: Text(c.name),
                  ),
                ActionChip(
                  avatar: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.transfer(theme.brightness),
                  ),
                  label: const Text('دسته جدید'),
                  onPressed: _openCreateCategoryDialog,
                ),
              ],
            ),
            if (_canLearnRule) ...[
              const SizedBox(height: 14),
              Material(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: scheme.outline),
                ),
                clipBehavior: Clip.antiAlias,
                child: CheckboxListTile(
                  value: _applyToSimilar,
                  onChanged: (v) => setState(() => _applyToSimilar = v ?? true),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    _learnLabel,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                GlassInteractionSilence(
                  child: GlassIconButton(
                    useOwnLayer: true,
                    size: 50,
                    semanticLabel: 'حذف تراکنش',
                    onPressed: _delete,
                    iconColor: scheme.error,
                    tintColor: scheme.error.withValues(alpha: 0.14),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('ذخیره تغییرات'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }
}

class _CreateCategoryDialog extends StatefulWidget {
  const _CreateCategoryDialog();

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final TextEditingController _name = TextEditingController();
  IconData _selectedIcon = AppCategories.customIconChoices.first;
  Color _selectedColor = AppCategories.customColorChoices.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('ساخت دسته‌بندی جدید'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'نام دسته',
                hintText: 'مثلاً کافه، آموزش، حیوان خانگی',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(_selectedIcon, color: _selectedColor),
              ),
            ),
            const SizedBox(height: 16),
            Text('رنگ', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final Color color in AppCategories.customColorChoices)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _selectedColor == color
                            ? Border.all(color: scheme.onSurface, width: 2.5)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('آیکون', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final IconData icon in AppCategories.customIconChoices)
                  GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedIcon == icon
                            ? _selectedColor.withValues(alpha: 0.22)
                            : scheme.surfaceContainerHighest.withValues(
                                alpha: 0.5,
                              ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedIcon == icon
                              ? _selectedColor
                              : scheme.outline,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: _selectedIcon == icon
                            ? _selectedColor
                            : scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  CustomCategory(
                    name: _name.text.trim(),
                    iconCodePoint: _selectedIcon.codePoint,
                    colorValue: _selectedColor.toARGB32(),
                  ),
                ),
          child: const Text('افزودن'),
        ),
      ],
    );
  }
}
