import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/features/sms/domain/entities/iranian_bank_registry.dart';
import 'package:siaheh/presentation/bloc/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance_event.dart';
import 'package:siaheh/presentation/mapper/finance_mapper.dart';
import 'package:siaheh/presentation/models/finance_ui_models.dart';
import 'package:siaheh/presentation/widgets/bank_logo.dart';
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
  String? _bankFilter;
  bool _searching = false;
  final TextEditingController _search = TextEditingController();

  static const Map<_Filter, String> _labels = {
    _Filter.all: 'همه',
    _Filter.income: 'واریز',
    _Filter.expense: 'برداشت',
    _Filter.transfer: 'انتقال',
    _Filter.review: 'نیازمند بررسی',
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BankTransaction> _filtered(FinanceMapper mapper) {
    final query = _search.text.trim().toLowerCase();
    return mapper.activeTransactions.where((t) {
      final bankKey = mapper.resolveBankKey(t);
      if (_bankFilter != null && bankKey != _bankFilter) {
        return false;
      }
      final matchesType = switch (_filter) {
        _Filter.all => true,
        _Filter.income => t.type == TransactionType.income,
        _Filter.expense => t.type == TransactionType.expense,
        _Filter.transfer => t.type == TransactionType.transfer,
        _Filter.review => t.needsReview,
      };
      if (!matchesType) return false;
      if (query.isNotEmpty) {
        final inTitle = (t.title ?? '').toLowerCase().contains(query);
        final inBank = IranianBankRegistry.byKey(bankKey)
            .name
            .toLowerCase()
            .contains(query);
        final inBody = t.rawBody.toLowerCase().contains(query);
        if (!inTitle && !inBank && !inBody) return false;
      }
      return true;
    }).toList(growable: false);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final FinanceMapper mapper = FinanceMapper(context.watch<FinanceBloc>().state);
    final List<UiBank> banks = mapper.detectedBanks;
    final List<BankTransaction> items = _filtered(mapper);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'تراکنش‌ها',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: () {
                    setState(() {
                      _searching = !_searching;
                      if (!_searching) _search.clear();
                    });
                  },
                  icon: Icon(
                    _searching ? Icons.close_rounded : Icons.search_rounded,
                  ),
                ),
              ],
            ),
          ),
          if (_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'جستجو در عنوان، بانک یا متن پیامک...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          if (banks.length > 1)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: const Text('همه بانک‌ها'),
                      selected: _bankFilter == null,
                      onSelected: (_) => setState(() => _bankFilter = null),
                    ),
                  ),
                  for (final UiBank b in banks)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        avatar: BankLogo(bankKey: b.key, size: 22),
                        label: Text(b.name),
                        selected: _bankFilter == b.key,
                        onSelected: (_) => setState(() => _bankFilter = b.key),
                      ),
                    ),
                ],
              ),
            ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<FinanceBloc>().add(const FinanceSyncRequested());
              },
              child: items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Text(
                            'تراکنشی یافت نشد',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final BankTransaction raw = items[i];
                        final UiTransaction tx = mapper.toUi(raw);
                        final bool newDay =
                            i == 0 ||
                            !_isSameDay(items[i - 1].occurredAt, raw.occurredAt);
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
          ),
        ],
      ),
    );
  }
}
