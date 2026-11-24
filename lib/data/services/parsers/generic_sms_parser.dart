import 'package:shamsi_date/shamsi_date.dart';
import 'package:siaheh/data/services/parsers/sms_normalizer.dart';
import 'package:siaheh/domain/models/bank_info.dart';
import 'package:siaheh/domain/models/bank_transaction.dart';

/// Result of parsing one SMS body (no sender / id information yet).
class ParsedSms {
  const ParsedSms({
    required this.accountNumber,
    required this.amountRial,
    required this.type,
    required this.occurredAt,
    this.balanceRial,
    this.suggestedTitle,
    this.needsReview = false,
  });

  final String accountNumber;
  final int amountRial;
  final TransactionType type;
  final DateTime occurredAt;
  final int? balanceRial;
  final String? suggestedTitle;
  final bool needsReview;
}

/// Smart universal parser for Iranian bank transaction SMS messages.
///
/// Handles:
/// - Signed line-based layouts (e.g. Bank Melli `+4,300,000` / `-120,000`)
/// - Keyword-based Persian layouts (`واریز`, `برداشت`, `خرید`, `انتقال`, `بستانکار`, `بدهکار`)
/// - Automatic ریال vs تومان conversion (stored internally in Rials)
/// - Account numbers, masked card numbers, or fallback to `'اصلی'`
/// - Jalali dates in body (`YYYY/MM/DD`, `YY/MM/DD`, `MM/DD`) with fallback to
///   the SMS delivery timestamp.
class GenericSmsParser {
  const GenericSmsParser({this._nowJalali});

  final Jalali Function()? _nowJalali;

  static const String defaultAccountLabel = BankTransaction.defaultAccountLabel;

  // --- OTP / non-transaction detection ---
  static final RegExp _otpRegex = RegExp(
    r'(رمز\s*(?:پویا|دوم|یکبار\s*مصرف|ورود)|کد\s*(?:تایید|تائید|فعال\s*سازی|احراز|امنیتی)|\bOTP\b|محرمانه\s*است|در\s*اختیار\s*دیگران\s*قرار\s*ندهید)',
    caseSensitive: false,
  );

  // --- Signed amount: `+4,300,000` or `-120,000` (optionally with currency) ---
  static final RegExp _signedAmount = RegExp(
    r'(?<![\d/:])([+\-])\s*([\d,]{3,})(?:\s*(تومان|تومن|ریال))?',
  );

  // --- Labeled amount: `مبلغ: 500,000 ریال`, `واریز 250,000 تومان`, etc. ---
  static final RegExp _labeledAmount = RegExp(
    r'(?:مبلغ|واریز|برداشت|خرید|انتقال|پرداخت|بدهکار|بستانکار|کسر|افزایش|کاهش)\s*(?:به\s*مبلغ)?\s*[:：]?\s*([+\-])?\s*([\d,]{3,})\s*(تومان|تومن|ریال)?',
  );

  // --- Amount with explicit currency suffix ---
  static final RegExp _currencyAmount = RegExp(
    r'([+\-])?\s*([\d,]{3,})\s*(تومان|تومن|ریال)',
  );

  // --- Ad / promo rejection ---
  static final RegExp _adFooterRegex = RegExp(r'لغو\s*=?\s*11');

  // --- Balance patterns (never matches telecom "مانده اعتبار" / "مانده بسته" etc.) ---
  static final RegExp _balanceRegex = RegExp(
    r'(?:مانده|موجودی|باقی\s*مانده)\s*(?!اعتبار|بسته|حجم|اینترنت|مکالمه|پیامک|امتیاز)(?:فعلی|حساب|سپرده|کل|قابل\s*برداشت)?\s*[:：]?\s*([\d,]+)\s*(تومان|تومن|ریال)?',
  );

  // --- Account & card extraction ---
  static final RegExp _labeledAccount = RegExp(
    r'(?:حساب|سپرده)\s*(?:شماره|به\s*شماره)?\s*[:：]?\s*([\d\.\-\*]{4,24})',
  );
  static final RegExp _rawAccount = RegExp(r'(?<![\d,/:\-])(\d{8,20})(?![\d,/:\-])');
  static final RegExp _maskedCard = RegExp(
    r'(?:کارت\s*[:：]?\s*)?(?:\d{4,6}\s*[\*xX\-]{2,8}\s*(\d{4})|[\*]{2,6}(\d{4})|کارت\s*(?:به\s*شماره\s*)?[:：]?\s*(\d{4})\b)',
  );

