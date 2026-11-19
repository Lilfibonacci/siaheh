import 'package:siaheh/features/sms/data/parsers/sms_normalizer.dart';
import 'package:siaheh/features/sms/domain/entities/iranian_bank_registry.dart';
import 'package:siaheh/features/sms/domain/entities/sms_sender.dart';

/// Result of running hybrid bank detection on a raw SMS.
class BankDetectionResult {
  const BankDetectionResult({
    required this.isBankSms,
    required this.bankKey,
    this.matchedSender,
    this.blockedByDisabledSender = false,
    this.isOfficialSender = false,
  });

  static const BankDetectionResult notBank = BankDetectionResult(
    isBankSms: false,
    bankKey: IranianBankRegistry.unknownKey,
  );

  /// Whether this SMS originates from a bank.
  final bool isBankSms;

  /// Resolved bank key in [IranianBankRegistry] (or `'unknown'`).
  final String bankKey;

  /// Existing [SmsSender] record if this sender is already saved.
  final SmsSender? matchedSender;

  /// True when the sender is already in the user's list and explicitly disabled.
  final bool blockedByDisabledSender;

  /// True when the sender matched an official [IranianBankRegistry] address
  /// or a manually added user sender.
  final bool isOfficialSender;
}

/// Hybrid Iranian bank SMS detector:
/// 1. Honours manually added senders (always trusted unless disabled).
/// 2. Rejects personal mobile numbers, known telecom/service senders, and ad footers.
/// 3. Matches official [IranianBankRegistry] numeric & alphanumeric sender IDs.
/// 4. Honours previously auto-detected senders (still filtering telecom/non-bank bodies).
/// 5. Falls back to strict banking heuristics for unknown senders.
class BankDetector {
  const BankDetector();

  static final RegExp _adFooterRegex = RegExp(r'لغو\s*=?\s*11');

  static final RegExp _telecomOrNonBankBodyRegex = RegExp(
    r'(?:'
    r'مشترک\s*گرامی'
    r'|(?:گیگابایت|مگابایت|\bGB\b|\bMB\b)'
    r'|(?:سیم\s*کارت|سیمکارت)'
    r'|مانده\s*(?:اعتبار|بسته|حجم|مکالمه|اینترنت|پیامک|امتیاز)'
    r'|اعتبار\s*(?:اصلی|هدیه|مکالمه|باقی\s*مانده)'
    r'|بسته\s*(?:اینترنت|مکالمه|پیامک|ترکیبی|هفتگی|ماهانه|روزانه|شبانه|ساعتی|پیشنهادی)'
    r'|(?:شارژ\s*(?:شگفت|مستقیم|اضطراری)|تمدید\s*خودکار|حجم\s*(?:بسته|اینترنت|باقی\s*مانده)|ترافیک\s*اینترنت|اینترنت\s*همراه)'
    r'|(?:ایرانسل\s*من|همراه\s*من|اپراتور|خط\s*(?:اعتباری|دائمی)|صورتحساب\s*(?:میان\s*دوره|پایان\s*دوره))'
    r'|(?:بیمه\s*(?:نامه|شخص|بدنه|عمر|تکمیلی)|کد\s*تخفیف|تخفیف\s*ویژه|قرعه\s*کشی|سفارش\s*شما|مرسوله\s*پستی|باشگاه\s*مشتریان)'
    r')',
    caseSensitive: false,
  );

  static final RegExp _realBalanceSignal = RegExp(
    r'(?:مانده|موجودی|باقی\s*مانده)\s*(?!اعتبار|بسته|حجم|اینترنت|مکالمه|پیامک|امتیاز)(?:فعلی|حساب|سپرده|کل|قابل\s*برداشت)?\s*[:：]?\s*[\d,]{3,}',
  );

  static final RegExp _signedAmountSignal = RegExp(
    r'(?<![\d/:])[+\-]\s*[\d,]{3,}',
  );

  static final RegExp _bankVerbSignal = RegExp(
    r'(واریز|برداشت|بستانکار|بدهکار)',
  );

  static final RegExp _currencyAmountSignal = RegExp(
    r'[\d,]{3,}\s*(?:ریال|تومان|تومن)',
  );

  static final RegExp _accountOrCardWordSignal = RegExp(
    r'(?:حساب|سپرده|کارت)',
  );

  static final RegExp _accountOrCardIdentifierSignal = RegExp(
    r'(?:حساب|سپرده|کارت\s*(?:به\s*شماره)?)\s*[:：]?\s*[\d\.\-\*]{4,24}|(?<![\d,/:\-])\d{8,20}(?![\d,/:\-])',
  );

  static final RegExp _otpSignal = RegExp(
    r'(رمز\s*(?:پویا|دوم|یکبار\s*مصرف)|کد\s*(?:تایید|امنیتی|ورود)\s*(?:بانک|همراه\s*بانک|موبایل\s*بانک))',
  );

