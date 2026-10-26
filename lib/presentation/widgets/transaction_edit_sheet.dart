import 'package:flutter/material.dart';
import 'package:siaheh/core/theme/app_colors.dart';
import 'package:siaheh/presentation/mock/mock_data.dart';
import 'package:siaheh/presentation/mock/ui_models.dart';
import 'package:siaheh/presentation/widgets/bank_logo.dart';

/// Bottom sheet to correct a parsed transaction (UI only).
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
  late UiAccount _account = MockData.accounts.firstWhere(
    (a) => a.bank.key == widget.tx.account.bank.key,
    orElse: () => MockData.accounts.first,
  );

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
              initialValue: widget.tx.amountRial ~/ 10 == 0 ? '' : '${widget.tx.amountRial ~/ 10}',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ (تومان)',
                prefixIcon: Icon(Icons.payments_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.tx.title,
              decoration: const InputDecoration(
                labelText: 'عنوان',
                prefixIcon: Icon(Icons.edit_note_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('حساب', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockData.accounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final UiAccount a = MockData.accounts[i];
                  return ChoiceChip(
                    selected: a == _account,
                    onSelected: (_) => setState(() => _account = a),
                    avatar: BankLogo(bankKey: a.bank.key, size: 24),
                    label: Text(a.bank.name),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('دسته‌بندی', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final UiCategory c in MockData.categories)
                  ChoiceChip(
                    selected: c == _category,
                    onSelected: (_) => setState(() => _category = c),
                    avatar: Icon(c.icon, size: 18, color: c.color),
                    label: Text(c.name),
                  ),
                ActionChip(
                  avatar: Icon(Icons.add_rounded, size: 18, color: AppColors.transfer(theme.brightness)),
                  label: const Text('دسته جدید'),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                IconButton.outlined(
                  onPressed: () => Navigator.pop(context),
                  color: scheme.error,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
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
