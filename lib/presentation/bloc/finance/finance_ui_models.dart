import 'package:flutter/material.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';
import 'package:siaheh/domain/entities/category_ids.dart';
import 'package:siaheh/domain/entities/custom_category.dart';

export 'package:siaheh/domain/entities/jalali_date_filter.dart';

enum UiTxType { income, expense, transfer }

/// Mode selector on the home expense breakdown chart.
enum ExpensePeriod { thisMonth, lastMonth, custom }

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
    this.isCustom = false,
  });

  final String name;
  final IconData icon;
  final Color color;
  final bool isCustom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UiCategory && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// One aggregated category slice for the interactive expense chart.
class CategoryExpenseSlice {
  const CategoryExpenseSlice({
    required this.category,
    required this.amountRial,
    required this.transactionCount,
    required this.percentage,
  });

  final UiCategory category;
  final int amountRial;
  final int transactionCount;
  final double percentage;
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
    this.merchantName,
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
  final String? merchantName;
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

/// Built-in Iranian personal finance categories + custom category icon/color
/// palettes.
class AppCategories {
  const AppCategories._();

  static const UiCategory internet = UiCategory(
    name: CategoryIds.internet,
    icon: Icons.wifi_rounded,
    color: Color(0xFF06B6D4),
  );
  static const UiCategory transport = UiCategory(
    name: CategoryIds.transport,
    icon: Icons.directions_car_rounded,
    color: Color(0xFF38BDF8),
  );
  static const UiCategory food = UiCategory(
    name: CategoryIds.food,
    icon: Icons.restaurant_rounded,
    color: Color(0xFFF59E0B),
  );
  static const UiCategory shopping = UiCategory(
    name: CategoryIds.shopping,
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFF472B6),
  );
  static const UiCategory bills = UiCategory(
    name: CategoryIds.bills,
    icon: Icons.receipt_long_rounded,
    color: Color(0xFFA78BFA),
  );
  static const UiCategory health = UiCategory(
    name: CategoryIds.health,
    icon: Icons.medical_services_rounded,
    color: Color(0xFFFB7185),
  );
  static const UiCategory entertainment = UiCategory(
    name: CategoryIds.entertainment,
    icon: Icons.movie_rounded,
    color: Color(0xFFC084FC),
  );
  static const UiCategory banking = UiCategory(
    name: CategoryIds.banking,
    icon: Icons.account_balance_rounded,
    color: Color(0xFFF97316),
  );
  static const UiCategory salary = UiCategory(
    name: CategoryIds.salary,
    icon: Icons.payments_rounded,
    color: Color(0xFF34D399),
  );
  static const UiCategory transfer = UiCategory(
    name: CategoryIds.transfer,
    icon: Icons.swap_horiz_rounded,
    color: Color(0xFF60A5FA),
  );
  static const UiCategory other = UiCategory(
    name: CategoryIds.other,
    icon: Icons.category_rounded,
    color: Color(0xFF94A3B8),
  );

  static const List<UiCategory> builtIn = [
    internet,
    transport,
    food,
    shopping,
    bills,
    health,
    entertainment,
    banking,
    salary,
    transfer,
    other,
  ];

  /// Curated icon options for creating custom categories.
  static const List<IconData> customIconChoices = [
    Icons.coffee_rounded,
    Icons.home_rounded,
    Icons.school_rounded,
    Icons.pets_rounded,
    Icons.flight_rounded,
    Icons.card_giftcard_rounded,
    Icons.fitness_center_rounded,
    Icons.checkroom_rounded,
    Icons.build_rounded,
    Icons.child_care_rounded,
    Icons.volunteer_activism_rounded,
    Icons.savings_rounded,
  ];

  /// Curated OLED-friendly high-contrast color choices for custom categories.
  static const List<Color> customColorChoices = [
    Color(0xFF14B8A6),
    Color(0xFF22C55E),
    Color(0xFFEAB308),
    Color(0xFFFB923C),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
  ];

  static IconData iconFromCodePoint(int codePoint) {
    for (final icon in customIconChoices) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.label_rounded;
  }

  static UiCategory fromCustom(CustomCategory c) => UiCategory(
    name: c.name,
    icon: iconFromCodePoint(c.iconCodePoint),
    color: Color(c.colorValue),
    isCustom: true,
  );

  static List<UiCategory> mergeWithCustom(List<CustomCategory> custom) {
    final result = List<UiCategory>.of(builtIn);
    for (final c in custom) {
      if (!result.any((e) => e.name == c.name)) {
        // Insert custom categories right before 'سایر'.
        result.insert(result.length - 1, fromCustom(c));
      }
    }
    return result;
  }

  static UiCategory byName(
    String? name, {
    List<CustomCategory> custom = const [],
  }) {
    if (name == null || name.isEmpty) return other;
    // Backward compatibility with previous 'قبض' category name.
    final resolvedName = name == 'قبض' ? CategoryIds.bills : name;
    for (final c in builtIn) {
      if (c.name == resolvedName) return c;
    }
    for (final c in custom) {
      if (c.name == resolvedName) return fromCustom(c);
    }
    return other;
  }
}
