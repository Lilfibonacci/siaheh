/// Utility to normalize Persian/Arabic bank SMS text into a consistent form
/// before regex matching.
class SmsNormalizer {
  const SmsNormalizer._();

  static const String _faDigits = '۰۱۲۳۴۵۶۷۸۹';
  static const String _arDigits = '٠١٢٣٤٥٦٧٨٩';

  /// Converts Persian/Arabic digits to ASCII `0-9`, unifies Arabic `ي`/`ك` to
  /// Persian `ی`/`ک`, strips invisible bidi/ZWNJ marks, and normalizes
  /// thousand separators (`٬`, `،`) to `,`.
  static String normalize(String input) {
    final sb = StringBuffer();
    for (final rune in input.runes) {
      // Strip invisible RTL/LTR directional marks.
      if (rune == 0x200E ||
          rune == 0x200F ||
          (rune >= 0x202A && rune <= 0x202E) ||
          (rune >= 0x2066 && rune <= 0x2069)) {
        continue;
      }
      if (rune == 0x200C) {
        // Replace ZWNJ with a regular space for consistent keyword matching.
        sb.write(' ');
        continue;
      }

      final ch = String.fromCharCode(rune);
      final fi = _faDigits.indexOf(ch);
      if (fi >= 0) {
        sb.write(fi);
        continue;
      }
      final ai = _arDigits.indexOf(ch);
      if (ai >= 0) {
        sb.write(ai);
        continue;
      }

      switch (ch) {
        case '٬':
        case '،':
          sb.write(',');
        case 'ي':
        case 'ى':
          sb.write('ی');
        case 'ك':
          sb.write('ک');
        case '−':
        case '–':
        case '—':
          sb.write('-');
        default:
          sb.write(ch);
      }
    }
    return sb.toString();
  }
}
