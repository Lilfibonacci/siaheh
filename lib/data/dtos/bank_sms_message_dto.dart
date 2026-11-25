/// Local persistence DTO for a detected bank SMS message stored in Hive.
class BankSmsMessageDto {
  const BankSmsMessageDto({
    required this.id,
    required this.senderAddress,
    required this.bankKey,
    required this.body,
    required this.receivedAtMs,
    required this.kind,
    this.transactionId,
  });

  final String id;
  final String senderAddress;
  final String bankKey;
  final String body;
  final int receivedAtMs;
  final String kind;
  final String? transactionId;

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderAddress': senderAddress,
    'bankKey': bankKey,
    'body': body,
    'receivedAt': receivedAtMs,
    'kind': kind,
    'transactionId': transactionId,
  };

  factory BankSmsMessageDto.fromMap(Map<dynamic, dynamic> m) =>
      BankSmsMessageDto(
        id: m['id'] as String,
        senderAddress: m['senderAddress'] as String,
        bankKey: m['bankKey'] as String? ?? 'unknown',
        body: m['body'] as String,
        receivedAtMs: m['receivedAt'] as int,
        kind: m['kind'] as String? ?? 'info',
        transactionId: m['transactionId'] as String?,
      );
}
