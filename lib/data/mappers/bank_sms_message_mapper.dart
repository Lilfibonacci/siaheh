import 'package:siaheh/data/dtos/bank_sms_message_dto.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';

class BankSmsMessageMapper {
  const BankSmsMessageMapper._();

  static BankSmsMessage toEntity(BankSmsMessageDto dto) => BankSmsMessage(
    id: dto.id,
    senderAddress: dto.senderAddress,
    bankKey: dto.bankKey,
    body: dto.body,
    receivedAt: DateTime.fromMillisecondsSinceEpoch(dto.receivedAtMs),
    kind: BankSmsKind.values.byName(dto.kind),
    transactionId: dto.transactionId,
  );

  static BankSmsMessageDto toDto(BankSmsMessage entity) => BankSmsMessageDto(
    id: entity.id,
    senderAddress: entity.senderAddress,
    bankKey: entity.bankKey,
    body: entity.body,
    receivedAtMs: entity.receivedAt.millisecondsSinceEpoch,
    kind: entity.kind.name,
    transactionId: entity.transactionId,
  );
}
