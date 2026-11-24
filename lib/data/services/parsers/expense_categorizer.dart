import 'package:siaheh/data/services/parsers/sms_normalizer.dart';
import 'package:siaheh/domain/models/bank_info.dart';
import 'package:siaheh/domain/models/bank_sms_message.dart';
import 'package:siaheh/domain/models/bank_transaction.dart';
import 'package:siaheh/domain/models/category_ids.dart';
import 'package:siaheh/domain/models/category_rule.dart';
import 'package:siaheh/domain/models/iranian_bank_registry.dart';

class _MerchantEntry {
  const _MerchantEntry({
    required this.keyword,
    required this.categoryId,
    required this.displayName,
  });

  final String keyword;
  final String categoryId;
  final String displayName;
}

class _IndexedOtp {
  const _IndexedOtp({
    required this.message,
    required this.normalizedBody,
    required this.rawAmount,
    required this.amountRial,
    required this.hasExplicitUnit,
    required this.extractedAcceptor,
  });

  final BankSmsMessage message;
  final String normalizedBody;
  final int? rawAmount;
  final int? amountRial;
  final bool hasExplicitUnit;
  final String? extractedAcceptor;
}

/// Three-layer Iranian expense categorizer:
/// 1. User-learned [CategoryRule]s (highest priority)
/// 2. Bank OTP (`رمز پویا`) correlation by bank + amount + time window (`[-10m, +2m]`)
/// 3. Built-in Iranian merchant & keyword catalog (compound brands checked first)
class ExpenseCategorizer {
  const ExpenseCategorizer({
    this.maxOtpLeadTime = const Duration(minutes: 10),
    this.maxOtpLagTime = const Duration(minutes: 2),
  });

  final Duration maxOtpLeadTime;
  final Duration maxOtpLagTime;

  static final RegExp _otpAmountRegex = RegExp(
    r'(?:مبلغ|به\s*مبلغ|پرداخت|خرید|انتقال)\s*[:：]?\s*([\d,]{3,})\s*(تومان|تومن|ریال)?|([\d,]{3,})\s*(تومان|تومن|ریال)',
  );

  static final RegExp _acceptorLabelRegex = RegExp(
    r'(?:پذیرنده|فروشگاه|درگاه|سایت|عنوان|بابت|مقصد|نام\s*پذیرنده|خرید\s*از|پرداخت\s*به)\s*[:：]?\s*([^\n\r]+)',
  );

  static final RegExp _acceptorTrailingNoise = RegExp(
    r'\s*(?:مبلغ|به\s*مبلغ|کد|رمز|شماره|تاریخ|ساعت|کارت|حساب|ریال|تومان|تومن).*$',
  );

  static final RegExp _genericAcceptorWords = RegExp(
    r'^(?:خرید|پرداخت|اینترنتی|آنلاین|تراکنش|کارت|حساب|شاپرک|به\s*پرداخت|آپ|سداد|پرداخت\s*الکترونیک)$',
  );

