import 'package:equatable/equatable.dart';

enum TransactionType { income, expense, transfer }

/// A financial transaction extracted from a bank SMS.
class BankTransaction extends Equatable {
  const BankTransaction({
    required this.id,
    required this.bankKey,
    required this.accountNumber,
    required this.senderNumber,
    required this.amountRial,
    required this.type,
    required this.occurredAt,
    required this.rawBody,
    this.smsId,
    this.balanceRial,
    this.categoryId,
    this.title,
    this.merchantName,
    this.needsReview = false,
    this.linkedTransferId,
    this.userEdited = false,
  });

  /// Stable id derived from the SMS (used to avoid importing a message twice).
  final String id;

  /// Bank key in [IranianBankRegistry] (e.g. `melli`, `blubank`, `unknown`).
  final String bankKey;

  /// Account or card identifier (may be `'اصلی'` when bank SMS omits it).
  final String accountNumber;
  final String senderNumber;

  /// Always positive; direction is expressed by [type]. Stored in Rials.
  final int amountRial;
  final TransactionType type;
  final DateTime occurredAt;
  final String rawBody;

  /// Reference to [BankSmsMessage.id].
  final String? smsId;
  final int? balanceRial;
  final String? categoryId;
  final String? title;

  /// Merchant / acceptor name extracted from either a correlated OTP SMS or
  /// the transaction SMS body (e.g. `ایرانسل`, `اسنپ`, `دیجی‌کالا`).
  final String? merchantName;
  final bool needsReview;

  /// When this transaction is paired as an internal transfer between two of
  /// the user's own accounts, holds the counterpart transaction's [id].
  final String? linkedTransferId;

  /// True after the user manually edits this transaction, so auto-transfer
  /// detection and auto-categorization do not override their choice.
  final bool userEdited;

  /// Fallback account label when a bank SMS omits an explicit account/card
  /// number.
  static const String defaultAccountLabel = 'اصلی';

  static final RegExp _nonDigit = RegExp(r'\D');

  /// Globally unique account key across multiple banks.
  String get accountKey => '${bankKey}_$accountNumber';

  /// Safe display suffix (last 4 digits or full label if shorter).
  String get accountDisplaySuffix {
    final digitsOnly = accountNumber.replaceAll(_nonDigit, '');
    if (digitsOnly.length >= 4) {
      return digitsOnly.substring(digitsOnly.length - 4);
    }
    return accountNumber;
  }

  BankTransaction copyWith({
    String? bankKey,
    TransactionType? type,
    int? amountRial,
    String? categoryId,
    String? title,
    String? merchantName,
    bool? needsReview,
    String? linkedTransferId,
    bool clearLinkedTransfer = false,
    bool? userEdited,
  }) => BankTransaction(
    id: id,
    bankKey: bankKey ?? this.bankKey,
    accountNumber: accountNumber,
    senderNumber: senderNumber,
    amountRial: amountRial ?? this.amountRial,
    type: type ?? this.type,
    occurredAt: occurredAt,
    rawBody: rawBody,
    smsId: smsId,
    balanceRial: balanceRial,
    categoryId: categoryId ?? this.categoryId,
    title: title ?? this.title,
    merchantName: merchantName ?? this.merchantName,
    needsReview: needsReview ?? this.needsReview,
    linkedTransferId: clearLinkedTransfer
        ? null
        : (linkedTransferId ?? this.linkedTransferId),
    userEdited: userEdited ?? this.userEdited,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'bankKey': bankKey,
    'accountNumber': accountNumber,
    'senderNumber': senderNumber,
    'amountRial': amountRial,
    'type': type.name,
    'occurredAt': occurredAt.millisecondsSinceEpoch,
    'rawBody': rawBody,
    'smsId': smsId,
    'balanceRial': balanceRial,
    'categoryId': categoryId,
    'title': title,
    'merchantName': merchantName,
    'needsReview': needsReview,
    'linkedTransferId': linkedTransferId,
    'userEdited': userEdited,
  };

  factory BankTransaction.fromMap(Map<dynamic, dynamic> m) => BankTransaction(
    id: m['id'] as String,
    bankKey: m['bankKey'] as String? ?? 'unknown',
    accountNumber: m['accountNumber'] as String,
    senderNumber: m['senderNumber'] as String,
    amountRial: m['amountRial'] as int,
    type: TransactionType.values.byName(m['type'] as String),
    occurredAt: DateTime.fromMillisecondsSinceEpoch(m['occurredAt'] as int),
    rawBody: m['rawBody'] as String,
    smsId: m['smsId'] as String?,
    balanceRial: m['balanceRial'] as int?,
    categoryId: m['categoryId'] as String?,
    title: m['title'] as String?,
    merchantName: m['merchantName'] as String?,
    needsReview: m['needsReview'] as bool? ?? false,
    linkedTransferId: m['linkedTransferId'] as String?,
    userEdited: m['userEdited'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [
    id,
    bankKey,
    accountNumber,
    senderNumber,
    amountRial,
    type,
    occurredAt,
    smsId,
    balanceRial,
    categoryId,
    title,
    merchantName,
    needsReview,
    linkedTransferId,
    userEdited,
  ];
}
