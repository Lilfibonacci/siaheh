import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
import 'package:siaheh/core/utils/persian_format.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/features/sms/domain/entities/iranian_bank_registry.dart';
import 'package:siaheh/presentation/bloc/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance_event.dart';
import 'package:siaheh/presentation/mapper/finance_mapper.dart';
import 'package:siaheh/presentation/models/finance_ui_models.dart';
import 'package:siaheh/presentation/widgets/bank_logo.dart';
import 'package:siaheh/presentation/widgets/jalali_period_picker.dart';
import 'package:siaheh/presentation/widgets/transaction_edit_sheet.dart';
import 'package:siaheh/presentation/widgets/transaction_tile.dart';

enum _Filter { all, income, expense, transfer, review }

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({
    super.key,
    this.categoryFilter,
    this.externalDateFilter,
    this.externalDateFilterVersion = 0,
    this.onClearCategoryFilter,
  });

  final String? categoryFilter;
  final JalaliDateFilter? externalDateFilter;
  final int externalDateFilterVersion;
  final VoidCallback? onClearCategoryFilter;

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  late _Filter _filter =
      widget.categoryFilter != null ? _Filter.expense : _Filter.all;
  late JalaliDateFilter _dateFilter =
      widget.externalDateFilter ?? const JalaliDateFilter.all();
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
  void didUpdateWidget(covariant TransactionsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryFilter != null &&
        widget.categoryFilter != oldWidget.categoryFilter) {
      // When drilling down from the expense chart, show expenses for that category.
      _filter = _Filter.expense;
    }
    if (widget.externalDateFilterVersion !=
            oldWidget.externalDateFilterVersion &&
        widget.externalDateFilter != null) {
      _dateFilter = widget.externalDateFilter!;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openDateFilterPicker(FinanceMapper mapper) async {
    final JalaliDateFilter? picked = await showJalaliPeriodPickerSheet(
      context: context,
      title: 'فیلتر زمانی تراکنش‌ها',
      initialFilter: _dateFilter,
      countsByYearMonth: mapper.transactionCountsByYearMonth,
      allowAll: true,
      allowWholeYear: true,
      allowQuickRanges: true,
      itemUnitLabel: 'تراکنش',
    );
    if (picked != null && mounted) {
      setState(() => _dateFilter = picked);
    }
  }

  List<BankTransaction> _filtered(FinanceMapper mapper) {
    final query = _search.text.trim().toLowerCase();
    final activeCategory = widget.categoryFilter;
    final (DateTime? start, DateTime? end) = _dateFilter.bounds();

    return mapper.activeTransactions.where((t) {
      if (start != null && t.occurredAt.isBefore(start)) return false;
      if (end != null && !t.occurredAt.isBefore(end)) return false;

      final bankKey = mapper.resolveBankKey(t);
      if (_bankFilter != null && bankKey != _bankFilter) {
        return false;
      }
      if (activeCategory != null) {
        final catName = mapper.categoryOf(t.categoryId).name;
        if (catName != activeCategory) return false;
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
        final inMerchant = (t.merchantName ?? '').toLowerCase().contains(query);
        final inBank = IranianBankRegistry.byKey(bankKey)
            .name
            .toLowerCase()
            .contains(query);
        final inBody = t.rawBody.toLowerCase().contains(query);
        if (!inTitle && !inMerchant && !inBank && !inBody) return false;
      }
      return true;
    }).toList(growable: false);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final FinanceMapper mapper = FinanceMapper(context.watch<FinanceBloc>().state);
    final List<UiBank> banks = mapper.detectedBanks;
    final List<BankTransaction> items = _filtered(mapper);
    final UiCategory? activeCategoryUi = widget.categoryFilter == null
        ? null
        : mapper.categoryOf(widget.categoryFilter);
    final bool hasSummaryFilter =
        _dateFilter.isActive || activeCategoryUi != null || _bankFilter != null;

    var filteredExpenseRial = 0;
    var filteredIncomeRial = 0;
    if (hasSummaryFilter && items.isNotEmpty) {
      for (final t in items) {
        if (t.type == TransactionType.expense) {
          filteredExpenseRial += t.amountRial;
        } else if (t.type == TransactionType.income) {
          filteredIncomeRial += t.amountRial;
        }
      }
    }

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
                AdaptiveLiquidGlassLayer(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassButton.custom(
                        width: 44,
                        height: 44,
                        stretch: 0.15,
                        label: 'فیلتر زمانی',
                        onTap: () => _openDateFilterPicker(mapper),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: _dateFilter.isActive
                              ? scheme.primary
                              : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GlassButton.custom(
                        width: 44,
                        height: 44,
                        stretch: 0.15,
                        label: _searching ? 'بستن جستجو' : 'جستجو',
                        onTap: () {
                          setState(() {
                            _searching = !_searching;
                            if (!_searching) _search.clear();
                          });
                        },
                        child: Icon(
                          _searching
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          size: 21,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (activeCategoryUi != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
              child: InputChip(
                avatar: Icon(
                  activeCategoryUi.icon,
                  size: 18,
                  color: activeCategoryUi.color,
                ),
                label: Text('دسته: ${activeCategoryUi.name}'),
                onDeleted: () {
                  setState(() => _filter = _Filter.all);
                  widget.onClearCategoryFilter?.call();
                },
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
                  hintText: 'جستجو در عنوان، پذیرنده، بانک یا متن پیامک...',
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
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                JalaliDateFilterChip(
                  filter: _dateFilter,
                  onTap: () => _openDateFilterPicker(mapper),
                  onClear: _dateFilter.isActive
                      ? () => setState(
                          () => _dateFilter = const JalaliDateFilter.all(),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                for (final _Filter f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(_labels[f]!),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          if (hasSummaryFilter && items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: SiahehGlass.frostedRowDecoration(
                  context,
                  radius: 16,
                ),
                child: Row(
                  children: [
                    Text(
                      PersianFormat.digits('${items.length} تراکنش'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (filteredExpenseRial > 0)
                              Text(
                                'برداشت: ${PersianFormat.toman(filteredExpenseRial)} ت',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (filteredExpenseRial > 0 &&
                                filteredIncomeRial > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Text(
                                  '•',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                            if (filteredIncomeRial > 0)
                              Text(
                                'واریز: ${PersianFormat.toman(filteredIncomeRial)} ت',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        SiahehGlass.floatingNavBottomInset,
                      ),
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