  /// Curated Iranian merchants & banking keywords.
  /// Sorted longest-keyword-first at runtime so compound brands (e.g. `اسنپ فود`,
  /// `اسنپ دکتر`, `اسنپ پی`, `دیجی کالا جت`) always match before `اسنپ` / `دیجی کالا`.
  static const List<_MerchantEntry> _rawCatalog = [
    // --- Compound brands first ---
    _MerchantEntry(keyword: 'اسنپ فود', categoryId: CategoryIds.food, displayName: 'اسنپ‌فود'),
    _MerchantEntry(keyword: 'اسنپفود', categoryId: CategoryIds.food, displayName: 'اسنپ‌فود'),
    _MerchantEntry(keyword: 'snappfood', categoryId: CategoryIds.food, displayName: 'اسنپ‌فود'),
    _MerchantEntry(keyword: 'اسنپ مارکت', categoryId: CategoryIds.food, displayName: 'اسنپ‌مارکت'),
    _MerchantEntry(keyword: 'snappmarket', categoryId: CategoryIds.food, displayName: 'اسنپ‌مارکت'),
    _MerchantEntry(keyword: 'اسنپ اکسپرس', categoryId: CategoryIds.food, displayName: 'اسنپ اکسپرس'),
    _MerchantEntry(keyword: 'اسنپ دکتر', categoryId: CategoryIds.health, displayName: 'اسنپ‌دکتر'),
    _MerchantEntry(keyword: 'snappdoctor', categoryId: CategoryIds.health, displayName: 'اسنپ‌دکتر'),
    _MerchantEntry(keyword: 'اسنپ پی', categoryId: CategoryIds.banking, displayName: 'اسنپ‌پی'),
    _MerchantEntry(keyword: 'snapppay', categoryId: CategoryIds.banking, displayName: 'اسنپ‌پی'),
    _MerchantEntry(keyword: 'اسنپ تریپ', categoryId: CategoryIds.transport, displayName: 'اسنپ‌تریپ'),
    _MerchantEntry(keyword: 'snapptrip', categoryId: CategoryIds.transport, displayName: 'اسنپ‌تریپ'),
    _MerchantEntry(keyword: 'اسنپ باکس', categoryId: CategoryIds.transport, displayName: 'اسنپ‌باکس'),
    _MerchantEntry(keyword: 'تپسی فود', categoryId: CategoryIds.food, displayName: 'تپسی‌فود'),
    _MerchantEntry(keyword: 'دیجی کالا جت', categoryId: CategoryIds.food, displayName: 'دیجی‌کالا جت'),
    _MerchantEntry(keyword: 'دیجی جت', categoryId: CategoryIds.food, displayName: 'دیجی‌کالا جت'),
    _MerchantEntry(keyword: 'فروشگاه رفاه', categoryId: CategoryIds.food, displayName: 'فروشگاه رفاه'),
    _MerchantEntry(keyword: 'بسته اینترنت', categoryId: CategoryIds.internet, displayName: 'بسته اینترنت'),
    _MerchantEntry(keyword: 'خرید شارژ', categoryId: CategoryIds.internet, displayName: 'خرید شارژ'),
    _MerchantEntry(keyword: 'شارژ سیم', categoryId: CategoryIds.internet, displayName: 'شارژ سیم‌کارت'),

    // --- اینترنت و شارژ ---
    _MerchantEntry(keyword: 'ایرانسل', categoryId: CategoryIds.internet, displayName: 'ایرانسل'),
    _MerchantEntry(keyword: 'irancell', categoryId: CategoryIds.internet, displayName: 'ایرانسل'),
    _MerchantEntry(keyword: 'همراه اول', categoryId: CategoryIds.internet, displayName: 'همراه اول'),
    _MerchantEntry(keyword: 'mci', categoryId: CategoryIds.internet, displayName: 'همراه اول'),
    _MerchantEntry(keyword: 'رایتل', categoryId: CategoryIds.internet, displayName: 'رایتل'),
    _MerchantEntry(keyword: 'rightel', categoryId: CategoryIds.internet, displayName: 'رایتل'),
    _MerchantEntry(keyword: 'شاتل', categoryId: CategoryIds.internet, displayName: 'شاتل'),
    _MerchantEntry(keyword: 'shatel', categoryId: CategoryIds.internet, displayName: 'شاتل'),
    _MerchantEntry(keyword: 'مبین نت', categoryId: CategoryIds.internet, displayName: 'مبین‌نت'),
    _MerchantEntry(keyword: 'mobinnet', categoryId: CategoryIds.internet, displayName: 'مبین‌نت'),
    _MerchantEntry(keyword: 'آسیاتک', categoryId: CategoryIds.internet, displayName: 'آسیاتک'),
    _MerchantEntry(keyword: 'asiatech', categoryId: CategoryIds.internet, displayName: 'آسیاتک'),
    _MerchantEntry(keyword: 'های وب', categoryId: CategoryIds.internet, displayName: 'های‌وب'),
    _MerchantEntry(keyword: 'hiweb', categoryId: CategoryIds.internet, displayName: 'های‌وب'),
    _MerchantEntry(keyword: 'پارس آنلاین', categoryId: CategoryIds.internet, displayName: 'پارس‌آنلاین'),
    _MerchantEntry(keyword: 'پیشگامان', categoryId: CategoryIds.internet, displayName: 'پیشگامان'),
    _MerchantEntry(keyword: 'زی تل', categoryId: CategoryIds.internet, displayName: 'زی‌تل'),
    _MerchantEntry(keyword: 'صبانت', categoryId: CategoryIds.internet, displayName: 'صبانت'),
    _MerchantEntry(keyword: 'سامانتل', categoryId: CategoryIds.internet, displayName: 'سامانتل'),
    _MerchantEntry(keyword: 'اینترنت', categoryId: CategoryIds.internet, displayName: 'اینترنت'),
    _MerchantEntry(keyword: 'شارژ', categoryId: CategoryIds.internet, displayName: 'خرید شارژ'),

    // --- حمل‌ونقل ---
    _MerchantEntry(keyword: 'اسنپ', categoryId: CategoryIds.transport, displayName: 'اسنپ'),
    _MerchantEntry(keyword: 'snapp', categoryId: CategoryIds.transport, displayName: 'اسنپ'),
    _MerchantEntry(keyword: 'تپسی', categoryId: CategoryIds.transport, displayName: 'تپسی'),
    _MerchantEntry(keyword: 'tapsi', categoryId: CategoryIds.transport, displayName: 'تپسی'),
    _MerchantEntry(keyword: 'ماکسیم', categoryId: CategoryIds.transport, displayName: 'ماکسیم'),
    _MerchantEntry(keyword: 'maxim', categoryId: CategoryIds.transport, displayName: 'ماکسیم'),
    _MerchantEntry(keyword: 'الوپیک', categoryId: CategoryIds.transport, displayName: 'الوپیک'),
    _MerchantEntry(keyword: 'میاره', categoryId: CategoryIds.transport, displayName: 'میاره'),
    _MerchantEntry(keyword: 'علی بابا', categoryId: CategoryIds.transport, displayName: 'علی‌بابا'),
    _MerchantEntry(keyword: 'alibaba', categoryId: CategoryIds.transport, displayName: 'علی‌بابا'),
    _MerchantEntry(keyword: 'مستربلیط', categoryId: CategoryIds.transport, displayName: 'مستربلیط'),
    _MerchantEntry(keyword: 'mrbilit', categoryId: CategoryIds.transport, displayName: 'مستربلیط'),
    _MerchantEntry(keyword: 'فلایتیو', categoryId: CategoryIds.transport, displayName: 'فلایتیو'),
    _MerchantEntry(keyword: 'flightio', categoryId: CategoryIds.transport, displayName: 'فلایتیو'),
    _MerchantEntry(keyword: 'جاباما', categoryId: CategoryIds.transport, displayName: 'جاباما'),
    _MerchantEntry(keyword: 'رجا', categoryId: CategoryIds.transport, displayName: 'قطار رجا'),
    _MerchantEntry(keyword: 'مترو', categoryId: CategoryIds.transport, displayName: 'مترو'),
    _MerchantEntry(keyword: 'تاکسی', categoryId: CategoryIds.transport, displayName: 'تاکسی'),
    _MerchantEntry(keyword: 'پمپ بنزین', categoryId: CategoryIds.transport, displayName: 'سوخت'),
    _MerchantEntry(keyword: 'جایگاه سوخت', categoryId: CategoryIds.transport, displayName: 'سوخت'),
    _MerchantEntry(keyword: 'بنزین', categoryId: CategoryIds.transport, displayName: 'سوخت'),
    _MerchantEntry(keyword: 'آزادراه', categoryId: CategoryIds.transport, displayName: 'عوارض آزادراه'),
    _MerchantEntry(keyword: 'عوارض', categoryId: CategoryIds.transport, displayName: 'عوارض'),
    _MerchantEntry(keyword: 'پارکینگ', categoryId: CategoryIds.transport, displayName: 'پارکینگ'),
    _MerchantEntry(keyword: 'طرح ترافیک', categoryId: CategoryIds.transport, displayName: 'طرح ترافیک'),

    // --- خوراک ---
    _MerchantEntry(keyword: 'اکالا', categoryId: CategoryIds.food, displayName: 'اکالا'),
    _MerchantEntry(keyword: 'okala', categoryId: CategoryIds.food, displayName: 'اکالا'),
    _MerchantEntry(keyword: 'افق کوروش', categoryId: CategoryIds.food, displayName: 'افق کوروش'),
    _MerchantEntry(keyword: 'هایپراستار', categoryId: CategoryIds.food, displayName: 'هایپراستار'),
    _MerchantEntry(keyword: 'hyperstar', categoryId: CategoryIds.food, displayName: 'هایپراستار'),
    _MerchantEntry(keyword: 'جانبـو', categoryId: CategoryIds.food, displayName: 'جانبو'),
    _MerchantEntry(keyword: 'جانبو', categoryId: CategoryIds.food, displayName: 'جانبو'),
    _MerchantEntry(keyword: 'شهروند', categoryId: CategoryIds.food, displayName: 'فروشگاه شهروند'),
    _MerchantEntry(keyword: 'اتکا', categoryId: CategoryIds.food, displayName: 'فروشگاه اتکا'),
    _MerchantEntry(keyword: 'دیلی مارکت', categoryId: CategoryIds.food, displayName: 'دیلی مارکت'),
    _MerchantEntry(keyword: 'سوپرمارکت', categoryId: CategoryIds.food, displayName: 'سوپرمارکت'),
    _MerchantEntry(keyword: 'هایپرمارکت', categoryId: CategoryIds.food, displayName: 'هایپرمارکت'),
    _MerchantEntry(keyword: 'رستوران', categoryId: CategoryIds.food, displayName: 'رستوران'),
    _MerchantEntry(keyword: 'کافی شاپ', categoryId: CategoryIds.food, displayName: 'کافه'),
    _MerchantEntry(keyword: 'کافه', categoryId: CategoryIds.food, displayName: 'کافه'),
    _MerchantEntry(keyword: 'فست فود', categoryId: CategoryIds.food, displayName: 'فست‌فود'),
    _MerchantEntry(keyword: 'پیتزا', categoryId: CategoryIds.food, displayName: 'پیتزا'),
    _MerchantEntry(keyword: 'کباب', categoryId: CategoryIds.food, displayName: 'رستوران'),
    _MerchantEntry(keyword: 'نانوایی', categoryId: CategoryIds.food, displayName: 'نانوایی'),
    _MerchantEntry(keyword: 'شیرینی', categoryId: CategoryIds.food, displayName: 'شیرینی‌فروشی'),
    _MerchantEntry(keyword: 'قنادی', categoryId: CategoryIds.food, displayName: 'قنادی'),
    _MerchantEntry(keyword: 'پروتئین', categoryId: CategoryIds.food, displayName: 'پروتئینی'),

    // --- خرید ---
    _MerchantEntry(keyword: 'دیجی کالا', categoryId: CategoryIds.shopping, displayName: 'دیجی‌کالا'),
    _MerchantEntry(keyword: 'دیجیکالا', categoryId: CategoryIds.shopping, displayName: 'دیجی‌کالا'),
    _MerchantEntry(keyword: 'digikala', categoryId: CategoryIds.shopping, displayName: 'دیجی‌کالا'),
    _MerchantEntry(keyword: 'دیجی استایل', categoryId: CategoryIds.shopping, displayName: 'دیجی‌استایل'),
    _MerchantEntry(keyword: 'باسلام', categoryId: CategoryIds.shopping, displayName: 'باسلام'),
    _MerchantEntry(keyword: 'basalam', categoryId: CategoryIds.shopping, displayName: 'باسلام'),
    _MerchantEntry(keyword: 'ترب', categoryId: CategoryIds.shopping, displayName: 'ترب'),
    _MerchantEntry(keyword: 'torob', categoryId: CategoryIds.shopping, displayName: 'ترب'),
    _MerchantEntry(keyword: 'تکنولایف', categoryId: CategoryIds.shopping, displayName: 'تکنولایف'),
    _MerchantEntry(keyword: 'technolife', categoryId: CategoryIds.shopping, displayName: 'تکنولایف'),
    _MerchantEntry(keyword: 'خانومی', categoryId: CategoryIds.shopping, displayName: 'خانومی'),
    _MerchantEntry(keyword: 'khanoumi', categoryId: CategoryIds.shopping, displayName: 'خانومی'),
    _MerchantEntry(keyword: 'بانی مد', categoryId: CategoryIds.shopping, displayName: 'بانی‌مد'),
    _MerchantEntry(keyword: 'banimode', categoryId: CategoryIds.shopping, displayName: 'بانی‌مد'),
    _MerchantEntry(keyword: 'تگموند', categoryId: CategoryIds.shopping, displayName: 'تگموند'),
    _MerchantEntry(keyword: 'دیوار', categoryId: CategoryIds.shopping, displayName: 'دیوار'),
    _MerchantEntry(keyword: 'divar', categoryId: CategoryIds.shopping, displayName: 'دیوار'),
    _MerchantEntry(keyword: 'شیپور', categoryId: CategoryIds.shopping, displayName: 'شیپور'),
    _MerchantEntry(keyword: 'طاقچه', categoryId: CategoryIds.shopping, displayName: 'طاقچه'),
    _MerchantEntry(keyword: 'فیدیبو', categoryId: CategoryIds.shopping, displayName: 'فیدیبو'),
    _MerchantEntry(keyword: 'پوشاک', categoryId: CategoryIds.shopping, displayName: 'پوشاک'),

    // --- قبض و خدمات ---
    _MerchantEntry(keyword: 'قبضینو', categoryId: CategoryIds.bills, displayName: 'قبضینو'),
    _MerchantEntry(keyword: 'ghabzino', categoryId: CategoryIds.bills, displayName: 'قبضینو'),
    _MerchantEntry(keyword: 'قبض', categoryId: CategoryIds.bills, displayName: 'پرداخت قبض'),
    _MerchantEntry(keyword: 'توانیر', categoryId: CategoryIds.bills, displayName: 'قبض برق'),
    _MerchantEntry(keyword: 'آبفا', categoryId: CategoryIds.bills, displayName: 'قبض آب'),
    _MerchantEntry(keyword: 'شرکت گاز', categoryId: CategoryIds.bills, displayName: 'قبض گاز'),
    _MerchantEntry(keyword: 'مخابرات', categoryId: CategoryIds.bills, displayName: 'قبض تلفن'),
    _MerchantEntry(keyword: 'شهرداری', categoryId: CategoryIds.bills, displayName: 'شهرداری'),
    _MerchantEntry(keyword: 'مالیات', categoryId: CategoryIds.bills, displayName: 'مالیات'),
    _MerchantEntry(keyword: 'خلافی', categoryId: CategoryIds.bills, displayName: 'خلافی خودرو'),
    _MerchantEntry(keyword: 'جریمه', categoryId: CategoryIds.bills, displayName: 'جریمه'),
    _MerchantEntry(keyword: 'تیپاکس', categoryId: CategoryIds.bills, displayName: 'تیپاکس'),
    _MerchantEntry(keyword: 'tipax', categoryId: CategoryIds.bills, displayName: 'تیپاکس'),
    _MerchantEntry(keyword: 'چاپار', categoryId: CategoryIds.bills, displayName: 'چاپار'),
    _MerchantEntry(keyword: 'پست', categoryId: CategoryIds.bills, displayName: 'خدمات پستی'),
    _MerchantEntry(keyword: 'تامین اجتماعی', categoryId: CategoryIds.bills, displayName: 'تامین اجتماعی'),
    _MerchantEntry(keyword: 'ثبت احوال', categoryId: CategoryIds.bills, displayName: 'ثبت احوال'),
    _MerchantEntry(keyword: 'عدل ایران', categoryId: CategoryIds.bills, displayName: 'خدمات قضایی'),
    _MerchantEntry(keyword: 'بیمه', categoryId: CategoryIds.bills, displayName: 'بیمه'),

    // --- درمان و سلامت ---
    _MerchantEntry(keyword: 'داروخانه', categoryId: CategoryIds.health, displayName: 'داروخانه'),
    _MerchantEntry(keyword: 'بیمارستان', categoryId: CategoryIds.health, displayName: 'بیمارستان'),
    _MerchantEntry(keyword: 'درمانگاه', categoryId: CategoryIds.health, displayName: 'درمانگاه'),
    _MerchantEntry(keyword: 'کلینیک', categoryId: CategoryIds.health, displayName: 'کلینیک'),
    _MerchantEntry(keyword: 'دندانپزشکی', categoryId: CategoryIds.health, displayName: 'دندانپزشکی'),
    _MerchantEntry(keyword: 'آزمایشگاه', categoryId: CategoryIds.health, displayName: 'آزمایشگاه'),
    _MerchantEntry(keyword: 'پذیرش24', categoryId: CategoryIds.health, displayName: 'پذیرش۲۴'),
    _MerchantEntry(keyword: 'دکترتو', categoryId: CategoryIds.health, displayName: 'دکترتو'),
    _MerchantEntry(keyword: 'دکتردکتر', categoryId: CategoryIds.health, displayName: 'دکتردکتر'),
    _MerchantEntry(keyword: 'پزشک', categoryId: CategoryIds.health, displayName: 'پزشک'),
    _MerchantEntry(keyword: 'باشگاه', categoryId: CategoryIds.health, displayName: 'باشگاه ورزشی'),
    _MerchantEntry(keyword: 'استخر', categoryId: CategoryIds.health, displayName: 'استخر'),

    // --- سرگرمی و اشتراک ---
    _MerchantEntry(keyword: 'فیلیمو', categoryId: CategoryIds.entertainment, displayName: 'فیلیمو'),
    _MerchantEntry(keyword: 'filimo', categoryId: CategoryIds.entertainment, displayName: 'فیلیمو'),
    _MerchantEntry(keyword: 'نماوا', categoryId: CategoryIds.entertainment, displayName: 'نماوا'),
    _MerchantEntry(keyword: 'namava', categoryId: CategoryIds.entertainment, displayName: 'نماوا'),
    _MerchantEntry(keyword: 'فیلم نت', categoryId: CategoryIds.entertainment, displayName: 'فیلم‌نت'),
    _MerchantEntry(keyword: 'filmnet', categoryId: CategoryIds.entertainment, displayName: 'فیلم‌نت'),
    _MerchantEntry(keyword: 'سینماتیکت', categoryId: CategoryIds.entertainment, displayName: 'سینماتیکت'),
    _MerchantEntry(keyword: 'cinematicket', categoryId: CategoryIds.entertainment, displayName: 'سینماتیکت'),
    _MerchantEntry(keyword: 'تیوال', categoryId: CategoryIds.entertainment, displayName: 'تیوال'),
    _MerchantEntry(keyword: 'tiwall', categoryId: CategoryIds.entertainment, displayName: 'تیوال'),
    _MerchantEntry(keyword: 'کافه بازار', categoryId: CategoryIds.entertainment, displayName: 'کافه‌بازار'),
    _MerchantEntry(keyword: 'cafebazaar', categoryId: CategoryIds.entertainment, displayName: 'کافه‌بازار'),
    _MerchantEntry(keyword: 'مایکت', categoryId: CategoryIds.entertainment, displayName: 'مایکت'),
    _MerchantEntry(keyword: 'myket', categoryId: CategoryIds.entertainment, displayName: 'مایکت'),
    _MerchantEntry(keyword: 'سینما', categoryId: CategoryIds.entertainment, displayName: 'سینما'),
    _MerchantEntry(keyword: 'اسپاتیفای', categoryId: CategoryIds.entertainment, displayName: 'اسپاتیفای'),
    _MerchantEntry(keyword: 'استیم', categoryId: CategoryIds.entertainment, displayName: 'استیم'),

    // --- قسط و بانکی ---
    _MerchantEntry(keyword: 'ازکی وام', categoryId: CategoryIds.banking, displayName: 'ازکی‌وام'),
    _MerchantEntry(keyword: 'azkivam', categoryId: CategoryIds.banking, displayName: 'ازکی‌وام'),
    _MerchantEntry(keyword: 'لندو', categoryId: CategoryIds.banking, displayName: 'لندو'),
    _MerchantEntry(keyword: 'دیجی پی', categoryId: CategoryIds.banking, displayName: 'دیجی‌پی'),
    _MerchantEntry(keyword: 'digipay', categoryId: CategoryIds.banking, displayName: 'دیجی‌پی'),
    _MerchantEntry(keyword: 'تارا', categoryId: CategoryIds.banking, displayName: 'تارا'),
    _MerchantEntry(keyword: 'کارمزد', categoryId: CategoryIds.banking, displayName: 'کارمزد بانکی'),
    _MerchantEntry(keyword: 'قسط', categoryId: CategoryIds.banking, displayName: 'پرداخت قسط'),
    _MerchantEntry(keyword: 'تسهیلات', categoryId: CategoryIds.banking, displayName: 'تسهیلات'),
    _MerchantEntry(keyword: 'آبونمان', categoryId: CategoryIds.banking, displayName: 'آبونمان بانکی'),
    _MerchantEntry(keyword: 'صدور کارت', categoryId: CategoryIds.banking, displayName: 'صدور کارت'),

    // --- انتقال / خودپرداز ---
    _MerchantEntry(keyword: 'کارت به کارت', categoryId: CategoryIds.transfer, displayName: 'کارت‌به‌کارت'),
    _MerchantEntry(keyword: 'خودپرداز', categoryId: CategoryIds.transfer, displayName: 'برداشت خودپرداز'),
    _MerchantEntry(keyword: 'پایا', categoryId: CategoryIds.transfer, displayName: 'انتقال پایا'),
    _MerchantEntry(keyword: 'ساتنا', categoryId: CategoryIds.transfer, displayName: 'انتقال ساتنا'),
    _MerchantEntry(keyword: 'انتقال', categoryId: CategoryIds.transfer, displayName: 'انتقال وجه'),
  ];

