import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
import 'package:siaheh/core/utils/persian_format.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';
import 'package:siaheh/domain/entities/iranian_bank_registry.dart';
import 'package:siaheh/presentation/bloc/finance/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance/finance_event.dart';
import 'package:siaheh/presentation/bloc/finance/finance_mapper.dart';
import 'package:siaheh/presentation/bloc/finance/finance_ui_models.dart';
import 'package:siaheh/presentation/widgets/bank_logo.dart';
import 'package:siaheh/presentation/widgets/filter_sheets.dart';
import 'package:siaheh/presentation/widgets/jalali_period_picker.dart';
import 'package:siaheh/presentation/widgets/transaction_edit_sheet.dart';
import 'package:siaheh/presentation/widgets/transaction_tile.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({
    super.key,
    this.categoryFilter,
    this.externalDateFilter,
    this.externalDateFilterVersion = 0,
    this.onCategoryFilterChanged,
  });

  final String? categoryFilter;
  final JalaliDateFilter? externalDateFilter;
  final int externalDateFilterVersion;
  final ValueChanged<String?>? onCategoryFilterChanged;

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  late TransactionTypeFilter _filter = widget.categoryFilter != null
      ? TransactionTypeFilter.expense
      : TransactionTypeFilter.all;
  late JalaliDateFilter _dateFilter =
      widget.externalDateFilter ?? const JalaliDateFilter.all();
  String? _bankFilter;
  bool _searching = false;
  final TextEditingController _search = TextEditingController();

  @override
  void didUpdateWidget(covariant TransactionsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryFilter != null &&
        widget.categoryFilter != oldWidget.categoryFilter) {
      // When drilling down from the expense chart, show expenses for that category.
      _filter = TransactionTypeFilter.expense;
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

  Future<void> _openFilterSheet(FinanceMapper mapper) async {
    final int reviewCount =
        mapper.activeTransactions.where((t) => t.needsReview).length;
    final TransactionFilterSelection? picked = await showTransactionFilterSheet(
      context: context,
      initial: TransactionFilterSelection(
        type: _filter,
        bankKey: _bankFilter,
        categoryName: widget.categoryFilter,
        dateFilter: _dateFilter,
      ),
      banks: mapper.detectedBanks,
      categories: mapper.allCategories,
      countsByYearMonth: mapper.transactionCountsByYearMonth,
      reviewCount: reviewCount,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _filter = picked.type;
      _bankFilter = picked.bankKey;
      _dateFilter = picked.dateFilter;
    });
    if (picked.categoryName != widget.categoryFilter) {
      widget.onCategoryFilterChanged?.call(picked.categoryName);
    }
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

  void _clearAllFilters() {
    setState(() {
      _filter = TransactionTypeFilter.all;
      _bankFilter = null;
      _dateFilter = const JalaliDateFilter.all();
    });
    widget.onCategoryFilterChanged?.call(null);
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
        TransactionTypeFilter.all => true,
        TransactionTypeFilter.income => t.type == TransactionType.income,
        TransactionTypeFilter.expense => t.type == TransactionType.expense,
        TransactionTypeFilter.transfer => t.type == TransactionType.transfer,
        TransactionTypeFilter.review => t.needsReview,
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
    final FinanceMapper mapper = FinanceMapper.of(
      context.watch<FinanceBloc>().state,
    );
    final List<BankTransaction> items = _filtered(mapper);
    final UiCategory? activeCategoryUi = widget.categoryFilter == null
        ? null
        : mapper.categoryOf(widget.categoryFilter);
    final int activeFilterCount =
        (_filter != TransactionTypeFilter.all ? 1 : 0) +
        (_bankFilter != null ? 1 : 0) +
        (activeCategoryUi != null ? 1 : 0) +
        (_dateFilter.isActive ? 1 : 0);
    final bool hasSummaryFilter = activeFilterCount > 0;

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
                GlassBackdropGroup(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilterActionButton(
                        activeCount: activeFilterCount,
                        onTap: () => _openFilterSheet(mapper),
                      ),
                      const SizedBox(width: 8),
                      GlassButton.custom(
                        useOwnLayer: true,
                        quality: GlassQuality.standard,
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
          if (_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GlassSearchBar(
                controller: _search,
                autofocus: true,
                useOwnLayer: true,
                quality: GlassQuality.standard,
                settings: SiahehGlass.inputSettings(theme.brightness),
                placeholder: 'جستجو در عنوان، پذیرنده، بانک یا متن پیامک...',
                searchIconColor: scheme.onSurface.withValues(alpha: 0.65),
                clearIconColor: scheme.onSurface.withValues(alpha: 0.65),
                textStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                ),
                placeholderStyle: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.52),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          if (activeFilterCount > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: GlassBackdropGroup(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (activeCategoryUi != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SiahehGlassChip(
                            selected: true,
                            accentColor: activeCategoryUi.color,
                            icon: Icon(
                              activeCategoryUi.icon,
                              size: 16,
                              color: activeCategoryUi.color,
                            ),
                            label: activeCategoryUi.name,
                            onTap: () => _openFilterSheet(mapper),
                            onDeleted: () {
                              widget.onCategoryFilterChanged?.call(null);
                              if (_filter == TransactionTypeFilter.expense &&
                                  _bankFilter == null &&
                                  !_dateFilter.isActive) {
                                setState(
                                  () => _filter = TransactionTypeFilter.all,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    if (_filter != TransactionTypeFilter.all)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SiahehGlassChip(
                            selected: true,
                            label: _filter.label,
                            onTap: () => _openFilterSheet(mapper),
                            onDeleted: () => setState(
                              () => _filter = TransactionTypeFilter.all,
                            ),
                          ),
                        ),
                      ),
                    if (_bankFilter != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SiahehGlassChip(
                            selected: true,
                            icon: BankLogo(bankKey: _bankFilter!, size: 18),
                            label: FinanceMapper.bank(_bankFilter!).name,
                            onTap: () => _openFilterSheet(mapper),
                            onDeleted: () =>
                                setState(() => _bankFilter = null),
                          ),
                        ),
                      ),
                    if (_dateFilter.isActive)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: JalaliDateFilterChip(
                            filter: _dateFilter,
                            onTap: () => _openDateFilterPicker(mapper),
                            onClear: () => setState(
                              () => _dateFilter = const JalaliDateFilter.all(),
                            ),
                          ),
                        ),
                      ),
                    if (activeFilterCount >= 2)
                      Center(
                        child: SiahehGlassChip(
                          selected: false,
                          icon: Icon(
                            Icons.clear_all_rounded,
                            size: 16,
                            color: scheme.onSurface.withValues(alpha: 0.78),
                          ),
                          label: 'پاک کردن همه',
                          onTap: _clearAllFilters,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (hasSummaryFilter && items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SiahehGlassCard(
                radius: 16,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
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
