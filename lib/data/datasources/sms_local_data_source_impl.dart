import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:siaheh/data/datasources/sms_local_data_source.dart';
import 'package:siaheh/data/dtos/bank_sms_message_dto.dart';
import 'package:siaheh/data/dtos/bank_transaction_dto.dart';
import 'package:siaheh/data/dtos/category_rule_dto.dart';
import 'package:siaheh/data/dtos/custom_category_dto.dart';
import 'package:siaheh/data/dtos/sms_sender_dto.dart';

/// Hive-backed implementation of [SmsLocalDataSource] with 6 boxes:
/// - `transactions`: parsed financial transactions
/// - `bank_messages`: all detected bank SMS (transactions + OTP + info + unparsed)
/// - `senders`: tracked bank senders (auto-discovered & user-added)
/// - `custom_categories`: user-created expense/income categories
/// - `category_rules`: learned merchant -> category rules
/// - `sync_meta`: incremental sync cursor & schema version metadata
class SmsLocalDataSourceImpl implements SmsLocalDataSource {
  SmsLocalDataSourceImpl(
    this._transactions,
    this._bankMessages,
    this._senders,
    this._customCategories,
    this._categoryRules,
    this._syncMeta,
  );

  static const String transactionsBox = 'transactions';
  static const String bankMessagesBox = 'bank_messages';
  static const String sendersBox = 'senders';
  static const String customCategoriesBox = 'custom_categories';
  static const String categoryRulesBox = 'category_rules';
  static const String syncMetaBox = 'sync_meta';

  static const String _lastSyncedAtKey = 'last_synced_at_ms';
  static const String _detectorVersionKey = 'detector_version';
  static const String _categorizerVersionKey = 'categorizer_version';

  final Box<Map<dynamic, dynamic>> _transactions;
  final Box<Map<dynamic, dynamic>> _bankMessages;
  final Box<Map<dynamic, dynamic>> _senders;
  final Box<Map<dynamic, dynamic>> _customCategories;
  final Box<Map<dynamic, dynamic>> _categoryRules;
  final Box<dynamic> _syncMeta;

  static Future<SmsLocalDataSourceImpl> open({Box<dynamic>? syncMeta}) async {
    final tx = await Hive.openBox<Map<dynamic, dynamic>>(transactionsBox);
    final msgs = await Hive.openBox<Map<dynamic, dynamic>>(bankMessagesBox);
    final senders = await Hive.openBox<Map<dynamic, dynamic>>(sendersBox);
    final customCats = await Hive.openBox<Map<dynamic, dynamic>>(
      customCategoriesBox,
    );
    final rules = await Hive.openBox<Map<dynamic, dynamic>>(categoryRulesBox);
    final meta = syncMeta ?? await Hive.openBox<dynamic>(syncMetaBox);
    return SmsLocalDataSourceImpl(tx, msgs, senders, customCats, rules, meta);
  }

  /// Ensures every Hive key is printable ASCII and at most 200 chars so
  /// non-ASCII sender names, Persian category names, or bidi marks never throw
  /// [HiveError].
  static String _safeKey(String raw) {
    if (raw.isNotEmpty && raw.length <= 200) {
      var printableAscii = true;
      for (final unit in raw.codeUnits) {
        if (unit < 0x20 || unit > 0x7E) {
          printableAscii = false;
          break;
        }
      }
      if (printableAscii) return raw;
    }
    return 'k_${_fnv1aHex(raw)}';
  }

