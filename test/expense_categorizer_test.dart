import 'package:flutter_test/flutter_test.dart';
import 'package:siaheh/features/sms/data/parsers/expense_categorizer.dart';
import 'package:siaheh/features/sms/domain/entities/bank_sms_message.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/features/sms/domain/entities/category_rule.dart';

void main() {
  const categorizer = ExpenseCategorizer();
  final baseTime = DateTime(2026, 11, 20, 17, 42);

  BankTransaction makeTx({
    required String id,
    required String bankKey,
    required int amountRial,
    required DateTime at,
    TransactionType type = TransactionType.expense,
    String rawBody = 'برداشت از حساب',
    String? title,
    String? merchantName,
    bool userEdited = false,
  }) => BankTransaction(
    id: id,
    bankKey: bankKey,
    accountNumber: 'اصلی',
    senderNumber: bankKey,
    amountRial: amountRial,
    type: type,
    occurredAt: at,
    rawBody: rawBody,
    title: title,
    merchantName: merchantName,
    userEdited: userEdited,
  );

  BankSmsMessage makeOtp({
    required String id,
    required String bankKey,
    required String body,
    required DateTime at,
  }) => BankSmsMessage(
    id: id,
    senderAddress: bankKey,
    bankKey: bankKey,
    body: body,
    receivedAt: at,
    kind: BankSmsKind.otp,
  );

  test('correlates BluBank Irancell OTP to internet category and merchant title', () {
    final otp = makeOtp(
      id: 'otp_1',
      bankKey: 'blubank',
      body: 'بلو\nرمز پویا: 482910\nپذیرنده: ایرانسل\nمبلغ: 150,000 تومان',
      at: baseTime.subtract(const Duration(minutes: 1)),
    );
    final tx = makeTx(
      id: 'tx_1',
      bankKey: 'blubank',
      amountRial: 1500000, // 150,000 Toman
      at: baseTime,
      rawBody: 'برداشت از حساب 150,000 تومان',
    );

    final changes = categorizer.categorizeAll(
      transactions: [tx],
      bankMessages: [otp],
      userRules: const [],
    );

    expect(changes.length, 1);
    expect(changes.first.categoryId, CategoryIds.internet);
    expect(changes.first.merchantName, 'ایرانسل');
    expect(changes.first.title, 'ایرانسل');
    expect(changes.first.needsReview, isFalse);
  });

  test('distinguishes compound Snapp brands (Snapp vs SnappFood vs SnappDoctor vs SnappPay)', () {
    final otps = [
      makeOtp(
        id: 'o1',
        bankKey: 'melli',
        body: 'رمز پویا 111222\nپذیرنده: اسنپ\nمبلغ: 850,000 ریال',
        at: baseTime.subtract(const Duration(seconds: 45)),
      ),
      makeOtp(
        id: 'o2',
        bankKey: 'melli',
        body: 'رمز پویا 333444\nپذیرنده: اسنپ فود\nمبلغ: 3,200,000 ریال',
        at: baseTime.add(const Duration(hours: 1)).subtract(const Duration(seconds: 30)),
      ),
      makeOtp(
        id: 'o3',
        bankKey: 'melli',
        body: 'رمز پویا 555666\nپذیرنده: اسنپ دکتر\nمبلغ: 1,800,000 ریال',
        at: baseTime.add(const Duration(hours: 2)).subtract(const Duration(seconds: 20)),
      ),
      makeOtp(
        id: 'o4',
        bankKey: 'melli',
        body: 'رمز پویا 777888\nپذیرنده: اسنپ پی\nمبلغ: 5,000,000 ریال',
        at: baseTime.add(const Duration(hours: 3)).subtract(const Duration(seconds: 20)),
      ),
    ];

    final txs = [
      makeTx(id: 't1', bankKey: 'melli', amountRial: 850000, at: baseTime),
      makeTx(
        id: 't2',
        bankKey: 'melli',
        amountRial: 3200000,
        at: baseTime.add(const Duration(hours: 1)),
      ),
      makeTx(
        id: 't3',
        bankKey: 'melli',
        amountRial: 1800000,
        at: baseTime.add(const Duration(hours: 2)),
      ),
      makeTx(
        id: 't4',
        bankKey: 'melli',
        amountRial: 5000000,
        at: baseTime.add(const Duration(hours: 3)),
      ),
    ];

    final changes = categorizer.categorizeAll(
      transactions: txs,
      bankMessages: otps,
      userRules: const [],
    );

    final byId = {for (final c in changes) c.id: c};
    expect(byId['t1']!.categoryId, CategoryIds.transport);
    expect(byId['t2']!.categoryId, CategoryIds.food);
    expect(byId['t3']!.categoryId, CategoryIds.health);
    expect(byId['t4']!.categoryId, CategoryIds.banking);
  });

  test('matches OTP arriving slightly after zero-second body timestamp (+30s lag)', () {
    final otp = makeOtp(
      id: 'otp_lag',
      bankKey: 'melli',
      body: 'بانک ملی\nرمز پویا 998877\nپذیرنده: دیجی کالا\nمبلغ: 4,500,000 ریال',
      at: baseTime.add(const Duration(seconds: 30)),
    );
    final tx = makeTx(
      id: 'tx_lag',
      bankKey: 'melli',
      amountRial: 4500000,
      at: baseTime,
    );

    final changes = categorizer.categorizeAll(
      transactions: [tx],
      bankMessages: [otp],
      userRules: const [],
    );
    expect(changes.length, 1);
    expect(changes.first.categoryId, CategoryIds.shopping);
    expect(changes.first.merchantName, 'دیجی‌کالا');
  });

  test('does not match OTP from a different bank or outside time window', () {
    final wrongBankOtp = makeOtp(
      id: 'o_wrong_bank',
      bankKey: 'mellat',
      body: 'رمز پویا 111222\nپذیرنده: اسنپ\nمبلغ: 1,000,000 ریال',
      at: baseTime.subtract(const Duration(seconds: 30)),
    );
    final tooOldOtp = makeOtp(
      id: 'o_old',
      bankKey: 'blubank',
      body: 'رمز پویا 111222\nپذیرنده: ایرانسل\nمبلغ: 100,000 تومان',
      at: baseTime.subtract(const Duration(minutes: 25)),
    );
    final tx = makeTx(
      id: 'tx_no_match',
      bankKey: 'blubank',
      amountRial: 1000000,
      at: baseTime,
    );

    final changes = categorizer.categorizeAll(
      transactions: [tx],
      bankMessages: [wrongBankOtp, tooOldOtp],
      userRules: const [],
    );
    expect(changes, isEmpty);
  });

  test('user learned rules override built-in catalog and apply to similar unedited transactions', () {
    const customRule = CategoryRule(
      pattern: 'کافه لمیز',
      categoryId: 'کافه و دورهمی',
      preferredTitle: 'کافه لمیز',
    );
    final unedited = makeTx(
      id: 'u1',
      bankKey: 'blubank',
      amountRial: 2500000,
      at: baseTime,
      merchantName: 'کافه لمیز',
    );
    final edited = makeTx(
      id: 'e1',
      bankKey: 'blubank',
      amountRial: 2500000,
      at: baseTime,
      merchantName: 'کافه لمیز',
      userEdited: true,
    );

    final applied = categorizer.applyRuleToExisting(
      transactions: [unedited, edited],
      rule: customRule,
    );

    expect(applied.length, 1);
    expect(applied.first.id, 'u1');
    expect(applied.first.categoryId, 'کافه و دورهمی');
  });

  test('categorizes direct transaction body keywords without OTP', () {
    final feeTx = makeTx(
      id: 'fee',
      bankKey: 'melli',
      amountRial: 12000,
      at: baseTime,
      rawBody: 'برداشت کارمزد پیامک بانکی 12,000 ریال',
    );
    final salaryTx = makeTx(
      id: 'sal',
      bankKey: 'mellat',
      amountRial: 250000000,
      at: baseTime,
      type: TransactionType.income,
      rawBody: 'واریز حقوق آبان ماه 250,000,000 ریال',
    );

    final changes = categorizer.categorizeAll(
      transactions: [feeTx, salaryTx],
      bankMessages: const [],
      userRules: const [],
    );
    final byId = {for (final c in changes) c.id: c};
    expect(byId['fee']!.categoryId, CategoryIds.banking);
    expect(byId['sal']!.categoryId, CategoryIds.salary);
  });
}