  BankDetectionResult detect({
    required String address,
    required String body,
    required List<SmsSender> knownSenders,
  }) {
    final normalizedBody = SmsNormalizer.normalize(body);

    final existing = knownSenders
        .where((s) => s.matchesAddress(address))
        .firstOrNull;

    // 1. Manually registered user senders take top priority.
    if (existing != null && !existing.autoDetected) {
      if (!existing.enabled) {
        return BankDetectionResult(
          isBankSms: false,
          bankKey: existing.bankKey,
          matchedSender: existing,
          blockedByDisabledSender: true,
        );
      }
      var bankKey = existing.bankKey;
      if (bankKey == IranianBankRegistry.unknownKey) {
        final byBody = IranianBankRegistry.matchBodyBankName(normalizedBody);
        if (byBody != null) bankKey = byBody.key;
      }
      return BankDetectionResult(
        isBankSms: true,
        bankKey: bankKey,
        matchedSender: existing,
        isOfficialSender: true,
      );
    }

    // 2. Hard rejections: personal mobiles, blocked telecom/service senders, ad footers.
    if (IranianBankRegistry.isPersonalPhoneNumber(address) ||
        IranianBankRegistry.isBlockedNonBankSender(address) ||
        _adFooterRegex.hasMatch(normalizedBody)) {
      return BankDetectionResult.notBank;
    }

    // 3. Match official Iranian bank registry by sender address.
    // Official bank senders are NOT blocked by telecom words in the body, so
    // legitimate bank purchases of mobile data/recharge still import cleanly.
    final byAddress = IranianBankRegistry.matchAddress(address);
    if (byAddress != null) {
      if (existing != null && !existing.enabled) {
        return BankDetectionResult(
          isBankSms: false,
          bankKey: existing.bankKey,
          matchedSender: existing,
          blockedByDisabledSender: true,
        );
      }
      return BankDetectionResult(
        isBankSms: true,
        bankKey: byAddress.key,
        matchedSender: existing,
        isOfficialSender: true,
      );
    }

    // 4. Previously auto-detected sender (not on the official address list).
    if (existing != null && existing.autoDetected) {
      if (!existing.enabled) {
        return BankDetectionResult(
          isBankSms: false,
          bankKey: existing.bankKey,
          matchedSender: existing,
          blockedByDisabledSender: true,
        );
      }
      if (_telecomOrNonBankBodyRegex.hasMatch(normalizedBody)) {
        return BankDetectionResult.notBank;
      }
      var bankKey = existing.bankKey;
      if (bankKey == IranianBankRegistry.unknownKey) {
        final byBody = IranianBankRegistry.matchBodyBankName(normalizedBody);
        if (byBody != null) bankKey = byBody.key;
      }
      return BankDetectionResult(
        isBankSms: true,
        bankKey: bankKey,
        matchedSender: existing,
      );
    }

    // 5. Content-based discovery for unknown shortcodes / alphanumeric senders.
    if (_telecomOrNonBankBodyRegex.hasMatch(normalizedBody)) {
      return BankDetectionResult.notBank;
    }

    final byBody = IranianBankRegistry.matchBodyBankName(normalizedBody);
    final hasRealBalance = _realBalanceSignal.hasMatch(normalizedBody);
    final hasSignedAmount = _signedAmountSignal.hasMatch(normalizedBody);
    final hasBankVerb = _bankVerbSignal.hasMatch(normalizedBody);
    final hasCurrencyAmount = _currencyAmountSignal.hasMatch(normalizedBody);
    final hasAccountOrCardWord = _accountOrCardWordSignal.hasMatch(normalizedBody);

    if (byBody != null) {
      final hasBankAnchor =
          hasRealBalance ||
          hasSignedAmount ||
          (hasBankVerb && (hasCurrencyAmount || hasAccountOrCardWord)) ||
          _otpSignal.hasMatch(normalizedBody);

      if (hasBankAnchor) {
        return BankDetectionResult(
          isBankSms: true,
          bankKey: byBody.key,
        );
      }
      return BankDetectionResult.notBank;
    }

    // No explicit bank name in body (e.g. Melli line-based format):
    // require ALL THREE: transaction money movement + real balance + account/card id.
    final hasMovement =
        hasSignedAmount || (hasBankVerb && hasCurrencyAmount);
    final hasAccountIdentifier =
        _accountOrCardIdentifierSignal.hasMatch(normalizedBody);

    if (hasMovement && hasRealBalance && hasAccountIdentifier) {
      return const BankDetectionResult(
        isBankSms: true,
        bankKey: IranianBankRegistry.unknownKey,
      );
    }

    return BankDetectionResult.notBank;
  }
}
