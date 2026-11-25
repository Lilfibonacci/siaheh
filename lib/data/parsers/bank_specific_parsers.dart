import 'package:siaheh/data/parsers/generic_sms_parser.dart';
import 'package:siaheh/data/parsers/sms_normalizer.dart';
import 'package:siaheh/domain/entities/bank_info.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';

/// Dedicated parser for a specific Iranian bank.
abstract interface class BankSpecificParser {
  /// Bank key in [IranianBankRegistry].
  String get bankKey;

  /// Attempts to parse [body] using bank-specific rules. Returns `null` to
  /// allow the pipeline to fall back to [GenericSmsParser].
  ParsedSms? parse(String body, {required DateTime fallbackDate});
}

/// Bank Melli (بانک ملی) — handles the classic line-based format:
/// ```
/// 0304546764008
/// +4,300,000
/// 07/6-18:14
/// مانده 4,334,844
/// از 1697
/// ```
class MelliSmsParser implements BankSpecificParser {
  const MelliSmsParser(this._generic);

  final GenericSmsParser _generic;

  @override
  String get bankKey => 'melli';

  @override
  ParsedSms? parse(String body, {required DateTime fallbackDate}) {
    final text = SmsNormalizer.normalize(body);
    final parsed = _generic.parse(
      body,
      fallbackDate: fallbackDate,
      defaultCurrency: CurrencyUnit.rial,
    );
    if (parsed == null) return null;

    // Extract optional counterpart suffix `از 1697` / `به 1697`.
    final counter = RegExp(r'(?:از|به)\s+(\d{4})\b').firstMatch(text);
    if (counter != null && parsed.suggestedTitle == null) {
      final dir = parsed.type == TransactionType.income ? 'واریز از' : 'انتقال به';
      return ParsedSms(
        accountNumber: parsed.accountNumber,
        amountRial: parsed.amountRial,
        type: parsed.type,
        occurredAt: parsed.occurredAt,
        balanceRial: parsed.balanceRial,
        suggestedTitle: '$dir ${counter.group(1)}',
        needsReview: parsed.needsReview,
      );
    }
    return parsed;
  }
}

/// BluBank (بلوبانک) — amounts are almost always reported in **تومان**, and
/// SMS messages usually do not contain an account number (single account).
///
/// Examples:
/// - `بلو\nبرداشت پول\nمبلغ: 250,000 تومان\nموجودی: 1,450,000 تومان`
/// - `مبلغ 1,200,000 ریال به حساب بلو شما واریز شد. موجودی: 5,000,000 ریال`
class BluBankSmsParser implements BankSpecificParser {
  const BluBankSmsParser(this._generic);

  final GenericSmsParser _generic;

  @override
  String get bankKey => 'blubank';

  @override
  ParsedSms? parse(String body, {required DateTime fallbackDate}) {
    return _generic.parse(
      body,
      fallbackDate: fallbackDate,
      defaultCurrency: CurrencyUnit.toman,
    );
  }
}

/// Bank Mellat (بانک ملت) — handles formats like:
/// ```
/// بانک ملت
/// حساب 1234567890
/// برداشت 500,000 ریال
/// مانده 12,500,000 ریال
/// 1405/07/06 14:22
/// ```
class MellatSmsParser implements BankSpecificParser {
  const MellatSmsParser(this._generic);

  final GenericSmsParser _generic;

  @override
  String get bankKey => 'mellat';

  @override
  ParsedSms? parse(String body, {required DateTime fallbackDate}) {
    return _generic.parse(
      body,
      fallbackDate: fallbackDate,
      defaultCurrency: CurrencyUnit.rial,
    );
  }
}

/// Bank Sepah (بانک سپه) — handles Sepah / merged military banks SMS layouts.
class SepahSmsParser implements BankSpecificParser {
  const SepahSmsParser(this._generic);

  final GenericSmsParser _generic;

  @override
  String get bankKey => 'sepah';

  @override
  ParsedSms? parse(String body, {required DateTime fallbackDate}) {
    return _generic.parse(
      body,
      fallbackDate: fallbackDate,
      defaultCurrency: CurrencyUnit.rial,
    );
  }
}

/// Bank Tejarat (بانک تجارت) — handles Tejarat SMS formats (often `برداشت از حساب`
/// or `کارت ...`).
class TejaratSmsParser implements BankSpecificParser {
  const TejaratSmsParser(this._generic);

  final GenericSmsParser _generic;

  @override
  String get bankKey => 'tejarat';

  @override
  ParsedSms? parse(String body, {required DateTime fallbackDate}) {
    return _generic.parse(
      body,
      fallbackDate: fallbackDate,
      defaultCurrency: CurrencyUnit.rial,
    );
  }
}

/// Bank Saderat (بانک صادرات / سپهر).
class SaderatSmsParser implements BankSpecificParser {
  const SaderatSmsParser(this._generic);

  final GenericSmsParser _generic;

  @override
  String get bankKey => 'saderat';

  @override
  ParsedSms? parse(String body, {required DateTime fallbackDate}) {
    return _generic.parse(
      body,
      fallbackDate: fallbackDate,
      defaultCurrency: CurrencyUnit.rial,
    );
  }
}

/// Bank Saman (بانک سامان).
class SamanSmsParser implements BankSpecificParser {
  const SamanSmsParser(this._generic);

  final GenericSmsParser _generic;

  @override
  String get bankKey => 'saman';

  @override
  ParsedSms? parse(String body, {required DateTime fallbackDate}) {
    return _generic.parse(
      body,
      fallbackDate: fallbackDate,
      defaultCurrency: CurrencyUnit.rial,
    );
  }
}

/// Bank Pasargad (بانک پاسارگاد / ویپاد).
class PasargadSmsParser implements BankSpecificParser {
  const PasargadSmsParser(this._generic);

  final GenericSmsParser _generic;

  @override
  String get bankKey => 'pasargad';

  @override
  ParsedSms? parse(String body, {required DateTime fallbackDate}) {
    final text = SmsNormalizer.normalize(body);
    // Wepod (Pasargad neo-bank) sometimes reports amounts in Toman.
    final defaultCurrency =
        text.contains('ویپاد') ? CurrencyUnit.toman : CurrencyUnit.rial;
    return _generic.parse(
      body,
      fallbackDate: fallbackDate,
      defaultCurrency: defaultCurrency,
    );
  }
}