  // --- Jalali Date & Time patterns ---
  static final RegExp _dateTime = RegExp(
    r'(?:(\d{2,4})/)?(\d{1,2})/(\d{1,2})\s*[-_\s]*(\d{1,2}):(\d{2})',
  );
  static final RegExp _dateOnly = RegExp(r'(\d{2,4})/(\d{1,2})/(\d{1,2})');
  static final RegExp _timeOnly = RegExp(r'(?:ساعت\s*[:：]?\s*)?(\d{1,2}):(\d{2})');

  // --- Direction keywords ---
  static final RegExp _incomeKeywords = RegExp(
    r'(واریز|بستانکار|افزایش\s*موجودی|دریافت\s*وجه|برگشت\s*(?:وجه|تراکنش)|سود\s*(?:سپرده|حساب)|به\s*حساب\s*(?:شما\s*)?واریز|واریز\s*شد|بستانکاری)',
  );
  static final RegExp _expenseKeywords = RegExp(
    r'(برداشت|بدهکار|کاهش\s*موجودی|خرید|کسر\s*(?:شد|از|وجه|کارمزد)|پرداخت|کارمزد|قسط|انتقال\s*از|از\s*حساب\s*(?:شما\s*)?(?:برداشت|کسر)|بدهکاری|تراکنش\s*خرید)',
  );

  // --- Financial signal check (to detect unparsed transaction SMS) ---
  static final RegExp _financialVerb = RegExp(
    r'(واریز|برداشت|خرید|انتقال|بستانکار|بدهکار|مانده|موجودی|کسر|پرداخت)',
  );

  /// Returns `true` when the SMS is clearly a one-time password / dynamic PIN
  /// and NOT a completed transaction.
  bool isOtpMessage(String body) {
    final text = SmsNormalizer.normalize(body);
    if (!_otpRegex.hasMatch(text)) return false;
    // If it also contains a balance, it might be a receipt with a security note.
    if (_balanceRegex.hasMatch(text)) return false;
    return true;
  }

  /// Returns `true` when a bank SMS appears to describe a financial transaction
  /// (used to classify failed parses as `unparsed` instead of `info`).
  bool looksLikeFinancialTransaction(String body) {
    final text = SmsNormalizer.normalize(body);
    if (_adFooterRegex.hasMatch(text) || isOtpMessage(text)) return false;
    final hasMoney =
        _signedAmount.hasMatch(text) || _currencyAmount.hasMatch(text);
    final hasVerb = _financialVerb.hasMatch(text);
    return hasMoney && hasVerb;
  }

  ParsedSms? parse(
    String body, {
    DateTime? fallbackDate,
    CurrencyUnit defaultCurrency = CurrencyUnit.rial,
  }) {
    final text = SmsNormalizer.normalize(body);
    if (_adFooterRegex.hasMatch(text) || isOtpMessage(text)) return null;

    // 1. Extract balance first so we don't accidentally pick the balance number
    // as the transaction amount.
    final balanceMatch = _balanceRegex.firstMatch(text);
    final balanceRial = _extractBalanceRial(balanceMatch, text, defaultCurrency);

    // Build a version of the text with the balance segment masked out when
    // searching for currency-suffixed amounts.
    final textWithoutBalance = balanceMatch == null
        ? text
        : text.replaceRange(balanceMatch.start, balanceMatch.end, ' ');

    // 2. Extract amount + optional explicit sign + unit.
    final amountInfo = _extractAmount(
      textWithoutBalance,
      fullText: text,
      defaultCurrency: defaultCurrency,
    );
    if (amountInfo == null || amountInfo.amountRial <= 0) return null;

    // 3. Determine transaction direction (income vs expense).
    final type = _resolveType(textWithoutBalance, amountInfo.sign);
    if (type == null) return null;

    // 4. Extract account or card identifier (fallback to 'اصلی' if absent).
    final accountInfo = _extractAccount(text);

    // 5. Extract date/time from body, or fall back to SMS timestamp.
    final occurredAt = _extractDateTime(text) ?? fallbackDate;
    if (occurredAt == null) return null;

    // 6. Infer a clean default Persian title when possible.
    final suggestedTitle = inferTitle(text, type);

    return ParsedSms(
      accountNumber: accountInfo.account,
      amountRial: amountInfo.amountRial,
      type: type,
      occurredAt: occurredAt,
      balanceRial: balanceRial,
      suggestedTitle: suggestedTitle,
      needsReview: amountInfo.ambiguous,
    );
  }

