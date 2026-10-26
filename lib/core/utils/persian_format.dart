import 'package:intl/intl.dart';

/// Display-only helpers. Money is stored in rials and shown in tomans.
class PersianFormat {
  PersianFormat._();

  static const List<String> _faDigits = [
    '۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹', //
  ];

  static final NumberFormat _grouped = NumberFormat('#,##0', 'en');

  /// Converts latin digits in [input] to Persian digits.
  static String digits(String input) => input.replaceAllMapped(
    RegExp(r'\d'),
    (m) => _faDigits[int.parse(m[0]!)],
  );

  /// Rial amount -> grouped Persian toman string (e.g. `۱٬۲۵۰٬۰۰۰`).
  static String toman(int rial) {
    final String text = _grouped.format(rial.abs() ~/ 10).replaceAll(',', '٬');
    return digits(text);
  }
}
