import 'package:flutter/material.dart';
import 'package:siaheh/core/theme/app_colors.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
import 'package:siaheh/core/utils/persian_format.dart';
import 'package:siaheh/presentation/models/finance_ui_models.dart';
import 'package:siaheh/presentation/widgets/bank_logo.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap});

  final UiTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final UiTransaction tx = transaction;

    final (Color color, String sign) = switch (tx.type) {
      UiTxType.income => (scheme.secondary, '+'),
      UiTxType.expense => (scheme.error, '-'),
      UiTxType.transfer => (AppColors.transfer(theme.brightness), ''),
    };

    return SiahehGlassCard(
      radius: 20,
      borderColor: tx.needsReview
          ? scheme.primary.withValues(alpha: 0.55)
          : null,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: tx.category.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: tx.category.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(tx.category.icon, color: tx.category.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          BankLogo(bankKey: tx.account.bank.key, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${tx.account.bank.name} • ${tx.category.name} • ${tx.timeLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.62),
                              ),
                            ),
                          ),
                          if (tx.needsReview) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'نیازمند بررسی',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sign${PersianFormat.toman(tx.amountRial)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'تومان',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
