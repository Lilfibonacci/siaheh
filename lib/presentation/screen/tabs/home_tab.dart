import 'package:flutter/material.dart';
import 'package:siaheh/core/utils/persian_format.dart';
import 'package:siaheh/presentation/mock/mock_data.dart';
import 'package:siaheh/presentation/widgets/account_card.dart';
import 'package:siaheh/presentation/widgets/balance_header_card.dart';
import 'package:siaheh/presentation/widgets/expense_donut.dart';
import 'package:siaheh/presentation/widgets/section_header.dart';
import 'package:siaheh/presentation/widgets/transaction_edit_sheet.dart';
import 'package:siaheh/presentation/widgets/transaction_tile.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onSeeAllTransactions});

  final VoidCallback onSeeAllTransactions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int total = MockData.accounts.fold(0, (s, a) => s + a.balanceRial);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.18),
                  child: Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('سیاهه', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        PersianFormat.digits('آبان ۱۴۰۵'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
              ],
            ),
          ),
          BalanceHeaderCard(
            totalRial: total,
            incomeRial: MockData.monthIncomeRial,
            expenseRial: MockData.monthExpenseRial,
          ),
          const SectionHeader(title: 'حساب‌های من'),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: MockData.accounts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => AccountCard(account: MockData.accounts[i]),
            ),
          ),
          const SectionHeader(title: 'هزینه‌ها بر اساس دسته'),
          const ExpenseDonut(data: MockData.expenseByCategory),
          SectionHeader(
            title: 'آخرین تراکنش‌ها',
            actionLabel: 'همه',
            onAction: onSeeAllTransactions,
          ),
          for (final tx in MockData.transactions.take(4))
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TransactionTile(
                transaction: tx,
                onTap: () => showTransactionEditSheet(context, tx),
              ),
            ),
        ],
      ),
    );
  }
}
