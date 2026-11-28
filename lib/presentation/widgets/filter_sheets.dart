import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/core/theme/app_fonts.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
import 'package:siaheh/core/utils/persian_format.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';
import 'package:siaheh/presentation/bloc/finance/finance_ui_models.dart';
import 'package:siaheh/presentation/widgets/bank_logo.dart';
import 'package:siaheh/presentation/widgets/jalali_period_picker.dart';

/// Filter options for transaction type on [TransactionsTab].
enum TransactionTypeFilter {
  all,
  income,
  expense,
  transfer,
  review;

  String get label => switch (this) {
    TransactionTypeFilter.all => 'همه',
    TransactionTypeFilter.income => 'واریز',
    TransactionTypeFilter.expense => 'برداشت',
    TransactionTypeFilter.transfer => 'انتقال',
    TransactionTypeFilter.review => 'نیازمند بررسی',
  };
}

/// Combined filter state edited inside [showTransactionFilterSheet].
@immutable
class TransactionFilterSelection {
  const TransactionFilterSelection({
    this.type = TransactionTypeFilter.all,
    this.bankKey,
    this.categoryName,
    this.dateFilter = const JalaliDateFilter.all(),
  });

  static const TransactionFilterSelection empty = TransactionFilterSelection();

  final TransactionTypeFilter type;
  final String? bankKey;
  final String? categoryName;
  final JalaliDateFilter dateFilter;

  int get activeCount =>
      (type != TransactionTypeFilter.all ? 1 : 0) +
      (bankKey != null ? 1 : 0) +
      (categoryName != null ? 1 : 0) +
      (dateFilter.isActive ? 1 : 0);

  bool get hasAny => activeCount > 0;
}

/// Combined filter state edited inside [showMessageFilterSheet].
@immutable
class MessageFilterSelection {
  const MessageFilterSelection({
    this.kind,
    this.bankKey,
    this.dateFilter = const JalaliDateFilter.all(),
  });

  static const MessageFilterSelection empty = MessageFilterSelection();

  final BankSmsKind? kind;
  final String? bankKey;
  final JalaliDateFilter dateFilter;

  int get activeCount =>
      (kind != null ? 1 : 0) +
      (bankKey != null ? 1 : 0) +
      (dateFilter.isActive ? 1 : 0);

  bool get hasAny => activeCount > 0;
}

/// Persian label for a [BankSmsKind].
String bankSmsKindLabel(BankSmsKind kind) => switch (kind) {
  BankSmsKind.transaction => 'تراکنش',
  BankSmsKind.info => 'اطلاع‌رسانی',
  BankSmsKind.otp => 'رمز پویا',
  BankSmsKind.unparsed => 'پارس‌نشده',
};

/// Compact Liquid Glass header button opening the filter sheet, showing an
/// active-count badge when one or more filters are applied.
class FilterActionButton extends StatelessWidget {
  const FilterActionButton({
    super.key,
    required this.activeCount,
    required this.onTap,
    this.size = 44,
  });

  final int activeCount;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool hasActive = activeCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassButton.custom(
          useOwnLayer: true,
          quality: GlassQuality.standard,
          width: size,
          height: size,
          stretch: 0.15,
          tintColor: hasActive ? scheme.primary.withValues(alpha: 0.22) : null,
          label: 'فیلتر',
          onTap: onTap,
          child: Icon(
            hasActive ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
            size: 20,
            color: hasActive ? scheme.primary : scheme.onSurface,
          ),
        ),
        if (hasActive)
          PositionedDirectional(
            top: -4,
            start: -4,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  PersianFormat.digits('$activeCount'),
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimary,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Opens the unified Liquid Glass filter bottom sheet for [TransactionsTab].
Future<TransactionFilterSelection?> showTransactionFilterSheet({
  required BuildContext context,
  required TransactionFilterSelection initial,
  required List<UiBank> banks,
  required List<UiCategory> categories,
  required Map<int, Map<int, int>> countsByYearMonth,
  int reviewCount = 0,
}) {
  final ThemeData capturedTheme = Theme.of(context);

  return GlassSheet.show<TransactionFilterSelection>(
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
          child: _TransactionFilterSheetContent(
            initial: initial,
            banks: banks,
            categories: categories,
            countsByYearMonth: countsByYearMonth,
            reviewCount: reviewCount,
          ),
        ),
      ),
    ),
  );
}

