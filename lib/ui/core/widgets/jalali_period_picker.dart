import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:siaheh/ui/core/theme/siaheh_glass.dart';
import 'package:siaheh/ui/core/utils/persian_format.dart';
import 'package:siaheh/ui/core/models/finance_ui_models.dart';

/// Opens a Liquid Glass bottom sheet allowing the user to pick a Jalali month,
/// whole Jalali year, or quick time preset (today, last 7 days, this/last month,
/// all time).
Future<JalaliDateFilter?> showJalaliPeriodPickerSheet({
  required BuildContext context,
  required JalaliDateFilter initialFilter,
  required Map<int, Map<int, int>> countsByYearMonth,
  String title = 'فیلتر زمانی',
  bool allowAll = true,
  bool allowWholeYear = true,
  bool allowQuickRanges = true,
  String itemUnitLabel = 'مورد',
}) {
  final ThemeData capturedTheme = Theme.of(context);

  return GlassSheet.show<JalaliDateFilter>(
    context: context,
    settings: SiahehGlass.sheetSettings(capturedTheme.brightness),
    topBorderRadius: 34,
    margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
    isScrollable: true,
    interactionScale: 1.0,
    stretch: 0.12,
    enableInteractionGlow: false,
    enableSaturationGlow: false,
    suppressInteractionOnChildren: true,
    dragIndicatorColor: capturedTheme.colorScheme.onSurface.withValues(
      alpha: 0.28,
    ),
    builder: (_) => Theme(
      data: capturedTheme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          type: MaterialType.transparency,
          child: _JalaliPeriodPickerContent(
            title: title,
            initialFilter: initialFilter,
            countsByYearMonth: countsByYearMonth,
            allowAll: allowAll,
            allowWholeYear: allowWholeYear,
            allowQuickRanges: allowQuickRanges,
            itemUnitLabel: itemUnitLabel,
          ),
        ),
      ),
    ),
  );
}

class _JalaliPeriodPickerContent extends StatefulWidget {
  const _JalaliPeriodPickerContent({
    required this.title,
    required this.initialFilter,
    required this.countsByYearMonth,
    required this.allowAll,
    required this.allowWholeYear,
    required this.allowQuickRanges,
    required this.itemUnitLabel,
  });

  final String title;
  final JalaliDateFilter initialFilter;
  final Map<int, Map<int, int>> countsByYearMonth;
  final bool allowAll;
  final bool allowWholeYear;
  final bool allowQuickRanges;
  final String itemUnitLabel;

  @override
  State<_JalaliPeriodPickerContent> createState() =>
      _JalaliPeriodPickerContentState();
}