  static String _fnv1aHex(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  // --- Transactions ---

  @override
  List<BankTransactionDto> transactions() =>
      _transactions.values.map(BankTransactionDto.fromMap).toList()
        ..sort((a, b) => b.occurredAtMs.compareTo(a.occurredAtMs));

  @override
  bool hasTransaction(String id) => _transactions.containsKey(_safeKey(id));

  @override
  Future<void> putTransaction(BankTransactionDto tx) =>
      _transactions.put(_safeKey(tx.id), tx.toMap());

  @override
  Future<void> putTransactions(Iterable<BankTransactionDto> items) async {
    final entries = {for (final tx in items) _safeKey(tx.id): tx.toMap()};
    if (entries.isEmpty) return;
    await _transactions.putAll(entries);
  }

  @override
  Future<void> deleteTransaction(String id) =>
      _transactions.delete(_safeKey(id));

  // --- Bank SMS Messages (all bank messages) ---

  @override
  List<BankSmsMessageDto> bankMessages() =>
      _bankMessages.values.map(BankSmsMessageDto.fromMap).toList()
        ..sort((a, b) => b.receivedAtMs.compareTo(a.receivedAtMs));

  @override
  bool hasBankMessage(String id) => _bankMessages.containsKey(_safeKey(id));

  @override
  Future<void> putBankMessage(BankSmsMessageDto message) =>
      _bankMessages.put(_safeKey(message.id), message.toMap());

  @override
  Future<void> putBankMessages(Iterable<BankSmsMessageDto> items) async {
    final entries = {for (final m in items) _safeKey(m.id): m.toMap()};
    if (entries.isEmpty) return;
    await _bankMessages.putAll(entries);
  }

  // --- Senders ---

  @override
  List<SmsSenderDto> senders() =>
      _senders.values.map(SmsSenderDto.fromMap).toList();

  @override
  Future<void> putSender(SmsSenderDto sender) =>
      _senders.put(_safeKey(sender.number), sender.toMap());

  @override
  Future<void> putSenders(Iterable<SmsSenderDto> items) async {
    final entries = {for (final s in items) _safeKey(s.number): s.toMap()};
    if (entries.isEmpty) return;
    await _senders.putAll(entries);
  }

  @override
  Future<void> deleteSender(String number) =>
      _senders.delete(_safeKey(number));

  // --- Custom Categories ---

  @override
  List<CustomCategoryDto> customCategories() =>
      _customCategories.values.map(CustomCategoryDto.fromMap).toList();

  @override
  Future<void> putCustomCategory(CustomCategoryDto category) =>
      _customCategories.put(_safeKey(category.name), category.toMap());

  @override
  Future<void> deleteCustomCategory(String name) =>
      _customCategories.delete(_safeKey(name));

  // --- Learned Category Rules ---

  @override
  List<CategoryRuleDto> categoryRules() =>
      _categoryRules.values.map(CategoryRuleDto.fromMap).toList();

  @override
  Future<void> putCategoryRule(CategoryRuleDto rule) =>
      _categoryRules.put(_safeKey(rule.pattern), rule.toMap());

  @override
  Future<void> deleteCategoryRule(String pattern) =>
      _categoryRules.delete(_safeKey(pattern));

  // --- Sync Cursor & Schema Versions ---

  @override
  DateTime? lastSyncedAt() {
    final ms = _syncMeta.get(_lastSyncedAtKey) as int?;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> setLastSyncedAt(DateTime timestamp) =>
      _syncMeta.put(_lastSyncedAtKey, timestamp.millisecondsSinceEpoch);

  @override
  Future<void> clearLastSyncedAt() => _syncMeta.delete(_lastSyncedAtKey);

  @override
  int detectorVersion() => (_syncMeta.get(_detectorVersionKey) as int?) ?? 0;

  @override
  Future<void> setDetectorVersion(int version) =>
      _syncMeta.put(_detectorVersionKey, version);

  @override
  int categorizerVersion() =>
      (_syncMeta.get(_categorizerVersionKey) as int?) ?? 0;

  @override
  Future<void> setCategorizerVersion(int version) =>
      _syncMeta.put(_categorizerVersionKey, version);

  /// Purges auto-detected senders (that are still enabled), all cached
  /// bank messages, and non-user-edited transactions so a fresh full rescan
  /// can cleanly rebuild state using updated detection rules.
  ///
  /// User-added manual senders, user-disabled senders, `userEdited == true`
  /// transactions, custom categories, and learned rules are preserved.
  @override
  Future<void> purgeAutoDetectedData() async {
    final senderKeysToDelete = <dynamic>[];
    for (final key in _senders.keys) {
      final raw = _senders.get(key);
      if (raw == null) continue;
      final sender = SmsSenderDto.fromMap(raw);
      if (sender.autoDetected && sender.enabled) {
        senderKeysToDelete.add(key);
      }
    }
    if (senderKeysToDelete.isNotEmpty) {
      await _senders.deleteAll(senderKeysToDelete);
    }

    await _bankMessages.clear();

    final txKeysToDelete = <dynamic>[];
    for (final key in _transactions.keys) {
      final raw = _transactions.get(key);
      if (raw == null) continue;
      final tx = BankTransactionDto.fromMap(raw);
      if (!tx.userEdited) {
        txKeysToDelete.add(key);
      }
    }
    if (txKeysToDelete.isNotEmpty) {
      await _transactions.deleteAll(txKeysToDelete);
    }

    await clearLastSyncedAt();
  }

  /// Removes cached bank messages and non-user-edited transactions matching
  /// [matchesAddress].
  @override
  Future<void> deleteMessagesAndAutoTransactionsMatching(
    bool Function(String address) matchesAddress,
  ) async {
    final msgKeysToDelete = <dynamic>[];
    for (final key in _bankMessages.keys) {
      final raw = _bankMessages.get(key);
      if (raw == null) continue;
      final msg = BankSmsMessageDto.fromMap(raw);
      if (matchesAddress(msg.senderAddress)) {
        msgKeysToDelete.add(key);
      }
    }
    if (msgKeysToDelete.isNotEmpty) {
      await _bankMessages.deleteAll(msgKeysToDelete);
    }

    final txKeysToDelete = <dynamic>[];
    for (final key in _transactions.keys) {
      final raw = _transactions.get(key);
      if (raw == null) continue;
      final tx = BankTransactionDto.fromMap(raw);
      if (!tx.userEdited && matchesAddress(tx.senderNumber)) {
        txKeysToDelete.add(key);
      }
    }
    if (txKeysToDelete.isNotEmpty) {
      await _transactions.deleteAll(txKeysToDelete);
    }
  }
}
