/// Local persistence DTO for a tracked bank SMS sender stored in Hive.
class SmsSenderDto {
  const SmsSenderDto({
    required this.number,
    required this.bankKey,
    this.enabled = true,
    this.autoDetected = false,
  });

  final String number;
  final String bankKey;
  final bool enabled;
  final bool autoDetected;

  Map<String, dynamic> toMap() => {
    'number': number,
    'bankKey': bankKey,
    'enabled': enabled,
    'autoDetected': autoDetected,
  };

  factory SmsSenderDto.fromMap(Map<dynamic, dynamic> m) => SmsSenderDto(
    number: m['number'] as String,
    bankKey: m['bankKey'] as String,
    enabled: m['enabled'] as bool? ?? true,
    autoDetected: m['autoDetected'] as bool? ?? false,
  );
}
