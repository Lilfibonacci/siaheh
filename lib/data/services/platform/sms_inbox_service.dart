import 'package:another_telephony/telephony.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// A raw SMS as read from the device.
class RawSms {
  const RawSms({
    this.id,
    required this.address,
    required this.body,
    required this.date,
  });

  final int? id;
  final String address;
  final String body;
  final DateTime date;
}

/// One keyset-paginated slice of the Android SMS inbox.
class SmsInboxPage {
  const SmsInboxPage({
    required this.messages,
    required this.hasMore,
    this.nextBeforeDateMs,
    this.nextBeforeId,
  });

  final List<RawSms> messages;
  final bool hasMore;
  final int? nextBeforeDateMs;
  final int? nextBeforeId;
}

/// Thin wrapper around the Android SMS APIs so the rest of the app never
/// touches platform channels or plugins directly.
class SmsInboxService {
  SmsInboxService({Telephony? telephony})
    : _telephony = telephony ?? Telephony.instance;

  static const MethodChannel _readerChannel = MethodChannel(
    'com.example.siaheh/sms_reader',
  );

  final Telephony _telephony;

  Future<bool> hasPermission() => Permission.sms.isGranted;

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
  Future<SmsInboxPage> readInboxPage({
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
      return const SmsInboxPage(messages: [], hasMore: false);
    }

    final rawList = (response['messages'] as List<dynamic>?) ?? const [];
    final messages = <RawSms>[];
    for (final entry in rawList) {
      if (entry is! Map) continue;
      final address = entry['address'] as String?;
      final body = entry['body'] as String?;
      if (address == null || body == null) continue;
      final dateMs = (entry['date'] as num?)?.toInt() ?? 0;
      final id = (entry['id'] as num?)?.toInt();
      messages.add(
        RawSms(
          id: id,
          address: address,
          body: body,
          date: DateTime.fromMillisecondsSinceEpoch(dateMs),
        ),
      );
    }

    return SmsInboxPage(
      messages: messages,
      hasMore: response['hasMore'] as bool? ?? false,
      nextBeforeDateMs: (response['nextBeforeDate'] as num?)?.toInt(),
      nextBeforeId: (response['nextBeforeId'] as num?)?.toInt(),
    );
  }

  /// Reads all inbox messages matching [since] across paginated slices.
  Future<List<RawSms>> readInbox({DateTime? since, int pageSize = 300}) async {
    final all = <RawSms>[];
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
  void listen(void Function(RawSms sms) onSms) {
    try {
      _telephony.listenIncomingSms(
        listenInBackground: false,
        onNewMessage: (m) {
          if (m.address == null || m.body == null) return;
          onSms(
            RawSms(
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
