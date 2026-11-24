import 'package:siaheh/domain/models/bank_info.dart';

/// Single source of truth for Iranian banks, their icon keys, search aliases,
/// unambiguous SMS body identifiers, and known numeric/alphanumeric sender
/// addresses.
class IranianBankRegistry {
  const IranianBankRegistry._();

  static const String unknownKey = 'unknown';

  static const BankInfo unknownBank = BankInfo(
    key: unknownKey,
    name: 'بانک ناشناس',
    hasLogoAsset: false,
  );

  static const Set<String> _blockedNumericSenders = {
    '700',
    '9990',
    '9999',
    '7070',
    '8080',
    '2020',
    '4444',
    '111',
    '195',
    '118',
    '110',
    '115',
    '125',
    '724',
    '780',
    '733',
    '1000',
    '2000',
    '3000',
    '5000',
    '9000',
    '8000',
    '6655',
  };

  /// Exact alphanumeric sender IDs (lowercased, letters only) that belong to
  /// telecom operators, messaging/government platforms, or non-bank services.
  static const Set<String> _blockedExactAlphanumericSenders = {
    'mtn',
    'mci',
    'tci',
    'sana',
    'sanasms',
    'bale',
    'post',
  };

  /// Substring tokens (length >= 5, excluding `'postbank'`) inside
  /// alphanumeric sender IDs that clearly indicate non-bank services.
  static const List<String> _blockedAlphanumericTokens = [
    'irancell',
    'mtnirancell',
    'myirancell',
    'hamrahaval',
    'hamrah',
    'myhamrah',
    'rightel',
    'shatel',
    'mokhaberat',
    'taliya',
    'samantel',
    'aptel',
    'hiweb',
    'asiatech',
    'parsonline',
    'mobinnet',
    'pishgaman',
    'bimeh',
    'snapp',
    'tapsi',
    'digikala',
    'divar',
    'torob',
    'basalam',
    'okala',
    'shahrvand',
    'ofogh',
    'canbo',
    'shahrdari',
    'rubika',
    'eitaa',
    'soroush',
    'filimo',
    'namava',
    'fidibo',
    'alibaba',
    'mrbilit',
    'sheypoor',
    'adliran',
    'sabteahval',
    'tamin',
    'rahvar',
    'police',
    'iranpost',
  ];

