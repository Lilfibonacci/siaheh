import 'package:equatable/equatable.dart';

/// Category of a detected bank SMS message.
enum BankSmsKind {
  /// Parsed financial transaction (income, expense, or transfer).
  transaction,

  /// Dynamic password / one-time password / verification code.
  otp,

  /// General bank notification (balance inquiry, login alert, installment reminder, etc.).
  info,

  /// Looks like a financial transaction from a bank, but could not be parsed cleanly.
  unparsed,
}

/// Every SMS detected as originating from a bank, regardless of whether it
/// produced a financial transaction.
class BankSmsMessage extends Equatable {
  const BankSmsMessage({
    required this.id,
    required this.senderAddress,
    required this.bankKey,
    required this.body,
    required this.receivedAt,
    required this.kind,
    this.transactionId,
  });

  /// Stable deterministic ID derived from the SMS.
  final String id;

  /// Raw sender address as reported by Android (e.g. `+9830007100` or `BluBank`).
  final String senderAddress;

  /// Resolved bank key in [IranianBankRegistry] (or `'unknown'`).
  final String bankKey;

  /// Raw SMS text.
  final String body;

  /// Timestamp when the SMS was received on the device.
  final DateTime receivedAt;

  /// Classification of this bank SMS.
  final BankSmsKind kind;

  /// Associated [BankTransaction.id] when [kind] is [BankSmsKind.transaction].
  final String? transactionId;

  BankSmsMessage copyWith({
    String? bankKey,
    BankSmsKind? kind,
    String? transactionId,
  }) => BankSmsMessage(
    id: id,
    senderAddress: senderAddress,
    bankKey: bankKey ?? this.bankKey,
    body: body,
    receivedAt: receivedAt,
    kind: kind ?? this.kind,
    transactionId: transactionId ?? this.transactionId,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderAddress': senderAddress,
    'bankKey': bankKey,
    'body': body,
    'receivedAt': receivedAt.millisecondsSinceEpoch,
    'kind': kind.name,
    'transactionId': transactionId,
  };

  factory BankSmsMessage.fromMap(Map<dynamic, dynamic> m) => BankSmsMessage(
    id: m['id'] as String,
    senderAddress: m['senderAddress'] as String,
    bankKey: m['bankKey'] as String? ?? 'unknown',
    body: m['body'] as String,
    receivedAt: DateTime.fromMillisecondsSinceEpoch(m['receivedAt'] as int),
    kind: BankSmsKind.values.byName(m['kind'] as String? ?? 'info'),
    transactionId: m['transactionId'] as String?,
  );

  @override
  List<Object?> get props => [
    id,
    senderAddress,
    bankKey,
    body,
    receivedAt,
    kind,
    transactionId,
  ];
}