  static final List<_MerchantEntry> _sortedCatalog = () {
    final list = _rawCatalog
        .map(
          (e) => _MerchantEntry(
            keyword: normalizePattern(e.keyword),
            categoryId: e.categoryId,
            displayName: e.displayName,
          ),
        )
        .toList();
    list.sort((a, b) => b.keyword.length.compareTo(a.keyword.length));
    return list;
  }();

  static final RegExp _multiSpace = RegExp(r'\s+');

  /// Normalizes a merchant name or rule pattern for consistent matching.
  static String normalizePattern(String input) =>
      SmsNormalizer.normalize(input).toLowerCase().replaceAll(_multiSpace, ' ').trim();

  /// Returns only the transactions whose `categoryId`, `title`, `merchantName`,
  /// or `needsReview` changed. Never modifies transactions with `userEdited == true`.
  List<BankTransaction> categorizeAll({
    required List<BankTransaction> transactions,
    required List<BankSmsMessage> bankMessages,
    required List<CategoryRule> userRules,
  }) {
    if (transactions.isEmpty) return const [];

    // Prepare sorted user rules (longest pattern first).
    final sortedRules = userRules
        .map(
          (r) => CategoryRule(
            pattern: normalizePattern(r.pattern),
            categoryId: r.categoryId,
            preferredTitle: r.preferredTitle,
          ),
        )
        .where((r) => r.pattern.length >= 2)
        .toList()
      ..sort((a, b) => b.pattern.length.compareTo(a.pattern.length));

    // Index OTP messages sorted ascending by receivedAt for O((N+K) log K) lookup.
    final indexedOtps = bankMessages
        .where((m) => m.kind == BankSmsKind.otp)
        .map(_indexOtp)
        .toList()
      ..sort((a, b) => a.message.receivedAt.compareTo(b.message.receivedAt));

    final sortedTxs = List<BankTransaction>.of(transactions)
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    final leadMs = maxOtpLeadTime.inMilliseconds;
    final lagMs = maxOtpLagTime.inMilliseconds;
    final usedOtpIds = <String>{};
    final updated = <BankTransaction>[];
    var otpLeft = 0;

    for (final tx in sortedTxs) {
      if (tx.userEdited) continue;

      final txMs = tx.occurredAt.millisecondsSinceEpoch;
      while (otpLeft < indexedOtps.length &&
          indexedOtps[otpLeft].message.receivedAt.millisecondsSinceEpoch <
              txMs - leadMs) {
        otpLeft++;
      }

      // 1. Try correlating an OTP SMS for expense transactions.
      _IndexedOtp? matchedOtp;
      if (tx.type == TransactionType.expense && indexedOtps.isNotEmpty) {
        matchedOtp = _findBestOtpMatch(
          tx: tx,
          txMs: txMs,
          otps: indexedOtps,
          startIndex: otpLeft,
          lagMs: lagMs,
          usedOtpIds: usedOtpIds,
        );
        if (matchedOtp != null) {
          usedOtpIds.add(matchedOtp.message.id);
        }
      }

      final categorized = _categorizeSingle(
        tx: tx,
        matchedOtp: matchedOtp,
        sortedRules: sortedRules,
      );

      if (categorized != tx) {
        updated.add(categorized);
      }
    }

    return updated;
  }