  static const List<BankInfo> banks = [
    BankInfo(
      key: 'melli',
      name: 'بانک ملی',
      aliases: ['بانک ملی', 'ملی ایران', 'ملی', 'melli', 'bmi', 'bam'],
      bodyIdentifiers: ['بانک ملی', 'بانک ملی ایران', 'bankmelli'],
      numericSenders: [
        '9899991000',
        '99991000',
        '30009000',
        '20001000',
        '30001000',
      ],
      alphanumericSenders: ['bankmelli', 'melli', 'bmi', 'mellibank'],
    ),
    BankInfo(
      key: 'mellat',
      name: 'بانک ملت',
      aliases: ['بانک ملت', 'ملت', 'mellat'],
      bodyIdentifiers: ['بانک ملت', 'bankmellat'],
      numericSenders: ['30007100', '9830007100'],
      alphanumericSenders: ['bankmellat', 'mellat', 'melat'],
    ),
    BankInfo(
      key: 'blubank',
      name: 'بلوبانک',
      aliases: ['بلوبانک', 'بلو بانک', 'بلو', 'blubank', 'blu'],
      bodyIdentifiers: ['بلوبانک', 'بلو بانک', 'blubank'],
      numericSenders: ['9820004000', '20004000', '9830004000'],
      alphanumericSenders: ['blubank', 'blu', 'blubankir'],
      defaultCurrency: CurrencyUnit.toman,
    ),
    BankInfo(
      key: 'sepah',
      name: 'بانک سپه',
      aliases: ['بانک سپه', 'سپه', 'sepah', 'omidbank'],
      bodyIdentifiers: ['بانک سپه', 'banksepah'],
      numericSenders: ['50002090', '20002090', '30002090', '9850002090'],
      alphanumericSenders: ['banksepah', 'sepah'],
    ),
    BankInfo(
      key: 'saderat',
      name: 'بانک صادرات',
      aliases: ['بانک صادرات', 'صادرات', 'سپهر', 'saderat', 'bsi'],
      bodyIdentifiers: ['بانک صادرات', 'بانک صادرات ایران', 'banksaderat'],
      numericSenders: ['90001234', '20001090', '30001090'],
      alphanumericSenders: ['saderat', 'banksaderat', 'bsi'],
    ),
    BankInfo(
      key: 'tejarat',
      name: 'بانک تجارت',
      aliases: ['بانک تجارت', 'تجارت', 'tejarat'],
      bodyIdentifiers: ['بانک تجارت', 'banktejarat', 'tejaratbank'],
      numericSenders: ['20001554', '30001554', '9820001554'],
      alphanumericSenders: ['tejarat', 'banktejarat', 'tejaratbank'],
    ),
    BankInfo(
      key: 'saman',
      name: 'بانک سامان',
      aliases: ['بانک سامان', 'سامان', 'saman', 'sb24'],
      bodyIdentifiers: ['بانک سامان', 'samanbank'],
      numericSenders: ['30008800', '20008800', '30006422'],
      alphanumericSenders: ['saman', 'samanbank', 'sb24'],
    ),
    BankInfo(
      key: 'pasargad',
      name: 'بانک پاسارگاد',
      aliases: [
        'بانک پاسارگاد',
        'پاسارگاد',
        'ویپاد',
        'pasargad',
        'bpi',
        'wepod',
      ],
      bodyIdentifiers: ['بانک پاسارگاد', 'ویپاد', 'bankpasargad', 'wepod'],
      numericSenders: ['30002222', '20002222', '9830002222', '20008289'],
      alphanumericSenders: ['pasargad', 'bankpasargad', 'bpi', 'wepod'],
    ),
    BankInfo(
      key: 'parsian',
      name: 'بانک پارسیان',
      aliases: ['بانک پارسیان', 'پارسیان', 'parsian', 'pec'],
      bodyIdentifiers: ['بانک پارسیان', 'parsianbank'],
      numericSenders: ['20003333', '30003333', '30000033'],
      alphanumericSenders: ['parsian', 'parsianbank'],
    ),
    BankInfo(
      key: 'keshavarzi',
      name: 'بانک کشاورزی',
      aliases: ['بانک کشاورزی', 'کشاورزی', 'keshavarzi', 'bki'],
      bodyIdentifiers: ['بانک کشاورزی', 'bankkeshavarzi'],
      numericSenders: ['20000911', '30000911', '2000911'],
      alphanumericSenders: ['keshavarzi', 'bki', 'bankkeshavarzi'],
    ),
    BankInfo(
      key: 'maskan',
      name: 'بانک مسکن',
      aliases: ['بانک مسکن', 'مسکن', 'maskan'],
      bodyIdentifiers: ['بانک مسکن', 'bankmaskan'],
      numericSenders: ['30002468', '20002468', '30001400'],
      alphanumericSenders: ['maskan', 'bankmaskan'],
    ),
    BankInfo(
      key: 'refah',
      name: 'بانک رفاه',
      aliases: ['بانک رفاه', 'رفاه کارگران', 'رفاه', 'refah'],
      bodyIdentifiers: ['بانک رفاه', 'بانک رفاه کارگران', 'bankrefah'],
      numericSenders: ['20008525', '30008525'],
      alphanumericSenders: ['refahbank', 'bankrefah'],
    ),
    BankInfo(
      key: 'ayandeh',
      name: 'بانک آینده',
      aliases: ['بانک آینده', 'آینده', 'آبانت', 'ayandeh'],
      bodyIdentifiers: ['بانک آینده', 'ayandehbank', 'bankayandeh'],
      numericSenders: ['20002766', '30002766'],
      alphanumericSenders: ['ayandehbank', 'bankayandeh'],
    ),
    BankInfo(
      key: 'shahr',
      name: 'بانک شهر',
      aliases: ['بانک شهر', 'شهر', 'shahr'],
      bodyIdentifiers: ['بانک شهر', 'shahrbank', 'bankshahr'],
      numericSenders: ['20008655', '30008655'],
      alphanumericSenders: ['shahrbank', 'bankshahr'],
    ),
    BankInfo(
      key: 'resalat',
      name: 'بانک رسالت',
      aliases: ['قرض الحسنه رسالت', 'بانک رسالت', 'رسالت', 'resalat', 'rqbank'],
      bodyIdentifiers: ['بانک رسالت', 'قرض الحسنه رسالت', 'rqbank'],
      numericSenders: ['20004747', '30004747', '50004747'],
      alphanumericSenders: ['resalat', 'rqbank'],
    ),
    BankInfo(
      key: 'mehr-iran',
      name: 'بانک مهر ایران',
      aliases: ['قرض الحسنه مهر ایران', 'مهر ایران', 'mehr iran', 'qmb'],
      bodyIdentifiers: ['بانک مهر ایران', 'قرض الحسنه مهر ایران'],
      numericSenders: ['20004356', '30004356'],
      alphanumericSenders: ['mehriran', 'qmb'],
    ),
    BankInfo(
      key: 'eghtesad-novin',
      name: 'بانک اقتصاد نوین',
      aliases: ['اقتصاد نوین', 'eghtesad novin', 'eghtesadnovin', 'enbank'],
      bodyIdentifiers: ['بانک اقتصاد نوین', 'اقتصاد نوین', 'enbank'],
      numericSenders: ['20004803', '30004803'],
      alphanumericSenders: ['enbank', 'eghtesadnovin'],
    ),
    BankInfo(
      key: 'sina',
      name: 'بانک سینا',
      aliases: ['بانک سینا', 'سینا', 'sina', 'sinabank'],
      bodyIdentifiers: ['بانک سینا', 'sinabank', 'banksina'],
      numericSenders: ['20008248', '30008248'],
      alphanumericSenders: ['sinabank', 'banksina'],
    ),
    BankInfo(
      key: 'dey',
      name: 'بانک دی',
      aliases: ['بانک دی', 'دی', 'dey', 'daybank'],
      bodyIdentifiers: ['بانک دی', 'daybank', 'deybank', 'bankdey'],
      numericSenders: ['20002893', '30002893'],
      alphanumericSenders: ['daybank', 'deybank', 'bankdey'],
    ),
    BankInfo(
      key: 'karafarin',
      name: 'بانک کارآفرین',
      aliases: ['کارآفرین', 'کارافرین', 'karafarin'],
      bodyIdentifiers: ['بانک کارآفرین', 'بانک کارافرین', 'karafarinbank'],
      numericSenders: ['20002364', '30002364'],
      alphanumericSenders: ['karafarin', 'karafarinbank'],
    ),
    BankInfo(
      key: 'gardeshgari',
      name: 'بانک گردشگری',
      aliases: ['بانک گردشگری', 'گردشگری', 'gardeshgari', 'tourismbank'],
      bodyIdentifiers: ['بانک گردشگری', 'tourismbank'],
      numericSenders: ['20002395', '30002395'],
      alphanumericSenders: ['gardeshgari', 'tourismbank'],
    ),
    BankInfo(
      key: 'iran-zamin',
      name: 'بانک ایران زمین',
      aliases: ['ایران زمین', 'iran zamin', 'iranzamin', 'izbank'],
      bodyIdentifiers: ['بانک ایران زمین', 'ایران زمین', 'izbank'],
      numericSenders: ['20002476', '30002476'],
      alphanumericSenders: ['izbank', 'iranzamin'],
    ),
    BankInfo(
      key: 'khavar-mianeh',
      name: 'بانک خاورمیانه',
      aliases: ['خاورمیانه', 'khavar mianeh', 'middleeastbank'],
      bodyIdentifiers: ['بانک خاورمیانه', 'middleeastbank'],
      alphanumericSenders: ['mebank', 'khavarmianeh'],
    ),
    BankInfo(
      key: 'postbank',
      name: 'پست بانک',
      aliases: ['پست بانک', 'postbank'],
      bodyIdentifiers: ['پست بانک', 'postbank'],
      numericSenders: ['20008428', '30008428'],
      alphanumericSenders: ['postbank'],
    ),
    BankInfo(
      key: 'sarmayeh',
      name: 'بانک سرمایه',
      aliases: ['بانک سرمایه', 'سرمایه', 'sarmayeh', 'sbank'],
      bodyIdentifiers: ['بانک سرمایه'],
      alphanumericSenders: ['sarmayeh', 'sbank'],
    ),
    BankInfo(
      key: 'bankino',
      name: 'بانکینو',
      aliases: ['بانکینو', 'bankino'],
      bodyIdentifiers: ['بانکینو', 'bankino'],
      alphanumericSenders: ['bankino'],
      defaultCurrency: CurrencyUnit.toman,
    ),
    BankInfo(
      key: 'sanat-madan',
      name: 'بانک صنعت و معدن',
      aliases: ['صنعت و معدن', 'صنعت معدن', 'sanat madan', 'bim'],
      bodyIdentifiers: ['بانک صنعت و معدن', 'صنعت و معدن'],
      alphanumericSenders: ['sanatmadan'],
    ),
    BankInfo(
      key: 'tosee-taavon',
      name: 'بانک توسعه تعاون',
      aliases: ['توسعه تعاون', 'tosee taavon', 'ttbank'],
      bodyIdentifiers: ['بانک توسعه تعاون', 'توسعه تعاون'],
      alphanumericSenders: ['ttbank', 'toseetaavon'],
    ),
    BankInfo(
      key: 'tosee-saderat',
      name: 'بانک توسعه صادرات',
      aliases: ['توسعه صادرات', 'tosee saderat', 'edbi'],
      bodyIdentifiers: ['بانک توسعه صادرات', 'توسعه صادرات'],
      alphanumericSenders: ['edbi'],
    ),
    BankInfo(
      key: 'melall',
      name: 'موسسه اعتباری ملل',
      aliases: ['اعتباری ملل', 'موسسه ملل', 'ملل', 'melall', 'melal'],
      bodyIdentifiers: ['موسسه اعتباری ملل', 'اعتباری ملل', 'موسسه ملل'],
      alphanumericSenders: ['melal', 'melall'],
    ),
    BankInfo(
      key: 'noor',
      name: 'موسسه نور',
      aliases: ['موسسه نور', 'نور', 'noor'],
      bodyIdentifiers: ['موسسه نور', 'موسسه اعتباری نور', 'noorbank'],
      alphanumericSenders: ['noorbank'],
    ),
    BankInfo(
      key: 'ansar',
      name: 'بانک انصار',
      aliases: ['بانک انصار', 'انصار', 'ansar'],
      bodyIdentifiers: ['بانک انصار'],
    ),
    BankInfo(
      key: 'ghavamin',
      name: 'بانک قوامین',
      aliases: ['بانک قوامین', 'قوامین', 'ghavamin'],
      bodyIdentifiers: ['بانک قوامین'],
    ),
    BankInfo(
      key: 'hekmat',
      name: 'بانک حکمت ایرانیان',
      aliases: ['حکمت ایرانیان', 'بانک حکمت', 'حکمت', 'hekmat'],
      bodyIdentifiers: ['بانک حکمت', 'حکمت ایرانیان'],
    ),
    BankInfo(
      key: 'mehr-eghtesad',
      name: 'بانک مهر اقتصاد',
      aliases: ['مهر اقتصاد', 'mehr eghtesad'],
      bodyIdentifiers: ['بانک مهر اقتصاد', 'مهر اقتصاد'],
    ),
    BankInfo(
      key: 'kosar',
      name: 'موسسه کوثر',
      aliases: ['موسسه کوثر', 'کوثر', 'kosar'],
      bodyIdentifiers: ['موسسه کوثر', 'موسسه اعتباری کوثر'],
    ),
    BankInfo(
      key: 'caspian',
      name: 'موسسه کاسپین',
      aliases: ['موسسه کاسپین', 'کاسپین', 'caspian'],
      bodyIdentifiers: ['موسسه کاسپین', 'موسسه اعتباری کاسپین'],
    ),
    BankInfo(
      key: 'tosee',
      name: 'موسسه توسعه',
      aliases: ['موسسه توسعه', 'tosee'],
      bodyIdentifiers: ['موسسه توسعه'],
    ),
    BankInfo(
      key: 'taavon-eslami',
      name: 'بانک تعاون اسلامی',
      aliases: ['تعاون اسلامی', 'taavon eslami'],
      bodyIdentifiers: ['بانک تعاون اسلامی'],
    ),
    BankInfo(
      key: 'iran-venezuela',
      name: 'بانک ایران ونزوئلا',
      aliases: ['ایران ونزوئلا', 'iran venezuela'],
      bodyIdentifiers: ['بانک ایران ونزوئلا'],
    ),
    BankInfo(
      key: 'iran-europe',
      name: 'بانک ایران اروپا',
      aliases: ['ایران اروپا', 'iran europe'],
      bodyIdentifiers: ['بانک ایران اروپا'],
    ),
    BankInfo(
      key: 'futurebank',
      name: 'فیوچر بانک',
      aliases: ['فیوچر', 'آینده بانک', 'futurebank'],
      bodyIdentifiers: ['فیوچر بانک', 'futurebank'],
    ),
    BankInfo(
      key: 'bank-markazi',
      name: 'بانک مرکزی',
      aliases: ['بانک مرکزی', 'bank markazi', 'cbi'],
      bodyIdentifiers: ['بانک مرکزی'],
      alphanumericSenders: ['cbi'],
    ),
    BankInfo(
      key: 'standard-chartered',
      name: 'استاندارد چارترد',
      aliases: ['استاندارد چارترد', 'standard chartered'],
      bodyIdentifiers: ['استاندارد چارترد', 'standard chartered'],
    ),
  ];

