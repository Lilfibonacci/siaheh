import 'package:equatable/equatable.dart';

/// Currency unit used by a bank when an SMS omits explicit «ریال» / «تومان».
enum CurrencyUnit { rial, toman }

/// Static metadata for an Iranian bank / neo-bank.
class BankInfo extends Equatable {
  const BankInfo({
    required this.key,
    required this.name,
    this.aliases = const [],
    this.bodyIdentifiers = const [],
    this.numericSenders = const [],
    this.alphanumericSenders = const [],
    this.defaultCurrency = CurrencyUnit.rial,
    this.hasLogoAsset = true,
  });

  /// Matches the SVG filename in `assets/icons/banks/<key>.svg` when
  /// [hasLogoAsset] is `true`.
  final String key;

  /// Persian display name (e.g. `بانک ملی`).
  final String name;

  /// Persian / English keywords used for user search / autocomplete.
  final List<String> aliases;

  /// Unambiguous bank identifiers safe for scanning raw SMS message bodies.
  final List<String> bodyIdentifiers;

  /// Known numeric shortcodes / sender numbers (stored as digits only).
  final List<String> numericSenders;

  /// Known alphanumeric sender IDs (case-insensitive, e.g. `BluBank`).
  final List<String> alphanumericSenders;

  /// Default currency unit when the SMS does not explicitly mention ریال/تومان.
  final CurrencyUnit defaultCurrency;

  /// Whether `assets/icons/banks/$key.svg` exists in the bundle.
  final bool hasLogoAsset;

  @override
  List<Object?> get props => [
    key,
    name,
    aliases,
    bodyIdentifiers,
    numericSenders,
    alphanumericSenders,
    defaultCurrency,
    hasLogoAsset,
  ];
}