  /// Applies a newly learned [rule] to all matching unedited transactions.
  List<BankTransaction> applyRuleToExisting({
    required List<BankTransaction> transactions,
    required CategoryRule rule,
    String? excludeTransactionId,
  }) {
    final normPattern = normalizePattern(rule.pattern);
    if (normPattern.length < 2) return const [];

    final updated = <BankTransaction>[];
    for (final tx in transactions) {
      if (tx.id == excludeTransactionId || tx.userEdited) continue;

      final matchesMerchant =
          tx.merchantName != null &&
          normalizePattern(tx.merchantName!).contains(normPattern);
      final matchesTitle =
          tx.title != null && normalizePattern(tx.title!).contains(normPattern);
      final matchesBody = normalizePattern(tx.rawBody).contains(normPattern);

      if (matchesMerchant || matchesTitle || matchesBody) {
        final next = tx.copyWith(
          categoryId: rule.categoryId,
          title: rule.preferredTitle ?? tx.title,
          needsReview: false,
        );
        if (next != tx) updated.add(next);
      }
    }
    return updated;
  }

  BankTransaction _categorizeSingle({
    required BankTransaction tx,
    required _IndexedOtp? matchedOtp,
    required List<CategoryRule> sortedRules,
  }) {
    final normalizedBody = normalizePattern(tx.rawBody);
    final normalizedTitle = tx.title == null ? '' : normalizePattern(tx.title!);

    // Determine candidate merchant name (existing, OTP acceptor, or catalog hit).
    String? merchantName = tx.merchantName;
    if (merchantName == null && matchedOtp != null) {
      final otpCatalogHit = _matchCatalog(matchedOtp.normalizedBody);
      merchantName = otpCatalogHit?.displayName ?? matchedOtp.extractedAcceptor;
    }

    // Layer 1: User-learned rules (highest priority).
    for (final rule in sortedRules) {
      final hit =
          (merchantName != null &&
              normalizePattern(merchantName).contains(rule.pattern)) ||
          (matchedOtp != null &&
              matchedOtp.normalizedBody.contains(rule.pattern)) ||
          normalizedTitle.contains(rule.pattern) ||
          normalizedBody.contains(rule.pattern);
      if (hit) {
        return tx.copyWith(
          categoryId: rule.categoryId,
          merchantName: merchantName,
          title: rule.preferredTitle ??
              _upgradeTitle(tx.title, merchantName),
          needsReview: false,
        );
      }
    }

    // Internal / linked transfers keep transfer category.
    if (tx.type == TransactionType.transfer) {
      if (tx.categoryId == CategoryIds.transfer) return tx;
      return tx.copyWith(categoryId: CategoryIds.transfer, needsReview: false);
    }

    // Income keyword detection (e.g. حقوق / سود).
    if (tx.type == TransactionType.income) {
      if (normalizedBody.contains('حقوق') ||
          normalizedBody.contains('دستمزد') ||
          normalizedBody.contains('مزایا')) {
        return tx.copyWith(
          categoryId: CategoryIds.salary,
          title: _upgradeTitle(tx.title, 'واریز حقوق'),
          needsReview: false,
        );
      }
      return tx;
    }

    // Layer 2: Match catalog on correlated OTP SMS first (most specific!).
    if (matchedOtp != null) {
      final otpHit = _matchCatalog(matchedOtp.normalizedBody);
      if (otpHit != null) {
        return tx.copyWith(
          categoryId: otpHit.categoryId,
          merchantName: otpHit.displayName,
          title: _upgradeTitle(tx.title, otpHit.displayName),
          needsReview: false,
        );
      }
      // OTP matched and had an acceptor name not in catalog: still save the
      // merchant name & title so the user sees it and can teach a rule in 1 tap!
      if (matchedOtp.extractedAcceptor != null) {
        return tx.copyWith(
          merchantName: matchedOtp.extractedAcceptor,
          title: _upgradeTitle(tx.title, matchedOtp.extractedAcceptor),
        );
      }
    }

    // Layer 3: Match catalog on existing merchantName / transaction body / title.
    final bodyHit =
        (merchantName == null ? null : _matchCatalog(normalizePattern(merchantName))) ??
        _matchCatalog(normalizedBody) ??
        (normalizedTitle.isEmpty ? null : _matchCatalog(normalizedTitle));

    if (bodyHit != null) {
      return tx.copyWith(
        categoryId: bodyHit.categoryId,
        merchantName: merchantName ?? bodyHit.displayName,
        title: _upgradeTitle(tx.title, bodyHit.displayName),
        needsReview: false,
      );
    }

    return tx;
  }

