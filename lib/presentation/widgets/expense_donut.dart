import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/core/theme/app_fonts.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
import 'package:siaheh/core/utils/persian_format.dart';
import 'package:siaheh/presentation/bloc/finance/finance_ui_models.dart';

/// Interactive Liquid Glass expense breakdown section with:
/// - Standalone [GlassSegmentedControl] switcher (`این ماه` / `ماه قبل` / `انتخاب ماه`)
///   placed outside the refractive card to preserve full jelly physics and refraction
/// - Interactive Jalali month navigator bar (`ماه قبل` / tappable `ماه و سال` / `ماه بعد`)
/// - Touch-interactive donut chart with animated center summary
/// - Accessible category breakdown rows (icon + bar + amount + % + drill-down)
class ExpenseDonut extends StatefulWidget {
  const ExpenseDonut({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onPickCustomMonth,
    required this.slices,
    required this.onCategoryTap,
  });

  final JalaliDateFilter selectedMonth;
  final ValueChanged<JalaliDateFilter> onMonthChanged;
  final VoidCallback onPickCustomMonth;
  final List<CategoryExpenseSlice> slices;
  final ValueChanged<String> onCategoryTap;

  @override
  State<ExpenseDonut> createState() => _ExpenseDonutState();
}

class _ExpenseDonutState extends State<ExpenseDonut> {
  int? _touchedIndex;

