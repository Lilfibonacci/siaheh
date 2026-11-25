import 'package:another_telephony/telephony.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siaheh/data/datasources/sms_inbox_data_source.dart';
import 'package:siaheh/data/dtos/raw_sms_dto.dart';

/// Thin Android platform wrapper around SMS inbox MethodChannel and Telephony
/// incoming SMS listener.
class SmsInboxDataSourceImpl implements SmsInboxDataSource {
  SmsInboxDataSourceImpl({Telephony? telephony})
    : _telephony = telephony ?? Telephony.instance;

  static const MethodChannel _readerChannel = MethodChannel(
    'com.example.siaheh/sms_reader',
  );

  final Telephony _telephony;

  @override
  Future<bool> hasPermission() => Permission.sms.isGranted;

  @override
  Future<bool> requestPermission() async {
    try {
      return (await _telephony.requestSmsPermissions) ?? false;
    } catch (_) {
      final status = await Permission.sms.request();
      return status.isGranted;
    }
  }

  /// Reads one paginated batch off the Android Main Thread using
  /// [MainActivity]'s background SMS reader channel.
  @override
  Future<SmsInboxPageDto> readInboxPage({
    DateTime? since,
    int? beforeDateMs,
    int? beforeId,
    int limit = 300,
  }) async {
    final Map<String, dynamic>? response = await _readerChannel
        .invokeMapMethod<String, dynamic>('readInboxPage', {
          'sinceMs': since?.millisecondsSinceEpoch,
          'beforeDateMs': beforeDateMs,
          'beforeId': beforeId,
          'limit': limit,
        });

    if (response == null) {
      return const SmsInboxPageDto(messages: [], hasMore: false);
    }

    return SmsInboxPageDto.fromPlatformMap(response);
  }

  /// Reads all inbox messages matching [since] across paginated slices.
  @override
  Future<List<RawSmsDto>> readInbox({
    DateTime? since,
    int pageSize = 300,
  }) async {
    final all = <RawSmsDto>[];
    int? beforeDateMs;
    int? beforeId;

    for (var pageIndex = 0; pageIndex < 200; pageIndex++) {
      final page = await readInboxPage(
        since: since,
        beforeDateMs: beforeDateMs,
        beforeId: beforeId,
        limit: pageSize,
      );
      all.addAll(page.messages);
      if (!page.hasMore ||
          page.nextBeforeDateMs == null ||
          page.nextBeforeId == null) {
        break;
      }
      beforeDateMs = page.nextBeforeDateMs;
      beforeId = page.nextBeforeId;
    }

    return all;
  }

  /// Foreground listener for new messages.
  @override
  void listen(void Function(RawSmsDto sms) onSms) {
    try {
      _telephony.listenIncomingSms(
        listenInBackground: false,
        onNewMessage: (m) {
          if (m.address == null || m.body == null) return;
          onSms(
            RawSmsDto(
              address: m.address!,
              body: m.body!,
              date: DateTime.fromMillisecondsSinceEpoch(
                m.date ?? DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          );
        },
      );
    } catch (_) {
      // Ignore foreground listener startup failures on unsupported platforms/devices.
    }
  }
}
