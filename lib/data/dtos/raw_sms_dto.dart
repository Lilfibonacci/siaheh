/// Raw SMS payload returned by the Android SMS inbox platform channel or live
/// incoming listener. Kept as a plain immutable class for `Isolate.run`.
class RawSmsDto {
  const RawSmsDto({
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
class SmsInboxPageDto {
  const SmsInboxPageDto({
    required this.messages,
    required this.hasMore,
    this.nextBeforeDateMs,
    this.nextBeforeId,
  });

  final List<RawSmsDto> messages;
  final bool hasMore;
  final int? nextBeforeDateMs;
  final int? nextBeforeId;

  factory SmsInboxPageDto.fromPlatformMap(Map<String, dynamic> response) {
    final rawList = (response['messages'] as List<dynamic>?) ?? const [];
    final messages = <RawSmsDto>[];
    for (final entry in rawList) {
      if (entry is! Map) continue;
      final address = entry['address'] as String?;
      final body = entry['body'] as String?;
      if (address == null || body == null) continue;
      final dateMs = (entry['date'] as num?)?.toInt() ?? 0;
      final id = (entry['id'] as num?)?.toInt();
      messages.add(
        RawSmsDto(
          id: id,
          address: address,
          body: body,
          date: DateTime.fromMillisecondsSinceEpoch(dateMs),
        ),
      );
    }

    return SmsInboxPageDto(
      messages: messages,
      hasMore: response['hasMore'] as bool? ?? false,
      nextBeforeDateMs: (response['nextBeforeDate'] as num?)?.toInt(),
      nextBeforeId: (response['nextBeforeId'] as num?)?.toInt(),
    );
  }
}
