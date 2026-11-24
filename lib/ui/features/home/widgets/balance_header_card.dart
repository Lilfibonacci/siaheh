import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/ui/core/theme/app_colors.dart';
import 'package:siaheh/ui/core/theme/siaheh_glass.dart';
import 'package:siaheh/ui/core/utils/persian_format.dart';

/// Total balance Liquid Glass hero card with income / expense summary.
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
    final Brightness brightness = Theme.of(context).brightness;
    final bool dark = brightness == Brightness.dark;
    final Color gold = dark ? AppColors.goldDarkTheme : const Color(0xFF9A6F14);
    final Color income = dark ? AppColors.emeraldDark : AppColors.emeraldLight;
    final Color expense = dark ? AppColors.crimsonDark : AppColors.crimsonLight;
    final Color labelColor = dark
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.lightTextPrimary.withValues(alpha: 0.65);
    final Color valueColor = dark ? Colors.white : AppColors.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RepaintBoundary(
        child: GlassContainer(
          useOwnLayer: true,
          shape: const LiquidRoundedSuperellipse(borderRadius: 30),
          settings: SiahehGlass.heroCardSettings(brightness),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: dark
                    ? [
                        const Color(0xFF2A2415).withValues(alpha: 0.56),
                        const Color(0xFF161A1D).withValues(alpha: 0.34),
                        const Color(0xFF0F2922).withValues(alpha: 0.58),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withValues(alpha: 0.82),
                        const Color(0xFFFAF3E0).withValues(alpha: 0.72),
                        const Color(0xFFE7F5EE).withValues(alpha: 0.74),
                      ],
              ),
              border: Border.all(
                color: dark
                    ? gold.withValues(alpha: 0.38)
                    : AppColors.goldLightTheme.withValues(alpha: 0.30),
                width: 1.1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'موجودی کل',
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.10)
                          : AppColors.lightTextPrimary.withValues(alpha: 0.06),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _hidden = !_hidden),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _hidden
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: labelColor,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          _hidden
                              ? '••••••••'
                              : PersianFormat.toman(widget.totalRial),
                          style: TextStyle(
                            color: gold,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'تومان',
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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
                        value: _hidden
                            ? '•••'
                            : PersianFormat.toman(widget.incomeRial),
                        color: income,
                        icon: Icons.south_west_rounded,
                        isDark: dark,
                        valueColor: valueColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStat(
                        label: 'هزینه این ماه',
                        value: _hidden
                            ? '•••'
                            : PersianFormat.toman(widget.expenseRial),
                        color: expense,
                        icon: Icons.north_east_rounded,
                        isDark: dark,
                        valueColor: valueColor,
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.09)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : AppColors.lightBorder.withValues(alpha: 0.85),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.22 : 0.14),
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
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.68)
                        : AppColors.lightTextSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
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
