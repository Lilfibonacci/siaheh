import 'package:siaheh/data/dtos/sms_sender_dto.dart';
import 'package:siaheh/domain/entities/sms_sender.dart';

class SmsSenderMapper {
  const SmsSenderMapper._();

  static SmsSender toEntity(SmsSenderDto dto) => SmsSender(
    number: dto.number,
    bankKey: dto.bankKey,
    enabled: dto.enabled,
    autoDetected: dto.autoDetected,
  );

  static SmsSenderDto toDto(SmsSender entity) => SmsSenderDto(
    number: entity.number,
    bankKey: entity.bankKey,
    enabled: entity.enabled,
    autoDetected: entity.autoDetected,
  );
}