  static final Map<String, BankInfo> _byKeyMap = {
    for (final b in banks) b.key: b,
  };

  static final RegExp _letterRegex = RegExp(r'[a-zA-Z\u0600-\u06FF]');
  static final RegExp _nonDigit = RegExp(r'\D');
  static final RegExp _nonAlpha = RegExp(r'[^a-z]');
  static final RegExp _multiSpace = RegExp(r'\s+');

  /// Pre-normalized `(identifier, bank)` pairs sorted longest-first for fast
  /// SMS body matching without re-normalizing on every message.
  static final List<(String, BankInfo)> _normalizedBodyIdentifiers = () {
    final list = <(String, BankInfo)>[];
    for (final bank in banks) {
      for (final id in bank.bodyIdentifiers) {
        final norm = _normalizeText(id);
        if (norm.isNotEmpty) list.add((norm, bank));
      }
    }
    list.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return list;
  }();

  static final Map<String, BankInfo> _alphanumericSenderMap = {
    for (final bank in banks)
      for (final id in bank.alphanumericSenders) id: bank,
  };

  static final Map<String, BankInfo> _numericSenderMap = {
    for (final bank in banks)
      for (final num in bank.numericSenders) stripIranPrefix(num): bank,
  };

  /// Returns the [BankInfo] for [key], or [unknownBank] if not registered.
  static BankInfo byKey(String key) => _byKeyMap[key] ?? unknownBank;