  _IndexedOtp? _findBestOtpMatch({
    required BankTransaction tx,
    required int txMs,
    required List<_IndexedOtp> otps,
    required int startIndex,
    required int lagMs,
    required Set<String> usedOtpIds,
  }) {
    _IndexedOtp? best;
    var bestScore = 1 << 30;

    for (var i = startIndex; i < otps.length; i++) {
      final otp = otps[i];
      final otpMs = otp.message.receivedAt.millisecondsSinceEpoch;
      if (otpMs > txMs + lagMs) break;
      if (usedOtpIds.contains(otp.message.id)) continue;

      // Must be from the same bank (unless either bank is unknown).
      if (tx.bankKey != IranianBankRegistry.unknownKey &&
          otp.message.bankKey != IranianBankRegistry.unknownKey &&
          tx.bankKey != otp.message.bankKey) {
        continue;
      }

      if (!_otpAmountMatches(otp, tx.amountRial)) continue;

      // Prefer OTPs that arrived just BEFORE the debit (with small tie-breaker).
      final delta = (txMs - otpMs).abs();
      final penalty = otpMs > txMs ? 60000 : 0;
      final score = delta + penalty;
      if (score < bestScore) {
        bestScore = score;
        best = otp;
      }
    }

    return best;
  }

  bool _otpAmountMatches(_IndexedOtp otp, int txAmountRial) {
    final otpRial = otp.amountRial;
    if (otpRial == null) return false;
    if (otpRial == txAmountRial) return true;

    // Some banks send OTPs without writing «ریال» or «تومان» explicitly.
    if (!otp.hasExplicitUnit && otp.rawAmount != null) {
      if (otp.rawAmount! * 10 == txAmountRial) return true;
      if (otp.rawAmount == txAmountRial * 10) return true;
    }

    // Allow card-to-card fee difference if OTP is clearly a transfer OTP.
    if (otp.normalizedBody.contains('انتقال') ||
        otp.normalizedBody.contains('کارت به کارت')) {
      final diff = txAmountRial - otpRial;
      if (diff >= 0 && diff <= 150000) return true;
    }
    return false;
  }

