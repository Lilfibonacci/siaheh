import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:siaheh/features/sms/domain/entities/bank_sms_message.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/features/sms/domain/entities/category_rule.dart';
import 'package:siaheh/features/sms/domain/entities/custom_category.dart';
import 'package:siaheh/features/sms/domain/entities/sms_sender.dart';

/// Hive-backed local storage with 6 clean boxes:
/// - `transactions`: parsed financial transactions
/// - `bank_messages`: all detected bank SMS (transactions + OTP + info + unparsed)
/// - `senders`: tracked bank senders (auto-discovered & user-added)
/// - `custom_categories`: user-created expense/income categories
/// - `category_rules`: learned merchant -> category rules
/// - `sync_meta`: incremental sync cursor & schema version metadata
class SmsLocalDataSource {
  SmsLocalDataSource(
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
  static const String _themeModeKey = 'theme_mode';

  final Box<Map<dynamic, dynamic>> _transactions;
  final Box<Map<dynamic, dynamic>> _bankMessages;
  final Box<Map<dynamic, dynamic>> _senders;
  final Box<Map<dynamic, dynamic>> _customCategories;
  final Box<Map<dynamic, dynamic>> _categoryRules;
  final Box<dynamic> _syncMeta;

  static Future<SmsLocalDataSource> open() async {
    final tx = await Hive.openBox<Map<dynamic, dynamic>>(transactionsBox);
    final msgs = await Hive.openBox<Map<dynamic, dynamic>>(bankMessagesBox);
    final senders = await Hive.openBox<Map<dynamic, dynamic>>(sendersBox);
    final customCats = await Hive.openBox<Map<dynamic, dynamic>>(
      customCategoriesBox,
    );
    final rules = await Hive.openBox<Map<dynamic, dynamic>>(categoryRulesBox);
    final meta = await Hive.openBox<dynamic>(syncMetaBox);
    return SmsLocalDataSource(tx, msgs, senders, customCats, rules, meta);
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

  List<BankTransaction> transactions() =>
      _transactions.values.map(BankTransaction.fromMap).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  bool hasTransaction(String id) => _transactions.containsKey(_safeKey(id));

  Future<void> putTransaction(BankTransaction tx) =>
      _transactions.put(_safeKey(tx.id), tx.toMap());

  Future<void> putTransactions(Iterable<BankTransaction> items) async {
    final entries = {for (final tx in items) _safeKey(tx.id): tx.toMap()};
    if (entries.isEmpty) return;
    await _transactions.putAll(entries);
  }

  Future<void> deleteTransaction(String id) =>
      _transactions.delete(_safeKey(id));

  // --- Bank SMS Messages (all bank messages) ---

  List<BankSmsMessage> bankMessages() =>
      _bankMessages.values.map(BankSmsMessage.fromMap).toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

  bool hasBankMessage(String id) => _bankMessages.containsKey(_safeKey(id));

  Future<void> putBankMessage(BankSmsMessage message) =>
      _bankMessages.put(_safeKey(message.id), message.toMap());

  Future<void> putBankMessages(Iterable<BankSmsMessage> items) async {
    final entries = {for (final m in items) _safeKey(m.id): m.toMap()};
    if (entries.isEmpty) return;
    await _bankMessages.putAll(entries);
  }

  // --- Senders ---

  List<SmsSender> senders() =>
      _senders.values.map(SmsSender.fromMap).toList();

  Future<void> putSender(SmsSender sender) =>
      _senders.put(_safeKey(sender.number), sender.toMap());

  Future<void> putSenders(Iterable<SmsSender> items) async {
    final entries = {for (final s in items) _safeKey(s.number): s.toMap()};
    if (entries.isEmpty) return;
    await _senders.putAll(entries);
  }

  Future<void> deleteSender(String number) =>
      _senders.delete(_safeKey(number));

  // --- Custom Categories ---

  List<CustomCategory> customCategories() =>
      _customCategories.values.map(CustomCategory.fromMap).toList();

  Future<void> putCustomCategory(CustomCategory category) =>
      _customCategories.put(_safeKey(category.name), category.toMap());

  Future<void> deleteCustomCategory(String name) =>
      _customCategories.delete(_safeKey(name));

  // --- Learned Category Rules ---

  List<CategoryRule> categoryRules() =>
      _categoryRules.values.map(CategoryRule.fromMap).toList();

  Future<void> putCategoryRule(CategoryRule rule) =>
      _categoryRules.put(_safeKey(rule.pattern), rule.toMap());

  Future<void> deleteCategoryRule(String pattern) =>
      _categoryRules.delete(_safeKey(pattern));

  // --- Sync Cursor & Schema Versions ---

  DateTime? lastSyncedAt() {
    final ms = _syncMeta.get(_lastSyncedAtKey) as int?;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastSyncedAt(DateTime timestamp) =>
      _syncMeta.put(_lastSyncedAtKey, timestamp.millisecondsSinceEpoch);

  Future<void> clearLastSyncedAt() => _syncMeta.delete(_lastSyncedAtKey);

  int detectorVersion() => (_syncMeta.get(_detectorVersionKey) as int?) ?? 0;

  Future<void> setDetectorVersion(int version) =>
      _syncMeta.put(_detectorVersionKey, version);

  int categorizerVersion() =>
      (_syncMeta.get(_categorizerVersionKey) as int?) ?? 0;

  Future<void> setCategorizerVersion(int version) =>
      _syncMeta.put(_categorizerVersionKey, version);

  /// Purges auto-detected senders (that are still enabled), all cached
  /// bank messages, and non-user-edited transactions so a fresh full rescan
  /// can cleanly rebuild state using updated detection rules.
  ///
  /// User-added manual senders, user-disabled senders, `userEdited == true`
  /// transactions, custom categories, and learned rules are preserved.
  Future<void> purgeAutoDetectedData() async {
    final senderKeysToDelete = <dynamic>[];
    for (final key in _senders.keys) {
      final raw = _senders.get(key);
      if (raw == null) continue;
      final sender = SmsSender.fromMap(raw);
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
      final tx = BankTransaction.fromMap(raw);
      if (!tx.userEdited) {
        txKeysToDelete.add(key);
      }
    }
    if (txKeysToDelete.isNotEmpty) {
      await _transactions.deleteAll(txKeysToDelete);
    }

    await clearLastSyncedAt();
  }

  /// Removes cached bank messages and non-user-edited transactions belonging
  /// to [sender].
  Future<void> deleteMessagesAndAutoTransactionsForSender(
    SmsSender sender,
  ) async {
    final msgKeysToDelete = <dynamic>[];
    for (final key in _bankMessages.keys) {
      final raw = _bankMessages.get(key);
      if (raw == null) continue;
      final msg = BankSmsMessage.fromMap(raw);
      if (sender.matchesAddress(msg.senderAddress)) {
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
      final tx = BankTransaction.fromMap(raw);
      if (!tx.userEdited && sender.matchesAddress(tx.senderNumber)) {
        txKeysToDelete.add(key);
      }
    }
    if (txKeysToDelete.isNotEmpty) {
      await _transactions.deleteAll(txKeysToDelete);
    }
  }

  // --- App Theme Preference ---

  String? get themeModeName {
    final raw = _syncMeta.get(_themeModeKey);
    return raw is String ? raw : null;
  }

  Future<void> setThemeModeName(String name) =>
      _syncMeta.put(_themeModeKey, name);
}
