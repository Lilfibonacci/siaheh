import 'package:flutter/material.dart';
import 'package:siaheh/presentation/mock/mock_data.dart';
import 'package:siaheh/presentation/mock/ui_models.dart';
import 'package:siaheh/presentation/widgets/transaction_edit_sheet.dart';
import 'package:siaheh/presentation/widgets/transaction_tile.dart';

enum _Filter { all, income, expense, transfer, review }

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  _Filter _filter = _Filter.all;

  static const Map<_Filter, String> _labels = {
    _Filter.all: 'همه',
    _Filter.income: 'واریز',
    _Filter.expense: 'برداشت',
    _Filter.transfer: 'انتقال',
    _Filter.review: 'نیازمند بررسی',
  };

  List<UiTransaction> get _items => MockData.transactions.where((t) {
    return switch (_filter) {
      _Filter.all => true,
      _Filter.income => t.type == UiTxType.income,
      _Filter.expense => t.type == UiTxType.expense,
      _Filter.transfer => t.type == UiTxType.transfer,
      _Filter.review => t.needsReview,
    };
  }).toList();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<UiTransaction> items = _items;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Expanded(child: Text('تراکنش‌ها', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
                IconButton.outlined(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _Filter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final _Filter f = _Filter.values[i];
                return ChoiceChip(
                  label: Text(_labels[f]!),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                );
              },
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'تراکنشی یافت نشد',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final UiTransaction tx = items[i];
                      final bool newDay = i == 0 || items[i - 1].dateLabel != tx.dateLabel;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (newDay)
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 8),
                              child: Text(
                                tx.dateLabel,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TransactionTile(
                              transaction: tx,
                              onTap: () => showTransactionEditSheet(context, tx),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
