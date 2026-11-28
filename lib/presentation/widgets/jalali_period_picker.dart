import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
import 'package:siaheh/core/utils/persian_format.dart';
import 'package:siaheh/presentation/bloc/finance/finance_ui_models.dart';

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
    builder: (sheetContext) => Theme(
      data: capturedTheme,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          type: MaterialType.transparency,
          child: JalaliPeriodPickerContent(
            title: title,
            initialFilter: initialFilter,
            countsByYearMonth: countsByYearMonth,
            allowAll: allowAll,
            allowWholeYear: allowWholeYear,
            allowQuickRanges: allowQuickRanges,
            itemUnitLabel: itemUnitLabel,
            onSelected: (filter) => Navigator.of(sheetContext).pop(filter),
          ),
        ),
      ),
    ),
  );
}

/// Reusable Liquid Glass Jalali (Shamsi) year & month picker view used both as
/// a standalone [GlassSheet] (e.g. from the Home donut chart) and as an
/// inline sub-view inside the unified filter sheets.
class JalaliPeriodPickerContent extends StatefulWidget {
  const JalaliPeriodPickerContent({
    super.key,
    required this.title,
    required this.initialFilter,
    required this.countsByYearMonth,
    required this.onSelected,
    this.onBack,
    this.allowAll = true,
    this.allowWholeYear = true,
    this.allowQuickRanges = true,
    this.itemUnitLabel = 'مورد',
  });

  final String title;
  final JalaliDateFilter initialFilter;
  final Map<int, Map<int, int>> countsByYearMonth;
  final ValueChanged<JalaliDateFilter> onSelected;
  final VoidCallback? onBack;
  final bool allowAll;
  final bool allowWholeYear;
  final bool allowQuickRanges;
  final String itemUnitLabel;

  @override
  State<JalaliPeriodPickerContent> createState() =>
      _JalaliPeriodPickerContentState();
}

class _JalaliPeriodPickerContentState extends State<JalaliPeriodPickerContent> {
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
              if (widget.onBack != null) ...[
                GlassButton.custom(
                  useOwnLayer: true,
                  quality: GlassQuality.standard,
                  width: 38,
                  height: 38,
                  stretch: 0.15,
                  label: 'بازگشت',
                  onTap: widget.onBack!,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
              ] else ...[
                Icon(
                  Icons.calendar_month_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.allowAll && widget.initialFilter.isActive)
                SiahehGlassChip(
                  label: 'حذف فیلتر',
                  selected: false,
                  onTap: () => widget.onSelected(const JalaliDateFilter.all()),
                ),
            ],
          ),
          if (widget.allowAll || widget.allowQuickRanges) ...[
            const SizedBox(height: 12),
            GlassBackdropGroup(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.allowAll)
                    SiahehGlassChip(
                      label: 'همه زمان‌ها',
                      selected: !widget.initialFilter.isActive,
                      onTap: () =>
                          widget.onSelected(const JalaliDateFilter.all()),
                    ),
                  if (widget.allowQuickRanges) ...[
                    SiahehGlassChip(
                      label: 'امروز',
                      selected:
                          widget.initialFilter.kind == JalaliFilterKind.today,
                      onTap: () =>
                          widget.onSelected(const JalaliDateFilter.today()),
                    ),
                    SiahehGlassChip(
                      label: '۷ روز اخیر',
                      selected:
                          widget.initialFilter.kind ==
                          JalaliFilterKind.last7Days,
                      onTap: () =>
                          widget.onSelected(const JalaliDateFilter.last7Days()),
                    ),
                  ],
                  SiahehGlassChip(
                    label: 'این ماه',
                    selected: widget.initialFilter == thisMonth,
                    onTap: () => widget.onSelected(thisMonth),
                  ),
                  SiahehGlassChip(
                    label: 'ماه قبل',
                    selected: widget.initialFilter == lastMonth,
                    onTap: () => widget.onSelected(lastMonth),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Year selector bar
          SiahehGlassCard(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
              height: 36,
              child: GlassBackdropGroup(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _suggestedYears.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final int y = _suggestedYears[i];
                    return Center(
                      child: SiahehGlassChip(
                        label: PersianFormat.digits('$y'),
                        selected: y == _selectedYear,
                        onTap: () => setState(() => _selectedYear = y),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (widget.allowWholeYear) ...[
            const SizedBox(height: 10),
            SiahehGlassCard(
              radius: 16,
              tintColor: isWholeYearSelected ? scheme.primary : null,
              borderColor: isWholeYearSelected
                  ? scheme.primary.withValues(alpha: 0.78)
                  : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    widget.onSelected(JalaliDateFilter.year(_selectedYear)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
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
                                ? (isDark ? scheme.primary : scheme.onSurface)
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
              mainAxisExtent: 60,
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

              return Opacity(
                opacity: isFuture ? 0.38 : 1.0,
                child: SiahehGlassCard(
                  radius: 16,
                  tintColor: isSelected ? scheme.primary : null,
                  borderColor: isSelected
                      ? scheme.primary.withValues(alpha: 0.80)
                      : (count > 0 && !isFuture
                          ? scheme.primary.withValues(alpha: 0.28)
                          : null),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isFuture
                        ? null
                        : () => widget.onSelected(
                            JalaliDateFilter.month(
                              year: _selectedYear,
                              month: month,
                            ),
                          ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            JalaliDateFilter.persianMonthNames[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? scheme.primary : scheme.onSurface)
                                  : scheme.onSurface,
                            ),
                          ),
                          if (count > 0 && !isFuture) ...[
                            const SizedBox(height: 2),
                            Text(
                              PersianFormat.digits(
                                '$count ${widget.itemUnitLabel}',
                              ),
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
