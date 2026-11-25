import 'package:siaheh/data/dtos/raw_sms_dto.dart';

/// Contract for reading Android SMS inbox pages, requesting SMS permissions,
/// and listening to incoming SMS messages while the app is open.
abstract interface class SmsInboxDataSource {
  Future<bool> hasPermission();

  Future<bool> requestPermission();

  Future<SmsInboxPageDto> readInboxPage({
    DateTime? since,
    int? beforeDateMs,
    int? beforeId,
    int limit = 300,
  });

  Future<List<RawSmsDto>> readInbox({DateTime? since, int pageSize = 300});

  void listen(void Function(RawSmsDto sms) onSms);
}
