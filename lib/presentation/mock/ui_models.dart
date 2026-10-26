import 'package:flutter/material.dart';

/// UI-only models. They exist just to build the screens and will be replaced
/// by the real domain entities when the logic phase starts.
enum UiTxType { income, expense, transfer }

class UiBank {
  const UiBank({required this.key, required this.name});

  /// Matches the svg file name in `assets/icons/banks/`.
  final String key;
  final String name;
}

class UiAccount {
  const UiAccount({
    required this.bank,
    required this.last4,
    required this.balanceRial,
  });

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
    required this.title,
    required this.amountRial,
    required this.type,
    required this.category,
    required this.account,
    required this.dateLabel,
    required this.timeLabel,
    this.needsReview = false,
  });

  final String title;
  final int amountRial;
  final UiTxType type;
  final UiCategory category;
  final UiAccount account;
  final String dateLabel;
  final String timeLabel;
  final bool needsReview;
}

class UiSender {
  const UiSender({
    required this.number,
    required this.bank,
    required this.enabled,
    required this.messageCount,
  });

  final String number;
  final UiBank bank;
  final bool enabled;
  final int messageCount;
}