  /// Whether `assets/icons/banks/$key.svg` exists.
  static bool hasLogo(String key) => _byKeyMap[key]?.hasLogoAsset ?? false;

  /// Returns `true` when [address] looks like a regular Iranian personal mobile
  /// phone number (e.g. `09121234567`, `+989121234567`, `00989121234567`,
  /// `9121234567`), while NOT flagging `+98`-prefixed 8-digit bank shortcodes
  /// such as `+9830007100` or `+9899991000`.
  static bool isPersonalPhoneNumber(String address) {
    final trimmed = address.trim();
    if (_letterRegex.hasMatch(trimmed)) return false;
    final digits = trimmed.replaceAll(_nonDigit, '');
    if (digits.length == 11 && digits.startsWith('09')) return true;
    if (digits.length == 12 && digits.startsWith('989')) return true;
    if (digits.length == 14 && digits.startsWith('00989')) return true;
    if (!trimmed.startsWith('+') &&
        digits.length == 10 &&
        digits.startsWith('9') &&
        !digits.startsWith('98')) {
      return true;
    }
    return false;
  }

  /// Returns `true` when [address] clearly belongs to a telecom operator,
  /// insurance company, messenger, or non-bank platform.
  static bool isBlockedNonBankSender(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return false;

    final alphaNorm = _normalizeAlpha(trimmed);
    if (alphaNorm.isNotEmpty) {
      if (alphaNorm == 'postbank') return false;
      if (_blockedExactAlphanumericSenders.contains(alphaNorm)) return true;
      if (alphaNorm.startsWith('bime')) return true;
      for (final token in _blockedAlphanumericTokens) {
        if (alphaNorm.contains(token)) return true;
      }
      return false;
    }

    final digits = trimmed.replaceAll(_nonDigit, '');
    if (digits.isEmpty) return false;
    final stripped = _stripShortcodeIranPrefix(digits);
    return _blockedNumericSenders.contains(digits) ||
        _blockedNumericSenders.contains(stripped);
  }

