/// Local persistence DTO for a financial transaction stored in Hive.
class BankTransactionDto {
  const BankTransactionDto({
    required this.id,
    required this.bankKey,
    required this.accountNumber,
    required this.senderNumber,
    required this.amountRial,
    required this.type,
    required this.occurredAtMs,
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

  final String id;
  final String bankKey;
  final String accountNumber;
  final String senderNumber;
  final int amountRial;
  final String type;
  final int occurredAtMs;
  final String rawBody;
  final String? smsId;
  final int? balanceRial;
  final String? categoryId;
  final String? title;
  final String? merchantName;
  final bool needsReview;
  final String? linkedTransferId;
  final bool userEdited;

  Map<String, dynamic> toMap() => {
    'id': id,
    'bankKey': bankKey,
    'accountNumber': accountNumber,
    'senderNumber': senderNumber,
    'amountRial': amountRial,
    'type': type,
    'occurredAt': occurredAtMs,
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

  factory BankTransactionDto.fromMap(Map<dynamic, dynamic> m) =>
      BankTransactionDto(
        id: m['id'] as String,
        bankKey: m['bankKey'] as String? ?? 'unknown',
        accountNumber: m['accountNumber'] as String,
        senderNumber: m['senderNumber'] as String,
        amountRial: m['amountRial'] as int,
        type: m['type'] as String,
        occurredAtMs: m['occurredAt'] as int,
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
}
