import 'package:flutter/material.dart';
import 'package:siaheh/core/theme/app_colors.dart';
import 'package:siaheh/core/utils/persian_format.dart';

/// Total balance hero card with income / expense summary.
class BalanceHeaderCard extends StatefulWidget {
  const BalanceHeaderCard({
    super.key,
    required this.totalRial,
    required this.incomeRial,
    required this.expenseRial,
  });

  final int totalRial;
  final int incomeRial;
  final int expenseRial;

  @override
  State<BalanceHeaderCard> createState() => _BalanceHeaderCardState();
}

class _BalanceHeaderCardState extends State<BalanceHeaderCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color gold = dark ? AppColors.goldDarkTheme : const Color(0xFFE9C46A);
    final Color income = dark ? AppColors.emeraldDark : const Color(0xFF34D399);
    final Color expense = dark ? AppColors.crimsonDark : const Color(0xFFF87171);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: dark ? AppColors.darkHeaderGradient : AppColors.lightHeaderGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: gold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'موجودی کل',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _hidden ? '••••••••' : PersianFormat.toman(widget.totalRial),
                style: TextStyle(
                  color: gold,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'تومان',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'درآمد این ماه',
                  value: _hidden ? '•••' : PersianFormat.toman(widget.incomeRial),
                  color: income,
                  icon: Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'هزینه این ماه',
                  value: _hidden ? '•••' : PersianFormat.toman(widget.expenseRial),
                  color: expense,
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
