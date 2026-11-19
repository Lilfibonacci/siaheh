import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaheh/presentation/bloc/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance_event.dart';
import 'package:siaheh/presentation/bloc/finance_state.dart';
import 'package:siaheh/presentation/mapper/finance_mapper.dart';
import 'package:siaheh/presentation/models/finance_ui_models.dart';
import 'package:siaheh/presentation/widgets/account_card.dart';
import 'package:siaheh/presentation/widgets/balance_header_card.dart';
import 'package:siaheh/presentation/widgets/expense_donut.dart';
import 'package:siaheh/presentation/widgets/section_header.dart';
import 'package:siaheh/presentation/widgets/transaction_edit_sheet.dart';
import 'package:siaheh/presentation/widgets/transaction_tile.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.onSeeAllTransactions,
    required this.onSeeAllMessages,
  });

  final VoidCallback onSeeAllTransactions;
  final VoidCallback onSeeAllMessages;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final FinanceState state = context.watch<FinanceBloc>().state;
    final FinanceMapper m = FinanceMapper(state);
    final List<UiAccount> accounts = m.accounts;
    final List<UiTransaction> transactions = m.recentTransactions(5);
    final Map<UiCategory, int> expenses = m.expenseByCategory;
    final int total = accounts.fold(0, (s, a) => s + a.balanceRial);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<FinanceBloc>().add(const FinanceSyncRequested());
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.18),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: theme.colorScheme.primary,
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
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'بروزرسانی پیامک‌ها',
                    onPressed: state.syncing
                        ? null
                        : () => context.read<FinanceBloc>().add(
                            const FinanceSyncRequested(),
                          ),
                    icon: state.syncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                  ),
                ],
              ),
            ),
            if (!state.hasPermission)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: FilledButton.icon(
                  onPressed: () => context.read<FinanceBloc>().add(
                    const FinancePermissionRequested(),
                  ),
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('دادن دسترسی پیامک برای تشخیص خودکار بانک‌ها'),
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
              onAction: onSeeAllMessages,
            ),
            if (accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    'هنوز حساب بانکی شناسایی نشده است. پس از دادن دسترسی پیامک، تمام بانک‌های شما به صورت خودکار تشخیص داده می‌شوند.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
                  ),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => AccountCard(account: accounts[i]),
                ),
              ),
            if (expenses.isNotEmpty) ...[
              const SectionHeader(title: 'هزینه‌ها بر اساس دسته'),
              ExpenseDonut(data: expenses),
            ],
            SectionHeader(
              title: 'آخرین تراکنش‌ها',
              actionLabel: 'همه',
              onAction: onSeeAllTransactions,
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
              for (final tx in transactions.take(5))
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
