import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/ui/core/theme/siaheh_glass.dart';
import 'package:siaheh/ui/core/bloc/finance_bloc.dart';
import 'package:siaheh/ui/core/bloc/finance_event.dart';
import 'package:siaheh/ui/core/bloc/finance_state.dart';
import 'package:siaheh/ui/core/bloc/theme_bloc.dart';
import 'package:siaheh/ui/core/mappers/finance_mapper.dart';
import 'package:siaheh/ui/core/models/finance_ui_models.dart';
import 'package:siaheh/ui/features/home/widgets/account_card.dart';
import 'package:siaheh/ui/features/home/widgets/balance_header_card.dart';
import 'package:siaheh/ui/features/home/widgets/expense_donut.dart';
import 'package:siaheh/ui/core/widgets/jalali_period_picker.dart';
import 'package:siaheh/ui/core/widgets/section_header.dart';
import 'package:siaheh/ui/features/transactions/widgets/transaction_edit_sheet.dart';
import 'package:siaheh/ui/features/transactions/widgets/transaction_tile.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.onSeeAllTransactions,
    required this.onSeeAllMessages,
    required this.onCategorySelected,
  });

  final VoidCallback onSeeAllTransactions;
  final VoidCallback onSeeAllMessages;
  final void Function(String categoryName, JalaliDateFilter monthFilter)
      onCategorySelected;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  JalaliDateFilter _selectedMonth = JalaliDateFilter.thisMonth();
  bool _pickingMonth = false;

  Future<void> _pickCustomMonth(FinanceMapper mapper) async {
    if (_pickingMonth) return;
    _pickingMonth = true;
    try {
      final JalaliDateFilter? picked = await showJalaliPeriodPickerSheet(
        context: context,
        title: 'انتخاب ماه و سال',
        initialFilter: _selectedMonth,
        countsByYearMonth: mapper.expenseCountsByYearMonth,
        allowAll: false,
        allowWholeYear: false,
        allowQuickRanges: false,
        itemUnitLabel: 'هزینه',
      );
      if (picked != null && mounted) {
        setState(() => _selectedMonth = picked);
      }
    } finally {
      _pickingMonth = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final FinanceState state = context.watch<FinanceBloc>().state;
    final FinanceMapper m = FinanceMapper.of(state);
    final List<UiAccount> accounts = m.accounts;
    final List<UiTransaction> transactions = m.recentTransactions(5);
    final List<CategoryExpenseSlice> slices = m.expenseBreakdown(_selectedMonth);
    final int total = accounts.fold(0, (s, a) => s + a.balanceRial);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<FinanceBloc>().add(const FinanceSyncRequested());
        },
        child: ListView(
          padding: const EdgeInsets.only(
            bottom: SiahehGlass.floatingNavBottomInset,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  SiahehGlassCard(
                    width: 46,
                    height: 46,
                    shape: const LiquidOval(),
                    borderColor: theme.colorScheme.primary.withValues(
                      alpha: 0.35,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سیاهه',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          m.currentJalaliMonthLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.62,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassButton.custom(
                    useOwnLayer: true,
                    width: 44,
                    height: 44,
                    stretch: 0.15,
                    label: theme.brightness == Brightness.dark
                        ? 'تغییر به حالت روشن'
                        : 'تغییر به حالت تیره',
                    onTap: () => context.read<ThemeBloc>().add(
                      ThemeToggled(currentBrightness: theme.brightness),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        theme.brightness == Brightness.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        key: ValueKey(theme.brightness),
                        size: 21,
                        color: theme.brightness == Brightness.dark
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!state.hasPermission)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SiahehPrimaryGlassButton(
                  onTap: () => context.read<FinanceBloc>().add(
                    const FinancePermissionRequested(),
                  ),
                  icon: Icons.lock_open_rounded,
                  label: 'دادن دسترسی پیامک برای تشخیص خودکار بانک‌ها',
                ),
              ),
            BalanceHeaderCard(
              totalRial: total,
              incomeRial: m.monthIncome,
              expenseRial: m.monthExpense,
            ),
            SectionHeader(
              title: 'حساب‌های من',
              actionLabel: 'پیامک‌ها',
              onAction: widget.onSeeAllMessages,
            ),
            if (accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SiahehGlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'هنوز حساب بانکی شناسایی نشده است. پس از دادن دسترسی پیامک، تمام بانک‌های شما به صورت خودکار تشخیص داده می‌شوند.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
                  ),
                ),
              )
            else
              SizedBox(
                height: 144,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => AccountCard(account: accounts[i]),
                ),
              ),
            if (state.transactions.isNotEmpty) ...[
              const SectionHeader(title: 'هزینه‌ها بر اساس دسته'),
              ExpenseDonut(
                selectedMonth: _selectedMonth,
                onMonthChanged: (month) =>
                    setState(() => _selectedMonth = month),
                onPickCustomMonth: () => _pickCustomMonth(m),
                slices: slices,
                onCategoryTap: (category) =>
                    widget.onCategorySelected(category, _selectedMonth),
              ),
            ],
            SectionHeader(
              title: 'آخرین تراکنش‌ها',
              actionLabel: 'همه',
              onAction: widget.onSeeAllTransactions,
            ),
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'هنوز تراکنشی ثبت نشده است.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              )
            else
              for (final tx in transactions)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: TransactionTile(
                    transaction: tx,
                    onTap: () => showTransactionEditSheet(context, tx),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