class _JalaliPeriodPickerContentState
    extends State<_JalaliPeriodPickerContent> {
  late final Jalali _nowJalali = Jalali.fromDateTime(DateTime.now());
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialFilter.year ?? _nowJalali.year;
  }

  List<int> get _suggestedYears {
    final years = <int>{
      _nowJalali.year,
      _selectedYear,
      ...widget.countsByYearMonth.keys,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  int _yearTotalCount(int year) {
    final months = widget.countsByYearMonth[year];
    if (months == null) return 0;
    var sum = 0;
    for (final c in months.values) {
      sum += c;
    }
    return sum;
  }

  void _select(JalaliDateFilter filter) {
    Navigator.of(context).pop(filter);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final JalaliDateFilter thisMonth = JalaliDateFilter.thisMonth();
    final JalaliDateFilter lastMonth = JalaliDateFilter.lastMonth();
    final Map<int, int> monthCounts =
        widget.countsByYearMonth[_selectedYear] ?? const {};
    final int selectedYearTotal = _yearTotalCount(_selectedYear);
    final bool isWholeYearSelected =
        widget.initialFilter.kind == JalaliFilterKind.year &&
        widget.initialFilter.year == _selectedYear;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: scheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.allowAll && widget.initialFilter.isActive)
                TextButton(
                  onPressed: () => _select(const JalaliDateFilter.all()),
                  child: const Text('حذف فیلتر'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick presets
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.allowAll)
                _QuickPill(
                  label: 'همه زمان‌ها',
                  selected: !widget.initialFilter.isActive,
                  onTap: () => _select(const JalaliDateFilter.all()),
                ),
              if (widget.allowQuickRanges) ...[
                _QuickPill(
                  label: 'امروز',
                  selected:
                      widget.initialFilter.kind == JalaliFilterKind.today,
                  onTap: () => _select(const JalaliDateFilter.today()),
                ),
                _QuickPill(
                  label: '۷ روز اخیر',
                  selected:
                      widget.initialFilter.kind == JalaliFilterKind.last7Days,
                  onTap: () => _select(const JalaliDateFilter.last7Days()),
                ),
              ],
              _QuickPill(
                label: 'این ماه',
                selected: widget.initialFilter == thisMonth,
                onTap: () => _select(thisMonth),
              ),
              _QuickPill(
                label: 'ماه قبل',
                selected: widget.initialFilter == lastMonth,
                onTap: () => _select(lastMonth),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Year selector bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : scheme.outline.withValues(alpha: 0.8),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'سال قبل',
                  visualDensity: VisualDensity.compact,
                  onPressed: _selectedYear > 1390
                      ? () => setState(() => _selectedYear--)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      PersianFormat.digits('سال $_selectedYear'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'سال بعد',
                  visualDensity: VisualDensity.compact,
                  onPressed: _selectedYear < _nowJalali.year
                      ? () => setState(() => _selectedYear++)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
              ],
            ),
          ),
          if (_suggestedYears.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestedYears.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final int y = _suggestedYears[i];
                  final bool selected = y == _selectedYear;
                  return _QuickPill(
                    label: PersianFormat.digits('$y'),
                    selected: selected,
                    onTap: () => setState(() => _selectedYear = y),
                  );
                },
              ),
            ),
          ],
          if (widget.allowWholeYear) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _select(JalaliDateFilter.year(_selectedYear)),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isWholeYearSelected
                      ? scheme.primary.withValues(alpha: isDark ? 0.24 : 0.16)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.65)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isWholeYearSelected
                        ? scheme.primary
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : scheme.outline),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 18,
                      color: isWholeYearSelected
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        PersianFormat.digits('کل سال $_selectedYear'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isWholeYearSelected
                              ? scheme.primary
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    if (selectedYearTotal > 0)
                      Text(
                        PersianFormat.digits(
                          '$selectedYearTotal ${widget.itemUnitLabel}',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          // 12-month Jalali grid (3 columns x 4 rows)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 58,
            ),
            itemBuilder: (_, index) {
              final int month = index + 1;
              final bool isFuture =
                  _selectedYear > _nowJalali.year ||
                  (_selectedYear == _nowJalali.year &&
                      month > _nowJalali.month);
              final bool isSelected =
                  widget.initialFilter.kind == JalaliFilterKind.month &&
                  widget.initialFilter.year == _selectedYear &&
                  widget.initialFilter.month == month;
              final int count = monthCounts[month] ?? 0;

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isFuture
                    ? null
                    : () => _select(
                        JalaliDateFilter.month(
                          year: _selectedYear,
                          month: month,
                        ),
                      ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary.withValues(alpha: isDark ? 0.25 : 0.16)
                        : (isDark
                            ? Colors.white.withValues(
                                alpha: isFuture ? 0.02 : 0.06,
                              )
                            : Colors.white.withValues(
                                alpha: isFuture ? 0.32 : 0.72,
                              )),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? scheme.primary
                          : (count > 0 && !isFuture
                              ? scheme.primary.withValues(alpha: 0.28)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.09)
                                  : scheme.outline.withValues(alpha: 0.7))),
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        JalaliDateFilter.persianMonthNames[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isFuture
                              ? scheme.onSurface.withValues(alpha: 0.28)
                              : (isSelected
                                  ? scheme.primary
                                  : scheme.onSurface),
                        ),
                      ),
                      if (count > 0 && !isFuture) ...[
                        const SizedBox(height: 2),
                        Text(
                          PersianFormat.digits('$count ${widget.itemUnitLabel}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: isSelected
                                ? scheme.primary.withValues(alpha: 0.9)
                                : scheme.onSurface.withValues(alpha: 0.52),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickPill extends StatelessWidget {
  const _QuickPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: isDark ? 0.25 : 0.16)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.72)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? scheme.primary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : scheme.outline),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? scheme.primary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Compact Liquid Glass filter chip placed in Transactions & Bank Messages tabs
/// to display and edit/clear the active [JalaliDateFilter].
class JalaliDateFilterChip extends StatelessWidget {
  const JalaliDateFilterChip({
    super.key,
    required this.filter,
    required this.onTap,
    this.onClear,
  });

  final JalaliDateFilter filter;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool active = filter.isActive;

    return SiahehGlassChip(
      label: filter.label,
      selected: active,
      accentColor: scheme.primary,
      icon: Icon(
        Icons.calendar_month_rounded,
        size: 15,
        color: active ? scheme.primary : scheme.onSurface.withValues(alpha: 0.78),
      ),
      onTap: onTap,
      onDeleted: active ? onClear : null,
    );
  }
}