  _IndexedOtp _indexOtp(BankSmsMessage message) {
    final norm = normalizePattern(message.body);
    final bankInfo = IranianBankRegistry.byKey(message.bankKey);

    int? rawAmount;
    int? amountRial;
    var hasExplicitUnit = false;

    final m = _otpAmountRegex.firstMatch(norm);
    if (m != null) {
      final digitsStr = (m.group(1) ?? m.group(3))?.replaceAll(',', '');
      final unitStr = m.group(2) ?? m.group(4);
      rawAmount = digitsStr == null ? null : int.tryParse(digitsStr);
      if (rawAmount != null && rawAmount > 0) {
        if (unitStr != null) {
          hasExplicitUnit = true;
          amountRial = unitStr.contains('توم') ? rawAmount * 10 : rawAmount;
        } else if (norm.contains('تومان') || norm.contains('تومن')) {
          hasExplicitUnit = true;
          amountRial = rawAmount * 10;
        } else if (norm.contains('ریال')) {
          hasExplicitUnit = true;
          amountRial = rawAmount;
        } else {
          amountRial = bankInfo.defaultCurrency == CurrencyUnit.toman
              ? rawAmount * 10
              : rawAmount;
        }
      }
    }

    final acceptor = _extractAcceptor(SmsNormalizer.normalize(message.body));

    return _IndexedOtp(
      message: message,
      normalizedBody: norm,
      rawAmount: rawAmount,
      amountRial: amountRial,
      hasExplicitUnit: hasExplicitUnit,
      extractedAcceptor: acceptor,
    );
  }