  int? _extractBalanceRial(
    RegExpMatch? m,
    String fullText,
    CurrencyUnit defaultCurrency,
  ) {
    if (m == null) return null;
    final raw = int.tryParse(m.group(1)!.replaceAll(',', ''));
    if (raw == null) return null;
    final unit = _detectCurrencyUnit(
      m.group(2),
      fullText: fullText,
      fallback: defaultCurrency,
    );
    return unit == CurrencyUnit.toman ? raw * 10 : raw;
  }

  _AmountExtraction? _extractAmount(
    String textWithoutBalance, {
    required String fullText,
    required CurrencyUnit defaultCurrency,
  }) {
    // Priority 1: explicit +/- signed amount (e.g. `+4,300,000` or `-120,000`).
    final signed = _signedAmount.firstMatch(textWithoutBalance);
    if (signed != null) {
      final raw = int.tryParse(signed.group(2)!.replaceAll(',', ''));
      if (raw != null && raw > 0) {
        final unit = _detectCurrencyUnit(
          signed.group(3),
          fullText: fullText,
          fallback: defaultCurrency,
        );
        return _AmountExtraction(
          amountRial: unit == CurrencyUnit.toman ? raw * 10 : raw,
          sign: signed.group(1),
        );
      }
    }

    // Priority 2: labeled amount (`مبلغ: 500,000 ریال`, `واریز: 200,000`).
    final labeled = _labeledAmount.firstMatch(textWithoutBalance);
    if (labeled != null) {
      final raw = int.tryParse(labeled.group(2)!.replaceAll(',', ''));
      if (raw != null && raw > 0) {
        final unit = _detectCurrencyUnit(
          labeled.group(3),
          fullText: fullText,
          fallback: defaultCurrency,
        );
        return _AmountExtraction(
          amountRial: unit == CurrencyUnit.toman ? raw * 10 : raw,
          sign: labeled.group(1),
        );
      }
    }

    // Priority 3: amount with explicit ریال/تومان (outside balance clause).
    final curr = _currencyAmount.firstMatch(textWithoutBalance);
    if (curr != null) {
      final raw = int.tryParse(curr.group(2)!.replaceAll(',', ''));
      if (raw != null && raw > 0) {
        final unit = _detectCurrencyUnit(
          curr.group(3),
          fullText: fullText,
          fallback: defaultCurrency,
        );
        return _AmountExtraction(
          amountRial: unit == CurrencyUnit.toman ? raw * 10 : raw,
          sign: curr.group(1),
          ambiguous: false,
        );
      }
    }

    return null;
  }

  CurrencyUnit _detectCurrencyUnit(
    String? explicitUnit, {
    required String fullText,
    required CurrencyUnit fallback,
  }) {
    if (explicitUnit != null) {
      return explicitUnit.contains('توم')
          ? CurrencyUnit.toman
          : CurrencyUnit.rial;
    }
    if (fullText.contains('تومان') || fullText.contains('تومن')) {
      return CurrencyUnit.toman;
    }
    if (fullText.contains('ریال')) {
      return CurrencyUnit.rial;
    }
    return fallback;
  }

  TransactionType? _resolveType(String text, String? explicitSign) {
    if (explicitSign == '+') return TransactionType.income;
    if (explicitSign == '-') return TransactionType.expense;

    final incMatch = _incomeKeywords.firstMatch(text);
    final expMatch = _expenseKeywords.firstMatch(text);

    if (incMatch != null && expMatch == null) return TransactionType.income;
    if (expMatch != null && incMatch == null) return TransactionType.expense;
    if (incMatch != null && expMatch != null) {
      // Pick whichever keyword appears earlier in the SMS (usually the main action).
      return incMatch.start < expMatch.start
          ? TransactionType.income
          : TransactionType.expense;
    }
    return null;
  }

