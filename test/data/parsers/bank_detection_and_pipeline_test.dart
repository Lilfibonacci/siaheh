import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:siaheh/data/parsers/generic_sms_parser.dart';
import 'package:siaheh/data/parsers/sms_parser_pipeline.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';
import 'package:siaheh/domain/entities/iranian_bank_registry.dart';
import 'package:siaheh/domain/entities/sms_sender.dart';
import 'package:siaheh/core/utils/bank_icon_resolver.dart';

void main() {
  final pipeline = SmsParserPipeline(
    genericParser: GenericSmsParser(nowJalali: () => Jalali(1405, 8, 6, 12)),
  );
  final now = DateTime(2026, 10, 28, 12, 0);

  group('IranianBankRegistry & SmsSender matching', () {
    test('matches numeric and alphanumeric senders', () {
      expect(IranianBankRegistry.matchAddress('+9830007100')?.key, 'mellat');
      expect(IranianBankRegistry.matchAddress('BluBank')?.key, 'blubank');
      expect(IranianBankRegistry.matchAddress('BankMelli')?.key, 'melli');
      expect(IranianBankRegistry.matchAddress('TEJARAT')?.key, 'tejarat');
      expect(IranianBankRegistry.matchAddress('PostBank')?.key, 'postbank');
    });

    test('rejects telecom and non-bank sender IDs', () {
      expect(IranianBankRegistry.isBlockedNonBankSender('Irancell'), isTrue);
      expect(IranianBankRegistry.isBlockedNonBankSender('MTN-Irancell'), isTrue);
      expect(IranianBankRegistry.isBlockedNonBankSender('MCI'), isTrue);
      expect(IranianBankRegistry.isBlockedNonBankSender('HamrahAval'), isTrue);
      expect(IranianBankRegistry.isBlockedNonBankSender('Rightel'), isTrue);
      expect(IranianBankRegistry.isBlockedNonBankSender('9990'), isTrue);
      expect(IranianBankRegistry.isBlockedNonBankSender('700'), isTrue);
      expect(IranianBankRegistry.isBlockedNonBankSender('+989990'), isTrue);
      expect(IranianBankRegistry.isBlockedNonBankSender('+98700'), isTrue);
      expect(IranianBankRegistry.isBlockedNonBankSender('BimehMellat'), isTrue);
      expect(IranianBankRegistry.isBlockedNonBankSender('PostBank'), isFalse);
      expect(IranianBankRegistry.matchAddress('BimehMellat'), isNull);
      expect(IranianBankRegistry.matchAddress('Shahrdari'), isNull);
    });

    test('identifies personal Iranian mobile numbers', () {
      expect(IranianBankRegistry.isPersonalPhoneNumber('09121234567'), isTrue);
      expect(IranianBankRegistry.isPersonalPhoneNumber('+989121234567'), isTrue);
      expect(IranianBankRegistry.isPersonalPhoneNumber('9121234567'), isTrue);
      expect(IranianBankRegistry.isPersonalPhoneNumber('+9830007100'), isFalse);
      expect(IranianBankRegistry.isPersonalPhoneNumber('+9899991000'), isFalse);
      expect(IranianBankRegistry.isPersonalPhoneNumber('BluBank'), isFalse);
    });

    test('SmsSender matches both numeric prefixes and alphanumeric IDs', () {
      const blu = SmsSender(number: 'BluBank', bankKey: 'blubank');
      expect(blu.matchesAddress('blubank'), isTrue);
      expect(blu.matchesAddress('Blu Bank'), isTrue);
      expect(blu.matchesAddress('+9830007100'), isFalse);

      const mellat = SmsSender(number: '+9830007100', bankKey: 'mellat');
      expect(mellat.matchesAddress('30007100'), isTrue);
      expect(mellat.matchesAddress('009830007100'), isTrue);
      expect(mellat.matchesAddress('\u200E+9830007100\u200F'), isTrue);
    });

    test('SmsSender.canonicalAddress strips bidi marks and handles non-ASCII safely', () {
      expect(
        SmsSender.canonicalAddress('\u200E+9830007100\u200F'),
        '30007100',
      );
      expect(
        SmsSender.canonicalAddress('\u202A BluBank \u202C'),
        'BluBank',
      );
      expect(
        SmsSender.canonicalAddress('\u200Fبانک ملی\u200E'),
        'بانک ملی',
      );
    });

    test('BankIconResolver keeps autocomplete search working for user input', () {
      expect(BankIconResolver.resolve('آینده'), 'ayandeh');
      expect(BankIconResolver.resolve('ملی'), 'melli');
      expect(BankIconResolver.resolve('بلو'), 'blubank');
    });
  });

  group('SmsParserPipeline multi-bank detection & classification', () {
    test('auto-detects and parses BluBank transaction in Toman', () {
      final outcome = pipeline.process(
        address: 'BluBank',
        body: 'برداشت از حساب به مبلغ 120,000 تومان\nموجودی: 2,500,000 تومان',
        receivedAt: now,
        knownSenders: const [],
      );
      expect(outcome.isBankSms, isTrue);
      expect(outcome.bankKey, 'blubank');
      expect(outcome.kind, BankSmsKind.transaction);
      expect(outcome.parsed!.amountRial, 1200000);
      expect(outcome.parsed!.balanceRial, 25000000);
      expect(outcome.parsed!.type, TransactionType.expense);
    });

    test('auto-detects unknown shortcode via body bank name + signals', () {
      final outcome = pipeline.process(
        address: '+98987654',
        body: 'بانک رسالت\nواریز به حساب 1020304050\nمبلغ: 5,000,000 ریال\nمانده: 12,000,000 ریال',
        receivedAt: now,
        knownSenders: const [],
      );
      expect(outcome.isBankSms, isTrue);
      expect(outcome.bankKey, 'resalat');
      expect(outcome.kind, BankSmsKind.transaction);
      expect(outcome.parsed!.type, TransactionType.income);
      expect(outcome.parsed!.amountRial, 5000000);
    });

    test('keeps bank OTP and info messages visible as non-transaction bank SMS', () {
      final otp = pipeline.process(
        address: 'BankMelli',
        body: 'بانک ملی\nرمز پویا: 654321\nمبلغ 300,000 ریال',
        receivedAt: now,
        knownSenders: const [],
      );
      expect(otp.isBankSms, isTrue);
      expect(otp.bankKey, 'melli');
      expect(otp.kind, BankSmsKind.otp);
      expect(otp.parsed, isNull);

      final info = pipeline.process(
        address: '+9830007100',
        body: 'مشتری گرامی بانک ملت، ورود شما به همراه بانک ثبت شد.',
        receivedAt: now,
        knownSenders: const [],
      );
      expect(info.isBankSms, isTrue);
      expect(info.bankKey, 'mellat');
      expect(info.kind, BankSmsKind.info);
      expect(info.parsed, isNull);
    });

    test('ignores personal mobile SMS even with banking words', () {
      final outcome = pipeline.process(
        address: '+989121234567',
        body: 'سلام 500,000 تومان برات به بانک ملی واریز کردم',
        receivedAt: now,
        knownSenders: const [],
      );
      expect(outcome.isBankSms, isFalse);
    });

    test('respects explicitly disabled sender', () {
      final outcome = pipeline.process(
        address: 'BluBank',
        body: 'برداشت 100,000 تومان\nموجودی 500,000 تومان',
        receivedAt: now,
        knownSenders: const [
          SmsSender(number: 'BluBank', bankKey: 'blubank', enabled: false),
        ],
      );
      expect(outcome.isBankSms, isFalse);
      expect(outcome.blockedByDisabledSender, isTrue);
    });

    test('rejects telecom operator internet-purchase & balance SMS', () {
      final samples = <(String, String)>[
        (
          'Irancell',
          'مشترک گرامی بسته اینترنت ۵ گیگابایت با مبلغ ۴۵۰,۰۰۰ ریال فعال شد. مانده اعتبار: ۱۲۰,۰۰۰ ریال',
        ),
        (
          'MTNIrancell',
          'خرید بسته اینترنت ماهانه ۱۰ گیگابایت با موفقیت انجام شد. مبلغ 950,000 ریال',
        ),
        (
          'MCI',
          'مشترک گرامی همراه اول، بسته اینترنت شما با مبلغ 320,000 ریال فعال گردید.',
        ),
        (
          'HamrahAval',
          'تمدید خودکار بسته اینترنت انجام شد. مانده بسته: 4 GB',
        ),
        (
          'Rightel',
          'مشترک گرامی رایتل، خرید بسته اینترنت 200,000 ریال با موفقیت انجام شد.',
        ),
        (
          '9990',
          'بسته اینترنت شما فعال شد. مانده اعتبار اصلی: 85,000 ریال',
        ),
        (
          '700',
          'مشترک گرامی خرید بسته اینترنت انجام شد.',
        ),
        (
          '+982000123456',
          'مشترک گرامی بسته اینترنت ۵ گیگابایت با مبلغ ۴۵۰,۰۰۰ ریال فعال شد. مانده اعتبار: ۱۲۰,۰۰۰ ریال',
        ),
      ];

      for (final (address, body) in samples) {
        final outcome = pipeline.process(
          address: address,
          body: body,
          receivedAt: now,
          knownSenders: const [],
        );
        expect(
          outcome.isBankSms,
          isFalse,
          reason: 'Expected telecom SMS from $address to be rejected',
        );
      }
    });

    test('rejects non-bank SMS with common Persian words like آینده/ملی/رفاه/دی/شهر', () {
      final samples = <(String, String)>[
        (
          '50004000',
          'تمدید اشتراک ماه آینده به مبلغ 250,000 تومان با موفقیت انجام شد.',
        ),
        (
          '300012345',
          'ثبت نام کد ملی شما تایید شد. مبلغ پرداختی 150,000 ریال',
        ),
        (
          '30009988',
          'خرید شما از فروشگاه رفاه به مبلغ 620,000 تومان ثبت شد.',
        ),
        (
          '50002211',
          'صورتحساب مورخ ۱۵ دی به مبلغ 400,000 تومان صادر شد.',
        ),
        (
          '10004567',
          'شهرداری منطقه ۲: عوارض نوسازی به مبلغ 1,200,000 ریال دریافت شد.',
        ),
      ];

      for (final (address, body) in samples) {
        final outcome = pipeline.process(
          address: address,
          body: body,
          receivedAt: now,
          knownSenders: const [],
        );
        expect(
          outcome.isBankSms,
          isFalse,
          reason: 'Expected non-bank SMS from $address ($body) to be rejected',
        );
      }
    });

    test('rejects insurance SMS and promotional لغو11 ads even mentioning a bank', () {
      final insuranceSamples = <(String, String)>[
        (
          'BimehMellat',
          'بیمه ملت: اقساط بیمه نامه شما به مبلغ 2,500,000 ریال پرداخت شد.',
        ),
        (
          'BimehSaman',
          'بیمه سامان: تمدید بیمه بدنه خودرو با مبلغ 8,000,000 تومان',
        ),
        (
          'BimehDey',
          'بیمه دی: خسارت شما واریز گردید. مبلغ 5,000,000 ریال',
        ),
        (
          '30007788',
          'قرعه کشی ویژه افتتاح حساب در بانک آینده با جایزه میلیاردی! لغو11',
        ),
      ];

      for (final (address, body) in insuranceSamples) {
        final outcome = pipeline.process(
          address: address,
          body: body,
          receivedAt: now,
          knownSenders: const [],
        );
        expect(
          outcome.isBankSms,
          isFalse,
          reason: 'Expected insurance/ad SMS from $address to be rejected',
        );
      }
    });

    test('still parses genuine bank debit SMS for purchasing an internet package', () {
      final mellatOutcome = pipeline.process(
        address: '+9830007100',
        body: 'بانک ملت\nبرداشت مبلغ 450,000 ریال بابت خرید بسته اینترنت\nمانده: 12,000,000 ریال',
        receivedAt: now,
        knownSenders: const [],
      );
      expect(mellatOutcome.isBankSms, isTrue);
      expect(mellatOutcome.bankKey, 'mellat');
      expect(mellatOutcome.kind, BankSmsKind.transaction);
      expect(mellatOutcome.parsed!.type, TransactionType.expense);
      expect(mellatOutcome.parsed!.amountRial, 450000);
      expect(mellatOutcome.parsed!.balanceRial, 12000000);

      final bluOutcome = pipeline.process(
        address: 'BluBank',
        body: 'بلو\nبرداشت پول بابت خرید بسته اینترنت\nمبلغ: 45,000 تومان\nموجودی: 1,200,000 تومان',
        receivedAt: now,
        knownSenders: const [],
      );
      expect(bluOutcome.isBankSms, isTrue);
      expect(bluOutcome.bankKey, 'blubank');
      expect(bluOutcome.kind, BankSmsKind.transaction);
      expect(bluOutcome.parsed!.type, TransactionType.expense);
      expect(bluOutcome.parsed!.amountRial, 450000);
      expect(bluOutcome.parsed!.balanceRial, 12000000);
    });
  });
}
