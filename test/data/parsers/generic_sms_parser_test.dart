import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:siaheh/data/parsers/generic_sms_parser.dart';
import 'package:siaheh/domain/entities/bank_info.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';

void main() {
  final parser = GenericSmsParser(nowJalali: () => Jalali(1405, 8, 6, 12));
  final fallbackDate = DateTime(2026, 10, 28, 15, 30);

  test('parses Melli line-based income sample', () {
    final r = parser.parse(
      '0304546764008\n+4,300,000\n07/6-18:14\nمانده 4,334,844\nاز 1697',
    )!;
    expect(r.accountNumber, '0304546764008');
    expect(r.amountRial, 4300000);
    expect(r.type, TransactionType.income);
    expect(r.balanceRial, 4334844);
    final j = Jalali.fromDateTime(r.occurredAt);
    expect([j.year, j.month, j.day, j.hour, j.minute], [1405, 7, 6, 18, 14]);
  });

  test('parses expense with persian digits', () {
    final r = parser.parse(
      '۰۳۰۴۵۴۶۷۶۴۰۰۸\n-۱۲۰٬۰۰۰\n۰۷/۶-۱۸:۱۴\nمانده ۴٬۲۱۴٬۸۴۴',
    )!;
    expect(r.type, TransactionType.expense);
    expect(r.amountRial, 120000);
    expect(r.balanceRial, 4214844);
  });

  test('parses Mellat keyword-based expense in Rials', () {
    final r = parser.parse(
      'بانک ملت\nحساب: 1234567890\nبرداشت مبلغ 1,500,000 ریال\nمانده: 8,200,000 ریال\n1405/07/06 14:22',
    )!;
    expect(r.type, TransactionType.expense);
    expect(r.accountNumber, '1234567890');
    expect(r.amountRial, 1500000);
    expect(r.balanceRial, 8200000);
  });

  test('parses BluBank Toman message without account number or body date', () {
    final r = parser.parse(
      'بلو\nبرداشت پول\nمبلغ: ۲۵۰٬۰۰۰ تومان\nموجودی: ۱٬۴۵۰٬۰۰۰ تومان',
      fallbackDate: fallbackDate,
      defaultCurrency: CurrencyUnit.toman,
    )!;
    expect(r.type, TransactionType.expense);
    expect(r.accountNumber, GenericSmsParser.defaultAccountLabel);
    expect(r.amountRial, 2500000);
    expect(r.balanceRial, 14500000);
    expect(r.occurredAt, fallbackDate);
  });

  test('parses masked card SMS', () {
    final r = parser.parse(
      'بانک تجارت\nکارت 6273****4912\nخرید به مبلغ 350,000 ریال\nمانده 9,100,000 ریال',
      fallbackDate: fallbackDate,
    )!;
    expect(r.type, TransactionType.expense);
    expect(r.accountNumber, 'کارت 4912');
    expect(r.amountRial, 350000);
    expect(r.balanceRial, 9100000);
    expect(r.suggestedTitle, 'خرید فروشگاهی');
  });

  test('rejects OTP and non-transaction messages', () {
    expect(parser.parse('کد تایید شما 12345', fallbackDate: fallbackDate), isNull);
    expect(
      parser.parse(
        'بانک ملی\nرمز پویا: 482910\nمبلغ: 500,000 ریال\nاین رمز محرمانه است',
        fallbackDate: fallbackDate,
      ),
      isNull,
    );
  });
}