  _AccountExtraction _extractAccount(String text) {
    // 1. Labeled account (`حساب: 0304...` or `سپرده: 123.456.789`).
    final labeled = _labeledAccount.firstMatch(text);
    if (labeled != null) {
      final cleaned = labeled.group(1)!.replaceAll(RegExp(r'[\.\-]'), '');
      if (cleaned.length >= 4) {
        return _AccountExtraction(account: cleaned, found: true);
      }
    }

    // 2. Standalone 8..20 digit account number (excluding 16-digit card numbers
    // if masked card is present, or accepting it as account/card identifier).
    final raw = _rawAccount.firstMatch(text);
    if (raw != null) {
      return _AccountExtraction(account: raw.group(1)!, found: true);
    }

    // 3. Masked card number (`6037****1234`, `****1234`, `کارت 1234`).
    final card = _maskedCard.firstMatch(text);
    if (card != null) {
      final last4 = card.group(1) ?? card.group(2) ?? card.group(3);
      if (last4 != null && last4.isNotEmpty) {
        return _AccountExtraction(account: 'کارت $last4', found: true);
      }
    }

    // 4. Fallback: bank's primary/main account.
    return const _AccountExtraction(account: defaultAccountLabel, found: false);
  }

  DateTime? _extractDateTime(String text) {
    final full = _dateTime.firstMatch(text);
    if (full != null) {
      return _resolveJalaliDate(
        yearRaw: full.group(1),
        month: int.parse(full.group(2)!),
        day: int.parse(full.group(3)!),
        hour: int.parse(full.group(4)!),
        minute: int.parse(full.group(5)!),
      );
    }

    final dOnly = _dateOnly.firstMatch(text);
    if (dOnly != null) {
      final tOnly = _timeOnly.firstMatch(text);
      return _resolveJalaliDate(
        yearRaw: dOnly.group(1),
        month: int.parse(dOnly.group(2)!),
        day: int.parse(dOnly.group(3)!),
        hour: tOnly == null ? 0 : int.parse(tOnly.group(1)!),
        minute: tOnly == null ? 0 : int.parse(tOnly.group(2)!),
      );
    }
    return null;
  }

  /// Resolves a Jalali date (supporting 2-digit or missing year).
  DateTime? _resolveJalaliDate({
    required String? yearRaw,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    final now = (_nowJalali ?? Jalali.now)();
    var year = now.year;
    if (yearRaw != null) {
      year = int.parse(yearRaw);
      if (yearRaw.length == 2) year += 1400;
      if (year < 1380 || year > 1500) return null;
    }

    try {
      var date = Jalali(year, month, day, hour, minute);
      if (yearRaw == null && date.toDateTime().isAfter(now.toDateTime())) {
        date = Jalali(year - 1, month, day, hour, minute);
      }
      return date.toDateTime();
    } catch (_) {
      return null;
    }
  }

  /// Infers a user-friendly Persian title from transaction keywords.
  static String? inferTitle(String normalizedText, TransactionType type) {
    if (normalizedText.contains('کارمزد')) return 'کارمزد بانکی';
    if (normalizedText.contains('قبض')) return 'پرداخت قبض';
    if (normalizedText.contains('قسط') || normalizedText.contains('تسهیلات')) {
      return 'پرداخت قسط';
    }
    if (normalizedText.contains('خودپرداز') || normalizedText.contains('ATM')) {
      return 'برداشت از خودپرداز';
    }
    if (normalizedText.contains('سود')) return 'واریز سود';
    if (normalizedText.contains('پایا')) {
      return type == TransactionType.income ? 'واریز پایا' : 'انتقال پایا';
    }
    if (normalizedText.contains('ساتنا')) {
      return type == TransactionType.income ? 'واریز ساتنا' : 'انتقال ساتنا';
    }
    if (normalizedText.contains('کارت به کارت') ||
        normalizedText.contains('انتقال')) {
      return type == TransactionType.income ? 'دریافت انتقال وجه' : 'انتقال وجه';
    }
    if (normalizedText.contains('خرید') || normalizedText.contains('پوز')) {
      return 'خرید فروشگاهی';
    }
    if (normalizedText.contains('شارژ') || normalizedText.contains('بسته')) {
      return 'خرید شارژ / اینترنت';
    }
    return null;
  }
}

class _AmountExtraction {
  const _AmountExtraction({
    required this.amountRial,
    this.sign,
    this.ambiguous = false,
  });

  final int amountRial;
  final String? sign;
  final bool ambiguous;
}

class _AccountExtraction {
  const _AccountExtraction({required this.account, required this.found});

  final String account;
  final bool found;
}
