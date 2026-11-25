import 'package:equatable/equatable.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:siaheh/core/utils/persian_format.dart';

/// Granularity of a Jalali (Shamsi) calendar date filter.
enum JalaliFilterKind { all, today, last7Days, month, year }

/// Immutable Jalali date filter shared by Home expense chart, Transactions,
/// and Bank Messages screens.
class JalaliDateFilter extends Equatable {
  const JalaliDateFilter._({
    required this.kind,
    this.year,
    this.month,
  }) : assert(month == null || (month >= 1 && month <= 12));

  const JalaliDateFilter.all() : this._(kind: JalaliFilterKind.all);

  const JalaliDateFilter.today() : this._(kind: JalaliFilterKind.today);

  const JalaliDateFilter.last7Days() : this._(kind: JalaliFilterKind.last7Days);

  const JalaliDateFilter.month({required int year, required int month})
    : this._(kind: JalaliFilterKind.month, year: year, month: month);

  const JalaliDateFilter.year(int year)
    : this._(kind: JalaliFilterKind.year, year: year);

  factory JalaliDateFilter.thisMonth([DateTime? now]) {
    final j = Jalali.fromDateTime(now ?? DateTime.now());
    return JalaliDateFilter.month(year: j.year, month: j.month);
  }

  factory JalaliDateFilter.lastMonth([DateTime? now]) {
    final j = Jalali.fromDateTime(now ?? DateTime.now());
    if (j.month == 1) {
      return JalaliDateFilter.month(year: j.year - 1, month: 12);
    }
    return JalaliDateFilter.month(year: j.year, month: j.month - 1);
  }

  final JalaliFilterKind kind;
  final int? year;
  final int? month;

  static const List<String> persianMonthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  bool get isActive => kind != JalaliFilterKind.all;

  String get label => switch (kind) {
    JalaliFilterKind.all => 'همه زمان‌ها',
    JalaliFilterKind.today => 'امروز',
    JalaliFilterKind.last7Days => '۷ روز اخیر',
    JalaliFilterKind.month => PersianFormat.digits(
      '${persianMonthNames[month! - 1]} $year',
    ),
    JalaliFilterKind.year => PersianFormat.digits('سال $year'),
  };

  /// Compact label suitable for segmented controls (omits year if it matches
  /// the current Jalali year).
  String compactLabel([DateTime? now]) {
    if (kind != JalaliFilterKind.month) return label;
    final currentYear = Jalali.fromDateTime(now ?? DateTime.now()).year;
    final name = persianMonthNames[month! - 1];
    if (year == currentYear) return name;
    return PersianFormat.digits('$name $year');
  }

  bool isSameMonthAs(JalaliDateFilter other) =>
      kind == JalaliFilterKind.month &&
      other.kind == JalaliFilterKind.month &&
      year == other.year &&
      month == other.month;

  bool isAtOrAfterCurrentMonth([DateTime? now]) {
    if (kind != JalaliFilterKind.month) return false;
    final cur = Jalali.fromDateTime(now ?? DateTime.now());
    return year! > cur.year || (year == cur.year && month! >= cur.month);
  }

  JalaliDateFilter nextMonth() {
    assert(kind == JalaliFilterKind.month);
    final y = year!;
    final m = month!;
    return m == 12
        ? JalaliDateFilter.month(year: y + 1, month: 1)
        : JalaliDateFilter.month(year: y, month: m + 1);
  }

  JalaliDateFilter previousMonth() {
    assert(kind == JalaliFilterKind.month);
    final y = year!;
    final m = month!;
    return m == 1
        ? JalaliDateFilter.month(year: y - 1, month: 12)
        : JalaliDateFilter.month(year: y, month: m - 1);
  }

  /// Precomputed half-open Gregorian bounds `[start, endExclusive)` so callers
  /// can filter thousands of records in O(N) without converting each timestamp
  /// to [Jalali].
  (DateTime? start, DateTime? endExclusive) bounds({DateTime? now}) {
    final ref = now ?? DateTime.now();
    switch (kind) {
      case JalaliFilterKind.all:
        return (null, null);
      case JalaliFilterKind.today:
        final start = DateTime(ref.year, ref.month, ref.day);
        return (start, start.add(const Duration(days: 1)));
      case JalaliFilterKind.last7Days:
        final end = DateTime(ref.year, ref.month, ref.day)
            .add(const Duration(days: 1));
        final start = end.subtract(const Duration(days: 7));
        return (start, end);
      case JalaliFilterKind.month:
        final start = Jalali(year!, month!, 1).toDateTime();
        final end = month == 12
            ? Jalali(year! + 1, 1, 1).toDateTime()
            : Jalali(year!, month! + 1, 1).toDateTime();
        return (start, end);
      case JalaliFilterKind.year:
        final start = Jalali(year!, 1, 1).toDateTime();
        final end = Jalali(year! + 1, 1, 1).toDateTime();
        return (start, end);
    }
  }

  bool matches(DateTime dt, {DateTime? now}) {
    final (start, end) = bounds(now: now);
    if (start != null && dt.isBefore(start)) return false;
    if (end != null && !dt.isBefore(end)) return false;
    return true;
  }

  @override
  List<Object?> get props => [kind, year, month];
}