  static String? _extractAcceptor(String normalizedText) {
    final m = _acceptorLabelRegex.firstMatch(normalizedText);
    if (m == null) return null;
    var value = m.group(1)!.replaceAll(_acceptorTrailingNoise, '').trim();
    value = value.replaceAll(RegExp(r'^[:：\-–\s]+|[:：\-–\s]+$'), '').trim();
    if (value.length < 2 || value.length > 48) return null;
    if (RegExp(r'^\d+$').hasMatch(value)) return null;
    if (_genericAcceptorWords.hasMatch(value.toLowerCase())) return null;
    return value;
  }

  static _MerchantEntry? _matchCatalog(String normalizedText) {
    if (normalizedText.isEmpty) return null;
    for (final entry in _sortedCatalog) {
      if (normalizedText.contains(entry.keyword)) {
        return entry;
      }
    }
    return null;
  }

  static String? _upgradeTitle(String? currentTitle, String? betterTitle) {
    if (betterTitle == null || betterTitle.isEmpty) return currentTitle;
    if (currentTitle == null ||
        currentTitle.isEmpty ||
        currentTitle == 'برداشت از حساب' ||
        currentTitle == 'واریز به حساب' ||
        currentTitle == 'خرید فروشگاهی') {
      return betterTitle;
    }
    return currentTitle;
  }
}
