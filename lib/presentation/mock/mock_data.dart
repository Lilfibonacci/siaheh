import 'package:flutter/material.dart';
import 'package:siaheh/presentation/mock/ui_models.dart';

/// Static sample data used only while the UI is designed (no logic yet).
class MockData {
  MockData._();

  static const UiBank melli = UiBank(key: 'melli', name: 'بانک ملی');
  static const UiBank mellat = UiBank(key: 'mellat', name: 'بانک ملت');
  static const UiBank sepah = UiBank(key: 'sepah', name: 'بانک سپه');
  static const UiBank saderat = UiBank(key: 'saderat', name: 'بانک صادرات');
  static const UiBank pasargad = UiBank(key: 'pasargad', name: 'بانک پاسارگاد');

  static const List<UiBank> banks = [melli, mellat, sepah, saderat, pasargad];

  static const List<UiAccount> accounts = [
    UiAccount(bank: melli, last4: '4821', balanceRial: 128500000),
    UiAccount(bank: mellat, last4: '9033', balanceRial: 56200000),
    UiAccount(bank: sepah, last4: '1175', balanceRial: 9800000),
    UiAccount(bank: pasargad, last4: '6640', balanceRial: 34750000),
  ];

  static const UiCategory food = UiCategory(
    name: 'خوراک',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFF59E0B),
  );
  static const UiCategory transport = UiCategory(
    name: 'حمل‌ونقل',
    icon: Icons.directions_car_rounded,
    color: Color(0xFF38BDF8),
  );
  static const UiCategory bills = UiCategory(
    name: 'قبض',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFFA78BFA),
  );
  static const UiCategory shopping = UiCategory(
    name: 'خرید',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFF472B6),
  );
  static const UiCategory salary = UiCategory(
    name: 'حقوق',
    icon: Icons.payments_rounded,
    color: Color(0xFF34D399),
  );
  static const UiCategory transferCat = UiCategory(
    name: 'انتقال',
    icon: Icons.swap_horiz_rounded,
    color: Color(0xFF60A5FA),
  );
  static const UiCategory other = UiCategory(
    name: 'سایر',
    icon: Icons.category_rounded,
    color: Color(0xFF94A3B8),
  );

  static const List<UiCategory> categories = [
    food,
    transport,
    bills,
    shopping,
    salary,
    transferCat,
    other,
  ];

  /// Expense share per category used by the donut chart (rials).
  static const Map<UiCategory, int> expenseByCategory = {
    food: 38500000,
    transport: 12400000,
    bills: 21000000,
    shopping: 29800000,
    other: 6500000,
  };

  static const int monthIncomeRial = 180000000;
  static const int monthExpenseRial = 108200000;

  static const List<UiTransaction> transactions = [
    UiTransaction(
      title: 'خرید از فروشگاه رفاه',
      amountRial: 4850000,
      type: UiTxType.expense,
      category: shopping,
      account: UiAccount(bank: melli, last4: '4821', balanceRial: 0),
      dateLabel: 'امروز',
      timeLabel: '۱۸:۴۲',
    ),
    UiTransaction(
      title: 'واریز حقوق',
      amountRial: 150000000,
      type: UiTxType.income,
      category: salary,
      account: UiAccount(bank: mellat, last4: '9033', balanceRial: 0),
      dateLabel: 'امروز',
      timeLabel: '۰۹:۱۰',
    ),
    UiTransaction(
      title: 'اسنپ',
      amountRial: 1260000,
      type: UiTxType.expense,
      category: transport,
      account: UiAccount(bank: pasargad, last4: '6640', balanceRial: 0),
      dateLabel: 'دیروز',
      timeLabel: '۲۱:۰۵',
    ),
    UiTransaction(
      title: 'انتقال به حساب سپه',
      amountRial: 20000000,
      type: UiTxType.transfer,
      category: transferCat,
      account: UiAccount(bank: melli, last4: '4821', balanceRial: 0),
      dateLabel: 'دیروز',
      timeLabel: '۱۴:۲۰',
    ),
    UiTransaction(
      title: 'پرداخت قبض برق',
      amountRial: 3120000,
      type: UiTxType.expense,
      category: bills,
      account: UiAccount(bank: saderat, last4: '2208', balanceRial: 0),
      dateLabel: 'دیروز',
      timeLabel: '۱۰:۳۳',
    ),
    UiTransaction(
      title: 'تراکنش نامشخص',
      amountRial: 890000,
      type: UiTxType.expense,
      category: other,
      account: UiAccount(bank: sepah, last4: '1175', balanceRial: 0),
      dateLabel: '۳ روز پیش',
      timeLabel: '۱۶:۵۰',
      needsReview: true,
    ),
    UiTransaction(
      title: 'رستوران',
      amountRial: 7400000,
      type: UiTxType.expense,
      category: food,
      account: UiAccount(bank: melli, last4: '4821', balanceRial: 0),
      dateLabel: '۳ روز پیش',
      timeLabel: '۱۳:۱۵',
    ),
  ];

  static const List<UiSender> senders = [
    UiSender(number: '+98 9999 1000', bank: melli, enabled: true, messageCount: 42),
    UiSender(number: '+98 3000 7100', bank: mellat, enabled: true, messageCount: 31),
    UiSender(number: '+98 5000 2090', bank: sepah, enabled: true, messageCount: 12),
    UiSender(number: '+98 3000 2222', bank: pasargad, enabled: false, messageCount: 8),
    UiSender(number: '+98 9000 1234', bank: saderat, enabled: false, messageCount: 5),
  ];
}
