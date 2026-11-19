import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/presentation/bloc/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance_event.dart';
import 'package:siaheh/presentation/models/finance_ui_models.dart';

/// Bottom sheet to inspect raw SMS and correct or delete a parsed transaction.
Future<void> showTransactionEditSheet(BuildContext context, UiTransaction tx) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TransactionEditSheet(tx: tx),
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
  late final TextEditingController _title = TextEditingController(
    text: widget.tx.title,
  );
  late final TextEditingController _amount = TextEditingController(
    text: '${widget.tx.amountRial ~/ 10}',
  );

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
      ),
    );
    Navigator.pop(context);
  }

  void _delete() {
    context.read<FinanceBloc>().add(FinanceTransactionDeleted(widget.tx.id));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ویرایش تراکنش', style: theme.textTheme.titleLarge),
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
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<UiTxType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: UiTxType.expense, label: Text('برداشت')),
                  ButtonSegment(value: UiTxType.income, label: Text('واریز')),
                  ButtonSegment(value: UiTxType.transfer, label: Text('انتقال')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
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
                for (final UiCategory c in AppCategories.all)
                  ChoiceChip(
                    selected: c == _category,
                    onSelected: (_) => setState(() => _category = c),
                    avatar: Icon(c.icon, size: 18, color: c.color),
                    label: Text(c.name),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                IconButton.outlined(
                  tooltip: 'حذف تراکنش',
                  onPressed: _delete,
                  color: scheme.error,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('ذخیره تغییرات'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