  @override
  void didUpdateWidget(covariant ExpenseDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth ||
        (_touchedIndex != null && _touchedIndex! >= widget.slices.length)) {
      _touchedIndex = null;
    }
  }

  String _formatCompactToman(int totalRial) {
    final int toman = totalRial.abs() ~/ 10;
    if (toman >= 1000000) {
      final double millions = toman / 1000000;
      final String formatted = millions >= 10
          ? millions.round().toString()
          : millions.toStringAsFixed(1);
      return '${PersianFormat.digits(formatted)} میلیون';
    }
    if (toman >= 1000) {
      return '${PersianFormat.digits('${(toman / 1000).round()}')} هزار';
    }
    return PersianFormat.digits('$toman');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final JalaliDateFilter thisMonth = JalaliDateFilter.thisMonth();
    final JalaliDateFilter lastMonth = JalaliDateFilter.lastMonth();
    final int segmentIndex = widget.selectedMonth.isSameMonthAs(thisMonth)
        ? 0
        : (widget.selectedMonth.isSameMonthAs(lastMonth) ? 1 : 2);
    final String customSegmentLabel =
        segmentIndex == 2 ? widget.selectedMonth.compactLabel() : 'انتخاب ماه';
    final bool canGoNextMonth = !widget.selectedMonth.isAtOrAfterCurrentMonth();

    final List<CategoryExpenseSlice> slices = widget.slices;
    final int totalRial = slices.fold(0, (s, e) => s + e.amountRial);
    final int totalCount = slices.fold(0, (s, e) => s + e.transactionCount);
    final CategoryExpenseSlice? selected =
        (_touchedIndex != null &&
            _touchedIndex! >= 0 &&
            _touchedIndex! < slices.length)
        ? slices[_touchedIndex!]
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Standalone Liquid Glass month switcher (sibling above card so jelly
          // overshoot and refraction are never clipped by a parent glass layer).
          GlassSegmentedControl(
            useOwnLayer: true,
            height: 44,
            borderRadius: 22,
            selectedIndex: segmentIndex,
            onSegmentSelected: (idx) {
              if (idx == 0) {
                widget.onMonthChanged(thisMonth);
              } else if (idx == 1) {
                widget.onMonthChanged(lastMonth);
              } else {
                widget.onPickCustomMonth();
              }
            },
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.05),
            indicatorColor: isDark
                ? scheme.primary.withValues(alpha: 0.26)
                : Colors.white.withValues(alpha: 0.92),
            selectedTextStyle: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? scheme.primary : scheme.onSurface,
            ),
            unselectedTextStyle: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.68),
            ),
            segments: [
              const GlassSegment(label: 'این ماه'),
              const GlassSegment(label: 'ماه قبل'),
              GlassSegment(label: customSegmentLabel),
            ],
          ),
          const SizedBox(height: 12),
          SiahehGlassCard(
            radius: 26,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  // Active Jalali month bar with quick prev/next & picker trigger
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'ماه قبل',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => widget.onMonthChanged(
                          widget.selectedMonth.previousMonth(),
                        ),
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: widget.onPickCustomMonth,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    size: 15,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      widget.selectedMonth.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'ماه بعد',
                        visualDensity: VisualDensity.compact,
                        onPressed: canGoNextMonth
                            ? () => widget.onMonthChanged(
                                widget.selectedMonth.nextMonth(),
                              )
                            : null,
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: canGoNextMonth
                              ? scheme.onSurface.withValues(alpha: 0.75)
                              : scheme.onSurface.withValues(alpha: 0.22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (slices.isEmpty || totalRial <= 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 40,
                            color: scheme.onSurface.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'در ${widget.selectedMonth.label} هزینه‌ای ثبت نشده است',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Interactive Donut Chart
                    Center(
                      child: RepaintBoundary(
                        child: SizedBox(
                          width: 196,
                          height: 196,
                          child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                startDegreeOffset: -90,
                                sectionsSpace: slices.length > 1 ? 3 : 0,
                                centerSpaceRadius: 62,
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, response) {
                                    if (event is! FlTapUpEvent) return;
                                    final idx = response
                                        ?.touchedSection
                                        ?.touchedSectionIndex;
                                    setState(() {
                                      if (idx == null ||
                                          idx < 0 ||
                                          idx >= slices.length ||
                                          _touchedIndex == idx) {
                                        _touchedIndex = null;
                                      } else {
                                        _touchedIndex = idx;
                                      }
                                    });
                                  },
                                ),
                                sections: [
                                  for (var i = 0; i < slices.length; i++)
                                    PieChartSectionData(
                                      value: slices[i].amountRial.toDouble(),
                                      color:
                                          _touchedIndex == null ||
                                              _touchedIndex == i
                                          ? slices[i].category.color
                                          : slices[i].category.color.withValues(
                                              alpha: 0.32,
                                            ),
                                      radius: _touchedIndex == i ? 24 : 18,
                                      showTitle: false,
                                    ),
                                ],
                              ),
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                            ),
                            GestureDetector(
                              onTap: selected == null
                                  ? null
                                  : () => widget.onCategoryTap(
                                      selected.category.name,
                                    ),
                              child: SizedBox(
                                width: 114,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: selected != null
                                      ? Column(
                                          key: ValueKey(selected.category.name),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              selected.category.icon,
                                              size: 20,
                                              color: selected.category.color,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              selected.category.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: theme
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '${PersianFormat.toman(selected.amountRial)} ت',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: selected
                                                          .category
                                                          .color,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                            Text(
                                              PersianFormat.digits(
                                                '${selected.percentage.round()}%',
                                              ),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontSize: 11,
                                                    color: scheme.onSurface
                                                        .withValues(
                                                          alpha: 0.6,
                                                        ),
                                                  ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          key: const ValueKey('total'),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'مجموع هزینه',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontSize: 11,
                                                    color: scheme.onSurface
                                                        .withValues(
                                                          alpha: 0.6,
                                                        ),
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                _formatCompactToman(totalRial),
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                            Text(
                                              PersianFormat.digits(
                                                '$totalCount تراکنش',
                                              ),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontSize: 11,
                                                    color: scheme.onSurface
                                                        .withValues(
                                                          alpha: 0.55,
                                                        ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : scheme.outline.withValues(alpha: 0.6),
                      height: 1,
                    ),
                    const SizedBox(height: 10),
                    // Breakdown rows sorted largest -> smallest
                    for (var i = 0; i < slices.length; i++)
                      _CategoryBreakdownRow(
                        slice: slices[i],
                        highlighted: _touchedIndex == i,
                        onTap: () =>
                            widget.onCategoryTap(slices[i].category.name),
                        onLongPress: () => setState(() {
                          _touchedIndex = _touchedIndex == i ? null : i;
                        }),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownRow extends StatelessWidget {
  const _CategoryBreakdownRow({
    required this.slice,
    required this.highlighted,
    required this.onTap,
    required this.onLongPress,
  });

  final CategoryExpenseSlice slice;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final UiCategory cat = slice.category;
    final double ratio = (slice.percentage / 100.0).clamp(0.02, 1.0);
    final String pctLabel = slice.percentage < 1
        ? '<۱%'
        : PersianFormat.digits('${slice.percentage.round()}%');

    return Material(
      color: highlighted
          ? cat.color.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(cat.icon, size: 19, color: cat.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${PersianFormat.toman(slice.amountRial)} تومان',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 5,
                              child: Stack(
                                children: [
                                  Container(
                                    color: scheme.outline.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: ratio,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: cat.color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          PersianFormat.digits(
                            '${slice.transactionCount} مورد • $pctLabel',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_left_rounded,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