/// Opens the unified Liquid Glass filter bottom sheet for [BankMessagesTab].
Future<MessageFilterSelection?> showMessageFilterSheet({
  required BuildContext context,
  required MessageFilterSelection initial,
  required List<UiBank> banks,
  required int Function(String bankKey) messageCountForBank,
  required Map<int, Map<int, int>> countsByYearMonth,
}) {
  final ThemeData capturedTheme = Theme.of(context);

  return GlassSheet.show<MessageFilterSelection>(
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
          child: _MessageFilterSheetContent(
            initial: initial,
            banks: banks,
            messageCountForBank: messageCountForBank,
            countsByYearMonth: countsByYearMonth,
          ),
        ),
      ),
    ),
  );
}

class _TransactionFilterSheetContent extends StatefulWidget {
  const _TransactionFilterSheetContent({
    required this.initial,
    required this.banks,
    required this.categories,
    required this.countsByYearMonth,
    required this.reviewCount,
  });

  final TransactionFilterSelection initial;
  final List<UiBank> banks;
  final List<UiCategory> categories;
  final Map<int, Map<int, int>> countsByYearMonth;
  final int reviewCount;

  @override
  State<_TransactionFilterSheetContent> createState() =>
      _TransactionFilterSheetContentState();
}

class _TransactionFilterSheetContentState
    extends State<_TransactionFilterSheetContent> {
  late TransactionTypeFilter _type = widget.initial.type;
  late String? _bankKey = widget.initial.bankKey;
  late String? _categoryName = widget.initial.categoryName;
  late JalaliDateFilter _dateFilter = widget.initial.dateFilter;
  bool _pickingDate = false;

  TransactionFilterSelection get _current => TransactionFilterSelection(
    type: _type,
    bankKey: _bankKey,
    categoryName: _categoryName,
    dateFilter: _dateFilter,
  );

  void _reset() {
    setState(() {
      _type = TransactionTypeFilter.all;
      _bankKey = null;
      _categoryName = null;
      _dateFilter = const JalaliDateFilter.all();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isReview = _type == TransactionTypeFilter.review;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _pickingDate
            ? JalaliPeriodPickerContent(
                key: const ValueKey('tx_jalali_picker'),
                title: 'فیلتر زمانی تراکنش‌ها',
                initialFilter: _dateFilter,
                countsByYearMonth: widget.countsByYearMonth,
                allowAll: true,
                allowWholeYear: true,
                allowQuickRanges: false,
                itemUnitLabel: 'تراکنش',
                onBack: () => setState(() => _pickingDate = false),
                onSelected: (picked) => setState(() {
                  _dateFilter = picked;
                  _pickingDate = false;
                }),
              )
            : Padding(
                key: const ValueKey('tx_main_filters'),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SheetHeader(
                      title: 'فیلتر تراکنش‌ها',
                      showClear: _current.hasAny,
                      onClear: _reset,
                    ),
                    const SizedBox(height: 14),
                    const _SheetSectionTitle('نوع تراکنش'),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: isReview ? 0.55 : 1.0,
                      child: GlassSegmentedControl(
                        useOwnLayer: true,
                        height: 40,
                        borderRadius: 20,
                        selectedIndex: isReview ? 0 : _type.index,
                        onSegmentSelected: (idx) => setState(
                          () => _type = TransactionTypeFilter.values[idx],
                        ),
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.05),
                        indicatorColor: isDark
                            ? scheme.primary.withValues(alpha: 0.28)
                            : Colors.white.withValues(alpha: 0.94),
                        selectedTextStyle: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? scheme.primary : scheme.onSurface,
                        ),
                        unselectedTextStyle: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface.withValues(alpha: 0.68),
                        ),
                        segments: const [
                          GlassSegment(label: 'همه'),
                          GlassSegment(label: 'واریز'),
                          GlassSegment(label: 'برداشت'),
                          GlassSegment(label: 'انتقال'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ReviewToggleTile(
                      selected: isReview,
                      reviewCount: widget.reviewCount,
                      onTap: () => setState(
                        () => _type = isReview
                            ? TransactionTypeFilter.all
                            : TransactionTypeFilter.review,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SheetSectionTitle('بازه زمانی'),
                    const SizedBox(height: 8),
                    _DateFilterSection(
                      dateFilter: _dateFilter,
                      onSelected: (f) => setState(() => _dateFilter = f),
                      onOpenJalaliPicker: () =>
                          setState(() => _pickingDate = true),
                    ),
                    if (widget.banks.length > 1) ...[
                      const SizedBox(height: 16),
                      const _SheetSectionTitle('بانک'),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 48,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: widget.banks.length + 1,
                        itemBuilder: (_, idx) {
                          if (idx == 0) {
                            return _BankGridTile(
                              label: 'همه بانک‌ها',
                              selected: _bankKey == null,
                              onTap: () => setState(() => _bankKey = null),
                            );
                          }
                          final UiBank bank = widget.banks[idx - 1];
                          return _BankGridTile(
                            bankKey: bank.key,
                            label: bank.name,
                            selected: _bankKey == bank.key,
                            onTap: () => setState(() => _bankKey = bank.key),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    const _SheetSectionTitle('دسته‌بندی'),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisExtent: 74,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: widget.categories.length + 1,
                      itemBuilder: (_, idx) {
                        if (idx == 0) {
                          return _CategoryGridTile(
                            label: 'همه دسته‌ها',
                            icon: Icons.apps_rounded,
                            color: scheme.primary,
                            selected: _categoryName == null,
                            onTap: () => setState(() => _categoryName = null),
                          );
                        }
                        final UiCategory cat = widget.categories[idx - 1];
                        return _CategoryGridTile(
                          label: cat.name,
                          icon: cat.icon,
                          color: cat.color,
                          selected: _categoryName == cat.name,
                          onTap: () => setState(() => _categoryName = cat.name),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SiahehPrimaryGlassButton(
                      label: 'اعمال فیلتر',
                      icon: Icons.check_rounded,
                      onTap: () => Navigator.of(context).pop(_current),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MessageFilterSheetContent extends StatefulWidget {
  const _MessageFilterSheetContent({
    required this.initial,
    required this.banks,
    required this.messageCountForBank,
    required this.countsByYearMonth,
  });

  final MessageFilterSelection initial;
  final List<UiBank> banks;
  final int Function(String bankKey) messageCountForBank;
  final Map<int, Map<int, int>> countsByYearMonth;

  @override
  State<_MessageFilterSheetContent> createState() =>
      _MessageFilterSheetContentState();
}

class _MessageFilterSheetContentState
    extends State<_MessageFilterSheetContent> {
  late BankSmsKind? _kind = widget.initial.kind;
  late String? _bankKey = widget.initial.bankKey;
  late JalaliDateFilter _dateFilter = widget.initial.dateFilter;
  bool _pickingDate = false;

  MessageFilterSelection get _current => MessageFilterSelection(
    kind: _kind,
    bankKey: _bankKey,
    dateFilter: _dateFilter,
  );

  void _reset() {
    setState(() {
      _kind = null;
      _bankKey = null;
      _dateFilter = const JalaliDateFilter.all();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _pickingDate
            ? JalaliPeriodPickerContent(
                key: const ValueKey('msg_jalali_picker'),
                title: 'فیلتر زمانی پیامک‌ها',
                initialFilter: _dateFilter,
                countsByYearMonth: widget.countsByYearMonth,
                allowAll: true,
                allowWholeYear: true,
                allowQuickRanges: false,
                itemUnitLabel: 'پیامک',
                onBack: () => setState(() => _pickingDate = false),
                onSelected: (picked) => setState(() {
                  _dateFilter = picked;
                  _pickingDate = false;
                }),
              )
            : Padding(
                key: const ValueKey('msg_main_filters'),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SheetHeader(
                      title: 'فیلتر پیامک‌های بانکی',
                      showClear: _current.hasAny,
                      onClear: _reset,
                    ),
                    const SizedBox(height: 14),
                    const _SheetSectionTitle('نوع پیامک'),
                    const SizedBox(height: 8),
                    GlassBackdropGroup(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SiahehGlassChip(
                            icon: const Icon(
                              Icons.mark_email_read_rounded,
                              size: 16,
                            ),
                            label: 'همه',
                            selected: _kind == null,
                            onTap: () => setState(() => _kind = null),
                          ),
                          SiahehGlassChip(
                            icon: const Icon(
                              Icons.receipt_long_rounded,
                              size: 16,
                            ),
                            label: bankSmsKindLabel(BankSmsKind.transaction),
                            selected: _kind == BankSmsKind.transaction,
                            onTap: () => setState(
                              () => _kind = BankSmsKind.transaction,
                            ),
                          ),
                          SiahehGlassChip(
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              size: 16,
                            ),
                            label: bankSmsKindLabel(BankSmsKind.info),
                            selected: _kind == BankSmsKind.info,
                            onTap: () =>
                                setState(() => _kind = BankSmsKind.info),
                          ),
                          SiahehGlassChip(
                            icon: const Icon(Icons.password_rounded, size: 16),
                            label: bankSmsKindLabel(BankSmsKind.otp),
                            selected: _kind == BankSmsKind.otp,
                            onTap: () =>
                                setState(() => _kind = BankSmsKind.otp),
                          ),
                          SiahehGlassChip(
                            icon: const Icon(
                              Icons.help_outline_rounded,
                              size: 16,
                            ),
                            label: bankSmsKindLabel(BankSmsKind.unparsed),
                            selected: _kind == BankSmsKind.unparsed,
                            onTap: () =>
                                setState(() => _kind = BankSmsKind.unparsed),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SheetSectionTitle('بازه زمانی'),
                    const SizedBox(height: 8),
                    _DateFilterSection(
                      dateFilter: _dateFilter,
                      onSelected: (f) => setState(() => _dateFilter = f),
                      onOpenJalaliPicker: () =>
                          setState(() => _pickingDate = true),
                    ),
                    if (widget.banks.length > 1) ...[
                      const SizedBox(height: 16),
                      const _SheetSectionTitle('بانک'),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 48,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: widget.banks.length + 1,
                        itemBuilder: (_, idx) {
                          if (idx == 0) {
                            return _BankGridTile(
                              label: 'همه بانک‌ها',
                              selected: _bankKey == null,
                              onTap: () => setState(() => _bankKey = null),
                            );
                          }
                          final UiBank bank = widget.banks[idx - 1];
                          return _BankGridTile(
                            bankKey: bank.key,
                            label: bank.name,
                            trailingCount: widget.messageCountForBank(bank.key),
                            selected: _bankKey == bank.key,
                            onTap: () => setState(() => _bankKey = bank.key),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    SiahehPrimaryGlassButton(
                      label: 'اعمال فیلتر',
                      icon: Icons.check_rounded,
                      onTap: () => Navigator.of(context).pop(_current),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.showClear,
    required this.onClear,
  });

  final String title;
  final bool showClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Row(
      children: [
        Icon(Icons.filter_alt_rounded, color: scheme.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showClear)
          SiahehGlassChip(
            label: 'پاک کردن',
            selected: false,
            onTap: onClear,
          ),
      ],
    );
  }
}

class _SheetSectionTitle extends StatelessWidget {
  const _SheetSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
      ),
    );
  }
}

class _DateFilterSection extends StatelessWidget {
  const _DateFilterSection({
    required this.dateFilter,
    required this.onSelected,
    required this.onOpenJalaliPicker,
  });

  final JalaliDateFilter dateFilter;
  final ValueChanged<JalaliDateFilter> onSelected;
  final VoidCallback onOpenJalaliPicker;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final JalaliDateFilter thisMonth = JalaliDateFilter.thisMonth();
    final JalaliDateFilter lastMonth = JalaliDateFilter.lastMonth();
    final bool isCustomPeriod =
        (dateFilter.kind == JalaliFilterKind.month &&
            !dateFilter.isSameMonthAs(thisMonth) &&
            !dateFilter.isSameMonthAs(lastMonth)) ||
        dateFilter.kind == JalaliFilterKind.year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassBackdropGroup(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SiahehGlassChip(
                label: 'همه زمان‌ها',
                selected: !dateFilter.isActive,
                onTap: () => onSelected(const JalaliDateFilter.all()),
              ),
              SiahehGlassChip(
                label: 'امروز',
                selected: dateFilter.kind == JalaliFilterKind.today,
                onTap: () => onSelected(const JalaliDateFilter.today()),
              ),
              SiahehGlassChip(
                label: '۷ روز اخیر',
                selected: dateFilter.kind == JalaliFilterKind.last7Days,
                onTap: () => onSelected(const JalaliDateFilter.last7Days()),
              ),
              SiahehGlassChip(
                label: 'این ماه',
                selected: dateFilter.isSameMonthAs(thisMonth),
                onTap: () => onSelected(thisMonth),
              ),
              SiahehGlassChip(
                label: 'ماه قبل',
                selected: dateFilter.isSameMonthAs(lastMonth),
                onTap: () => onSelected(lastMonth),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SiahehGlassCard(
          radius: 16,
          tintColor: isCustomPeriod ? scheme.primary : null,
          borderColor: isCustomPeriod
              ? scheme.primary.withValues(alpha: 0.78)
              : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onOpenJalaliPicker,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: isCustomPeriod
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCustomPeriod
                          ? 'بازه انتخاب‌شده: ${dateFilter.label}'
                          : 'انتخاب ماه یا سال شمسی',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCustomPeriod
                            ? (isDark ? scheme.primary : scheme.onSurface)
                            : scheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewToggleTile extends StatelessWidget {
  const _ReviewToggleTile({
    required this.selected,
    required this.reviewCount,
    required this.onTap,
  });

  final bool selected;
  final int reviewCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return SiahehGlassCard(
      radius: 16,
      tintColor: selected ? scheme.primary : null,
      borderColor: selected ? scheme.primary.withValues(alpha: 0.78) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                size: 18,
                color: selected
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.72),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'فقط نیازمند بررسی',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? (isDark ? scheme.primary : scheme.onSurface)
                        : scheme.onSurface,
                  ),
                ),
              ),
              if (reviewCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    PersianFormat.digits('$reviewCount'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankGridTile extends StatelessWidget {
  const _BankGridTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.bankKey,
    this.trailingCount,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? bankKey;
  final int? trailingCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return SiahehGlassCard(
      radius: 16,
      tintColor: selected ? scheme.primary : null,
      borderColor: selected ? scheme.primary.withValues(alpha: 0.78) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              if (bankKey != null)
                BankLogo(bankKey: bankKey!, size: 20)
              else
                Icon(
                  Icons.account_balance_rounded,
                  size: 18,
                  color: selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.75),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? (isDark ? scheme.primary : scheme.onSurface)
                        : scheme.onSurface,
                  ),
                ),
              ),
              if (trailingCount != null) ...[
                const SizedBox(width: 4),
                Text(
                  PersianFormat.digits('$trailingCount'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.52),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGridTile extends StatelessWidget {
  const _CategoryGridTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return SiahehGlassCard(
      radius: 18,
      tintColor: selected ? color : null,
      borderColor: selected ? color.withValues(alpha: 0.80) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? (isDark ? Color.lerp(color, Colors.white, 0.35) : color)
                      : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
