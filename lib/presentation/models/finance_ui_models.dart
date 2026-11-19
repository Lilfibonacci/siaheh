import 'package:flutter/material.dart';
import 'package:siaheh/features/sms/domain/entities/bank_sms_message.dart';

enum UiTxType { income, expense, transfer }

class UiBank {
  const UiBank({required this.key, required this.name});

  final String key;
  final String name;
}

class UiAccount {
  const UiAccount({
    required this.accountKey,
    required this.bank,
    required this.last4,
    required this.balanceRial,
  });

  final String accountKey;
  final UiBank bank;
  final String last4;
  final int balanceRial;
}

class UiCategory {
  const UiCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;
}

class UiTransaction {
  const UiTransaction({
    this.id = '',
    required this.title,
    required this.amountRial,
    required this.type,
    required this.category,
    required this.account,
    required this.dateLabel,
    required this.timeLabel,
    this.rawBody = '',
    this.needsReview = false,
    this.isAutoTransfer = false,
  });

  final String id;
  final String title;
  final int amountRial;
  final UiTxType type;
  final UiCategory category;
  final UiAccount account;
  final String dateLabel;
  final String timeLabel;
  final String rawBody;
  final bool needsReview;
  final bool isAutoTransfer;
}

class UiBankMessage {
  const UiBankMessage({
    required this.id,
    required this.bank,
    required this.senderAddress,
    required this.body,
    required this.kind,
    required this.dateLabel,
    required this.timeLabel,
    this.transactionId,
  });

  final String id;
  final UiBank bank;
  final String senderAddress;
  final String body;
  final BankSmsKind kind;
  final String dateLabel;
  final String timeLabel;
  final String? transactionId;
}

class UiSender {
  const UiSender({
    required this.number,
    required this.bank,
    required this.enabled,
    required this.autoDetected,
    required this.messageCount,
  });

  final String number;
  final UiBank bank;
  final bool enabled;
  final bool autoDetected;
  final int messageCount;
}

/// Built-in transaction categories.
class AppCategories {
  const AppCategories._();

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
  static const UiCategory transfer = UiCategory(
    name: 'انتقال',
    icon: Icons.swap_horiz_rounded,
    color: Color(0xFF60A5FA),
  );
  static const UiCategory other = UiCategory(
    name: 'سایر',
    icon: Icons.category_rounded,
    color: Color(0xFF94A3B8),
  );

  static const List<UiCategory> all = [
    food,
    transport,
    bills,
    shopping,
    salary,
    transfer,
    other,
  ];

  static UiCategory byName(String? name) => all.firstWhere(
    (c) => c.name == name,
    orElse: () => other,
  );
}
