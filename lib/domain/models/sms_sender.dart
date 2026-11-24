import 'package:equatable/equatable.dart';
import 'package:siaheh/domain/models/iranian_bank_registry.dart';

/// A bank SMS sender (numeric shortcode or alphanumeric sender ID) tracked by
/// the application.
class SmsSender extends Equatable {
  const SmsSender({
    required this.number,
    required this.bankKey,
    this.enabled = true,
    this.autoDetected = false,
  });

  /// Canonical sender address (e.g. `+9830007100` or `BluBank`).
  final String number;

  /// Key in [IranianBankRegistry] (matches `assets/icons/banks/<bankKey>.svg`).
  final String bankKey;

  /// Whether messages from this sender should be imported.
  final bool enabled;

  /// Whether this sender was auto-discovered by the detector vs manually added.
  final bool autoDetected;

  SmsSender copyWith({
    String? bankKey,
    bool? enabled,
    bool? autoDetected,
  }) => SmsSender(
    number: number,
    bankKey: bankKey ?? this.bankKey,
    enabled: enabled ?? this.enabled,
    autoDetected: autoDetected ?? this.autoDetected,
  );

  Map<String, dynamic> toMap() => {
    'number': number,
    'bankKey': bankKey,
    'enabled': enabled,
    'autoDetected': autoDetected,
  };

  factory SmsSender.fromMap(Map<dynamic, dynamic> m) => SmsSender(
    number: m['number'] as String,
    bankKey: m['bankKey'] as String,
    enabled: m['enabled'] as bool? ?? true,
    autoDetected: m['autoDetected'] as bool? ?? false,
  );

  static final RegExp _bidiMarks = RegExp(
    r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]',
  );
  static final RegExp _letterRegex = RegExp(r'[a-zA-Z\u0600-\u06FF]');
  static final RegExp _alphaSeparator = RegExp(r'[\s\-_]+');
  static final RegExp _nonDigit = RegExp(r'\D');

  /// Whether an SMS `address` (e.g. `+983000123`, `3000123`, or `BluBank`)
  /// belongs to this sender.
  bool matchesAddress(String address) {
    final trimmedA = address.replaceAll(_bidiMarks, '').trim();
    final trimmedB = number.replaceAll(_bidiMarks, '').trim();
    if (trimmedA.isEmpty || trimmedB.isEmpty) return false;

    final hasLettersA = _letterRegex.hasMatch(trimmedA);
    final hasLettersB = _letterRegex.hasMatch(trimmedB);

    // Alphanumeric sender matching (e.g. `BluBank` vs `blubank`).
    if (hasLettersA || hasLettersB) {
      if (hasLettersA != hasLettersB) return false;
      final normA = trimmedA.toLowerCase().replaceAll(_alphaSeparator, '');
      final normB = trimmedB.toLowerCase().replaceAll(_alphaSeparator, '');
      return normA == normB;
    }

    // Numeric shortcode matching.
    final a = IranianBankRegistry.stripIranPrefix(_digits(trimmedA));
    final b = IranianBankRegistry.stripIranPrefix(_digits(trimmedB));
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;

    final shorter = a.length < b.length ? a : b;
    final longer = a.length < b.length ? b : a;
    return shorter.length >= 5 && longer.endsWith(shorter);
  }

  /// Canonical storage key for deduplicating senders in Hive.
  static String canonicalAddress(String raw) {
    final trimmed = raw.replaceAll(_bidiMarks, '').trim();
    if (_letterRegex.hasMatch(trimmed)) {
      return trimmed;
    }
    final digits = IranianBankRegistry.stripIranPrefix(_digits(trimmed));
    return digits.isEmpty ? trimmed : digits;
  }

  static String _digits(String s) => s.replaceAll(_nonDigit, '');

  @override
  List<Object?> get props => [number, bankKey, enabled, autoDetected];
}