  /// Matches an SMS sender address (numeric shortcode or alphanumeric sender ID)
  /// against known Iranian banks using O(1) exact canonical lookup.
  static BankInfo? matchAddress(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty ||
        isPersonalPhoneNumber(trimmed) ||
        isBlockedNonBankSender(trimmed)) {
      return null;
    }

    final alphaNorm = _normalizeAlpha(trimmed);
    if (alphaNorm.isNotEmpty) {
      return _alphanumericSenderMap[alphaNorm];
    }

    final digits = stripIranPrefix(trimmed.replaceAll(_nonDigit, ''));
    if (digits.length < 4) return null;

    return _numericSenderMap[digits];
  }

  /// Scans an SMS body for unambiguous bank names (`bodyIdentifiers`).
  /// Never uses short autocomplete aliases like «آینده», «دی», or «شهر».
  static BankInfo? matchBodyBankName(String normalizedBody) {
    final query = _normalizeText(normalizedBody);
    if (query.isEmpty) return null;

    for (final (normId, bank) in _normalizedBodyIdentifiers) {
      if (query.contains(normId)) return bank;
    }
    return null;
  }

  /// Matches a bank from user search input using [BankInfo.aliases].
  /// When [allowPrefixMatch] is `true` (for search autocomplete), partial
  /// prefixes like `"مل"` also match.
  static BankInfo? matchByName(String input, {bool allowPrefixMatch = false}) {
    final query = _normalizeText(input);
    if (query.isEmpty) return null;

    // 1. Exact alias match.
    for (final bank in banks) {
      if (bank.aliases.any((a) => _normalizeText(a) == query)) {
        return bank;
      }
    }

    // 2. Longest alias contained in / starting with query.
    BankInfo? best;
    var bestLen = 0;
    for (final bank in banks) {
      for (final alias in bank.aliases) {
        final normAlias = _normalizeText(alias);
        if (normAlias.length < 2) continue;

        final bool hit = allowPrefixMatch
            ? query.contains(normAlias) ||
                  (query.length >= 2 && normAlias.startsWith(query))
            : (normAlias.length <= 3
                  ? _containsStandaloneToken(query, normAlias)
                  : query.contains(normAlias));

        if (hit && normAlias.length > bestLen) {
          best = bank;
          bestLen = normAlias.length;
        }
      }
    }
    return best;
  }

  /// Strips leading `0098` or `98` from numeric Iranian shortcodes.
  static String stripIranPrefix(String digits) {
    if (digits.startsWith('0098') && digits.length > 7) {
      return digits.substring(4);
    }
    if (digits.startsWith('98') && digits.length > 6) {
      return digits.substring(2);
    }
    return digits;
  }

  static String _stripShortcodeIranPrefix(String digits) {
    if (digits.startsWith('0098') && digits.length >= 7) {
      return digits.substring(4);
    }
    if (digits.startsWith('98') && digits.length >= 5) {
      return digits.substring(2);
    }
    return digits;
  }

  static String _normalizeAlpha(String input) =>
      input.toLowerCase().replaceAll(_nonAlpha, '');

  static String _normalizeText(String input) {
    var s = input
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('\u200c', ' ')
        .toLowerCase()
        .trim();
    s = s.replaceAll(_multiSpace, ' ');
    return s;
  }

  static bool _containsStandaloneToken(String text, String token) {
    final escaped = RegExp.escape(token);
    return RegExp(
      '(?:^|[\\s:：\\-،,\\(\\)\\.\\n])$escaped(?:[\\s:：\\-،,\\(\\)\\.\\n]|\$)',
    ).hasMatch(text);
  }
}
