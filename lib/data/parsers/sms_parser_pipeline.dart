import 'package:siaheh/data/parsers/bank_detector.dart';
import 'package:siaheh/data/parsers/bank_specific_parsers.dart';
import 'package:siaheh/data/parsers/generic_sms_parser.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';
import 'package:siaheh/domain/entities/iranian_bank_registry.dart';
import 'package:siaheh/domain/entities/sms_sender.dart';

/// Full outcome of running a raw SMS through detection + two-layer parsing.
class SmsParseOutcome {
  const SmsParseOutcome({
    required this.isBankSms,
    required this.bankKey,
    required this.kind,
    this.parsed,
    this.matchedSender,
    this.blockedByDisabledSender = false,
    this.isOfficialSender = false,
  });

  static const SmsParseOutcome ignored = SmsParseOutcome(
    isBankSms: false,
    bankKey: IranianBankRegistry.unknownKey,
    kind: BankSmsKind.info,
  );

  final bool isBankSms;
  final String bankKey;
  final BankSmsKind kind;
  final ParsedSms? parsed;
  final SmsSender? matchedSender;
  final bool blockedByDisabledSender;
  final bool isOfficialSender;
}

/// Coordinates:
/// 1. Hybrid [BankDetector]
/// 2. OTP classification
/// 3. Bank-specific parser (Layer 1)
/// 4. Smart universal [GenericSmsParser] fallback (Layer 2)
/// 5. Unparsed vs general info classification
class SmsParserPipeline {
  SmsParserPipeline({
    BankDetector? detector,
    GenericSmsParser? genericParser,
    List<BankSpecificParser>? bankParsers,
  }) : _detector = detector ?? const BankDetector(),
       _generic = genericParser ?? const GenericSmsParser() {
    final parsers = bankParsers ??
        [
          MelliSmsParser(_generic),
          BluBankSmsParser(_generic),
          MellatSmsParser(_generic),
          SepahSmsParser(_generic),
          TejaratSmsParser(_generic),
          SaderatSmsParser(_generic),
          SamanSmsParser(_generic),
          PasargadSmsParser(_generic),
        ];
    _bankParserMap = {for (final p in parsers) p.bankKey: p};
  }

  final BankDetector _detector;
  final GenericSmsParser _generic;
  late final Map<String, BankSpecificParser> _bankParserMap;

  SmsParseOutcome process({
    required String address,
    required String body,
    required DateTime receivedAt,
    required List<SmsSender> knownSenders,
  }) {
    final detection = _detector.detect(
      address: address,
      body: body,
      knownSenders: knownSenders,
    );

    if (!detection.isBankSms) {
      return SmsParseOutcome(
        isBankSms: false,
        bankKey: detection.bankKey,
        kind: BankSmsKind.info,
        matchedSender: detection.matchedSender,
        blockedByDisabledSender: detection.blockedByDisabledSender,
      );
    }

    // 1. Classify OTP / dynamic password SMS.
    if (_generic.isOtpMessage(body)) {
      return SmsParseOutcome(
        isBankSms: true,
        bankKey: detection.bankKey,
        kind: BankSmsKind.otp,
        matchedSender: detection.matchedSender,
        isOfficialSender: detection.isOfficialSender,
      );
    }

    // 2. Layer 1: Try bank-specific parser if registered.
    final bankInfo = IranianBankRegistry.byKey(detection.bankKey);
    final specific = _bankParserMap[detection.bankKey];
    ParsedSms? parsed = specific?.parse(body, fallbackDate: receivedAt);

    // 3. Layer 2: Fallback to smart universal parser.
    parsed ??= _generic.parse(
      body,
      fallbackDate: receivedAt,
      defaultCurrency: bankInfo.defaultCurrency,
    );

    if (parsed != null) {
      return SmsParseOutcome(
        isBankSms: true,
        bankKey: detection.bankKey,
        kind: BankSmsKind.transaction,
        parsed: parsed,
        matchedSender: detection.matchedSender,
        isOfficialSender: detection.isOfficialSender,
      );
    }

    // 4. Not parsed as a transaction: distinguish failed financial parse vs
    // general informational notification.
    final kind = _generic.looksLikeFinancialTransaction(body)
        ? BankSmsKind.unparsed
        : BankSmsKind.info;

    return SmsParseOutcome(
      isBankSms: true,
      bankKey: detection.bankKey,
      kind: kind,
      matchedSender: detection.matchedSender,
      isOfficialSender: detection.isOfficialSender,
    );
  }
}
