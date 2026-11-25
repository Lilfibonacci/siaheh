import 'dart:async';
import 'dart:isolate';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/data/datasources/sms_inbox_data_source.dart';
import 'package:siaheh/data/datasources/sms_local_data_source.dart';
import 'package:siaheh/data/dtos/raw_sms_dto.dart';
import 'package:siaheh/data/mappers/bank_sms_message_mapper.dart';
import 'package:siaheh/data/mappers/bank_transaction_mapper.dart';
import 'package:siaheh/data/mappers/category_rule_mapper.dart';
import 'package:siaheh/data/mappers/custom_category_mapper.dart';
import 'package:siaheh/data/mappers/sms_sender_mapper.dart';
import 'package:siaheh/data/parsers/expense_categorizer.dart';
import 'package:siaheh/data/parsers/internal_transfer_detector.dart';
import 'package:siaheh/data/parsers/sms_parser_pipeline.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';
import 'package:siaheh/domain/entities/category_rule.dart';
import 'package:siaheh/domain/entities/custom_category.dart';
import 'package:siaheh/domain/entities/sms_sender.dart';
import 'package:siaheh/domain/entities/sync_result.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class SmsRepositoryImpl implements SmsRepository {
  SmsRepositoryImpl(
    this._local,
    this._inbox,
    this._pipeline,
    this._transferDetector,
    this._categorizer,
  );

  /// Increment whenever bank detection / filtering rules change so cached
  /// auto-detected records on existing devices are automatically purged and
  /// rescanned cleanly.
  static const int currentDetectorVersion = 2;

  /// Increment whenever auto-categorization rules or OTP correlation improve
  /// so existing unedited transactions are re-categorized once without needing
  /// to re-read the entire Android SMS inbox.
  static const int currentCategorizerVersion = 1;

  static const int _pageSize = 500;
  static const int _maxPages = 120; // Up to 60,000 SMS

  final SmsLocalDataSource _local;
  final SmsInboxDataSource _inbox;
  final SmsParserPipeline _pipeline;
  final InternalTransferDetector _transferDetector;
  final ExpenseCategorizer _categorizer;

  final StreamController<BankSmsMessage> _incoming =
      StreamController<BankSmsMessage>.broadcast();
  bool _listening = false;
  Future<Either<Failure, SyncResult>>? _inFlightSync;

  /// Small overlap when performing incremental inbox sync so delayed SMS
  /// delivery timestamps are never skipped.
  static const Duration _syncOverlap = Duration(minutes: 2);

  static const Set<String> _genericTitles = {
    'برداشت از حساب',
    'واریز به حساب',
    'انتقال بین حساب‌ها',
    'خرید فروشگاهی',
    'تراکنش نامشخص',
  };

  @override
  Stream<BankSmsMessage> get incomingMessages {
    _startListening();
    return _incoming.stream;
  }

  Future<void> _startListening() async {
    try {
      if (_listening || !await _inbox.hasPermission()) return;
      _listening = true;
      _inbox.listen((sms) async {
        try {
          final senders = _local
              .senders()
              .map(SmsSenderMapper.toEntity)
              .toList();
          final result = await _processSingleSms(sms, senders);
          if (result.message != null) {
            if (result.transaction != null) {
              await _linkInternalTransfers();
            }
            if (result.transaction != null ||
                result.message!.kind == BankSmsKind.otp) {
              await _categorizeUneditedTransactions();
            }
            await _local.setLastSyncedAt(sms.date);
            _incoming.add(result.message!);
          }
        } catch (_) {
          // Keep live listener resilient against malformed incoming SMS.
        }
      });
    } catch (_) {
      _listening = false;
    }
  }

  Future<_SingleSmsResult> _processSingleSms(
    RawSmsDto sms,
    List<SmsSender> senders,
  ) async {
    final outcome = _pipeline.process(
      address: sms.address,
      body: sms.body,
      receivedAt: sms.date,
      knownSenders: senders,
    );

    if (!outcome.isBankSms) return const _SingleSmsResult();

    final canonicalNumber = SmsSender.canonicalAddress(sms.address);

    // Auto-discover & persist new bank senders only when the sender is an
    // official bank address OR produced a parsed financial transaction.
    // This keeps shared-panel non-transaction messages from polluting senders.
    var discoveredNewSender = false;
    var senderNumberForRecord = canonicalNumber;
    if (outcome.matchedSender != null) {
      var sender = outcome.matchedSender!;
      senderNumberForRecord = sender.number;
      // Upgrade an 'unknown' sender if we now identified its real bankKey.
      if (sender.bankKey == 'unknown' && outcome.bankKey != 'unknown') {
        sender = sender.copyWith(bankKey: outcome.bankKey);
        await _local.putSender(SmsSenderMapper.toDto(sender));
        final idx = senders.indexWhere((s) => s.number == sender.number);
        if (idx >= 0) senders[idx] = sender;
      }
    } else if (outcome.isOfficialSender ||
        outcome.kind == BankSmsKind.transaction) {
      final sender = SmsSender(
        number: canonicalNumber,
        bankKey: outcome.bankKey,
        enabled: true,
        autoDetected: true,
      );
      await _local.putSender(SmsSenderMapper.toDto(sender));
      senders.add(sender);
      discoveredNewSender = true;
    }

    final id = _buildStableId(senderNumberForRecord, sms.date, sms.body);

    BankTransaction? createdTx;
    if (outcome.kind == BankSmsKind.transaction &&
        outcome.parsed != null &&
        !_local.hasTransaction(id)) {
      final parsed = outcome.parsed!;
      createdTx = BankTransaction(
        id: id,
        bankKey: outcome.bankKey,
        accountNumber: parsed.accountNumber,
        senderNumber: senderNumberForRecord,
        amountRial: parsed.amountRial,
        type: parsed.type,
        occurredAt: parsed.occurredAt,
        rawBody: sms.body,
        smsId: id,
        balanceRial: parsed.balanceRial,
        title: parsed.suggestedTitle,
        needsReview: parsed.needsReview,
      );
      await _local.putTransaction(BankTransactionMapper.toDto(createdTx));
    }

    BankSmsMessage? createdMessage;
    if (!_local.hasBankMessage(id)) {
      createdMessage = BankSmsMessage(
        id: id,
        senderAddress: sms.address,
        bankKey: outcome.bankKey,
        body: sms.body,
        receivedAt: sms.date,
        kind: outcome.kind,
        transactionId:
            outcome.kind == BankSmsKind.transaction ? id : null,
      );
      await _local.putBankMessage(BankSmsMessageMapper.toDto(createdMessage));
    }

    return _SingleSmsResult(
      message: createdMessage,
      transaction: createdTx,
      discoveredNewSender: discoveredNewSender,
    );
  }

  Future<int> _linkInternalTransfers() async {
    final all = _local
        .transactions()
        .map(BankTransactionMapper.toEntity)
        .toList();
    final changes = _transferDetector.detectChanges(all);
    if (changes.isNotEmpty) {
      await _local.putTransactions(changes.map(BankTransactionMapper.toDto));
    }
    return changes.length ~/ 2;
  }

  Future<int> _categorizeUneditedTransactions() async {
    final allTx = _local
        .transactions()
        .map(BankTransactionMapper.toEntity)
        .toList();
    final allMsgs = _local
        .bankMessages()
        .map(BankSmsMessageMapper.toEntity)
        .toList();
    final rules = _local
        .categoryRules()
        .map(CategoryRuleMapper.toEntity)
        .toList();
    final changes = _categorizer.categorizeAll(
      transactions: allTx,
      bankMessages: allMsgs,
      userRules: rules,
    );
    if (changes.isNotEmpty) {
      await _local.putTransactions(changes.map(BankTransactionMapper.toDto));
    }
    return changes.length;
  }

  @override
  Future<Either<Failure, SyncResult>> syncInbox({bool fullRescan = false}) {
    final inFlight = _inFlightSync;
    if (inFlight != null) return inFlight;

    final future = _runSyncInbox(fullRescan: fullRescan).whenComplete(() {
      _inFlightSync = null;
    });
    _inFlightSync = future;
    return future;
  }

  Future<Either<Failure, SyncResult>> _runSyncInbox({
    required bool fullRescan,
  }) async {
    final sw = Stopwatch()..start();
    try {
      if (!await _inbox.hasPermission()) return const Left(PermissionFailure());

      final needsUpgradePurge =
          _local.detectorVersion() < currentDetectorVersion;
      final needsRecategorize =
          _local.categorizerVersion() < currentCategorizerVersion;
      final effectiveFullRescan = fullRescan || needsUpgradePurge;

      if (kDebugMode) {
        debugPrint(
          '[SiahehSync] start fullRescan=$fullRescan upgradePurge=$needsUpgradePurge recategorize=$needsRecategorize',
        );
      }

      if (effectiveFullRescan) {
        await _local.purgeAutoDetectedData();
      }

      final lastSync = effectiveFullRescan ? null : _local.lastSyncedAt();
      final since = lastSync?.subtract(_syncOverlap);
      final senders = _local
          .senders()
          .map(SmsSenderMapper.toEntity)
          .toList();

      var newMessages = 0;
      var newTransactions = 0;
      var discoveredSenders = 0;
      var totalScanned = 0;
      DateTime? newestSeen = lastSync;

      int? beforeDateMs;
      int? beforeId;

      for (var pageIndex = 0; pageIndex < _maxPages; pageIndex++) {
        final page = await _inbox.readInboxPage(
          since: since,
          beforeDateMs: beforeDateMs,
          beforeId: beforeId,
          limit: _pageSize,
        );

        if (page.messages.isEmpty && !page.hasMore) break;
        totalScanned += page.messages.length;

        for (final sms in page.messages) {
          if (newestSeen == null || sms.date.isAfter(newestSeen)) {
            newestSeen = sms.date;
          }
        }

        if (page.messages.isNotEmpty) {
          final snapshot = List<SmsSender>.of(senders);
          final batch = page.messages;
          final parsedItems = await Isolate.run(
            () => _parseBatchInIsolate(batch, snapshot),
          );

          final pendingSenders = <String, SmsSender>{};
          final pendingTransactions = <String, BankTransaction>{};
          final pendingMessages = <String, BankSmsMessage>{};

          for (final item in parsedItems) {
            final sms = item.sms;
            final outcome = item.outcome;

            final matched = senders
                .where((s) => s.matchesAddress(sms.address))
                .firstOrNull;
            var senderNumberForRecord = item.canonicalAddress;

            if (matched != null) {
              senderNumberForRecord = matched.number;
              if (matched.bankKey == 'unknown' &&
                  outcome.bankKey != 'unknown') {
                final upgraded = matched.copyWith(bankKey: outcome.bankKey);
                final idx = senders.indexWhere(
                  (s) => s.number == matched.number,
                );
                if (idx >= 0) senders[idx] = upgraded;
                pendingSenders[upgraded.number] = upgraded;
              }
            } else if (outcome.isOfficialSender ||
                outcome.kind == BankSmsKind.transaction) {
              final createdSender = SmsSender(
                number: item.canonicalAddress,
                bankKey: outcome.bankKey,
                enabled: true,
                autoDetected: true,
              );
              senders.add(createdSender);
              pendingSenders[createdSender.number] = createdSender;
              discoveredSenders++;
            }

            final id = _buildStableId(senderNumberForRecord, sms.date, sms.body);

            if (outcome.kind == BankSmsKind.transaction &&
                outcome.parsed != null &&
                !_local.hasTransaction(id) &&
                !pendingTransactions.containsKey(id)) {
              final parsed = outcome.parsed!;
              pendingTransactions[id] = BankTransaction(
                id: id,
                bankKey: outcome.bankKey,
                accountNumber: parsed.accountNumber,
                senderNumber: senderNumberForRecord,
                amountRial: parsed.amountRial,
                type: parsed.type,
                occurredAt: parsed.occurredAt,
                rawBody: sms.body,
                smsId: id,
                balanceRial: parsed.balanceRial,
                title: parsed.suggestedTitle,
                needsReview: parsed.needsReview,
              );
              newTransactions++;
            }

            if (!_local.hasBankMessage(id) &&
                !pendingMessages.containsKey(id)) {
              pendingMessages[id] = BankSmsMessage(
                id: id,
                senderAddress: sms.address,
                bankKey: outcome.bankKey,
                body: sms.body,
                receivedAt: sms.date,
                kind: outcome.kind,
                transactionId:
                    outcome.kind == BankSmsKind.transaction ? id : null,
              );
              newMessages++;
            }
          }

          if (pendingSenders.isNotEmpty) {
            await _local.putSenders(
              pendingSenders.values.map(SmsSenderMapper.toDto),
            );
          }
          if (pendingTransactions.isNotEmpty) {
            await _local.putTransactions(
              pendingTransactions.values.map(BankTransactionMapper.toDto),
            );
          }
          if (pendingMessages.isNotEmpty) {
            await _local.putBankMessages(
              pendingMessages.values.map(BankSmsMessageMapper.toDto),
            );
          }
        }

        if (!page.hasMore ||
            page.nextBeforeDateMs == null ||
            page.nextBeforeId == null) {
          break;
        }
        if (page.nextBeforeDateMs == beforeDateMs &&
            page.nextBeforeId == beforeId) {
          break;
        }
        beforeDateMs = page.nextBeforeDateMs;
        beforeId = page.nextBeforeId;
        await Future<void>.delayed(Duration.zero);
      }

      var linkedTransfers = 0;
      if (newTransactions > 0 || effectiveFullRescan) {
        linkedTransfers = await _linkInternalTransfers();
      }

      var categorizedCount = 0;
      if (newTransactions > 0 ||
          newMessages > 0 ||
          effectiveFullRescan ||
          needsRecategorize) {
        categorizedCount = await _categorizeUneditedTransactions();
      }

      if (newestSeen != null) {
        await _local.setLastSyncedAt(newestSeen);
      }

      if (needsUpgradePurge) {
        await _local.setDetectorVersion(currentDetectorVersion);
      }
      if (needsRecategorize) {
        await _local.setCategorizerVersion(currentCategorizerVersion);
      }

      if (kDebugMode) {
        debugPrint(
          '[SiahehSync] done in ${sw.elapsedMilliseconds}ms '
          '(scanned=$totalScanned, msgs=$newMessages, txs=$newTransactions, '
          'senders=$discoveredSenders, categorized=$categorizedCount)',
        );
      }

      return Right(
        SyncResult(
          newMessages: newMessages,
          newTransactions: newTransactions,
          discoveredSenders: discoveredSenders,
          linkedTransfers: linkedTransfers,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SiahehSync] failed after ${sw.elapsedMilliseconds}ms: $e');
      }
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, List<BankTransaction>>> getTransactions() =>
      _guard(
        () async => _local
            .transactions()
            .map(BankTransactionMapper.toEntity)
            .toList(),
      );

  @override
  Future<Either<Failure, Unit>> updateTransaction(
    BankTransaction tx, {
    bool applyToSimilar = false,
  }) => _guard(() async {
    final edited = tx.copyWith(userEdited: true);
    await _local.putTransaction(BankTransactionMapper.toDto(edited));

    if (applyToSimilar && edited.categoryId != null) {
      final candidatePattern = _extractLearningPattern(edited);
      if (candidatePattern != null) {
        final rule = CategoryRule(
          pattern: candidatePattern,
          categoryId: edited.categoryId!,
          preferredTitle:
              edited.title != null && !_genericTitles.contains(edited.title)
              ? edited.title
              : null,
        );
        await _local.putCategoryRule(CategoryRuleMapper.toDto(rule));

        final existing = _local
            .transactions()
            .map(BankTransactionMapper.toEntity)
            .toList();
        final similarChanges = _categorizer.applyRuleToExisting(
          transactions: existing,
          rule: rule,
          excludeTransactionId: edited.id,
        );
        if (similarChanges.isNotEmpty) {
          await _local.putTransactions(
            similarChanges.map(BankTransactionMapper.toDto),
          );
        }
      }
    }
    return unit;
  });

  static String? _extractLearningPattern(BankTransaction tx) {
    final merchant = tx.merchantName?.trim();
    if (merchant != null && merchant.length >= 2) {
      return ExpenseCategorizer.normalizePattern(merchant);
    }
    final title = tx.title?.trim();
    if (title != null &&
        title.length >= 2 &&
        !_genericTitles.contains(title)) {
      return ExpenseCategorizer.normalizePattern(title);
    }
    return null;
  }

  @override
  Future<Either<Failure, Unit>> deleteTransaction(String id) =>
      _guard(() async {
        await _local.deleteTransaction(id);
        return unit;
      });

  @override
  Future<Either<Failure, List<BankSmsMessage>>> getBankMessages() =>
      _guard(
        () async => _local
            .bankMessages()
            .map(BankSmsMessageMapper.toEntity)
            .toList(),
      );

  @override
  Future<Either<Failure, List<SmsSender>>> getSenders() =>
      _guard(
        () async => _local.senders().map(SmsSenderMapper.toEntity).toList(),
      );

  @override
  Future<Either<Failure, Unit>> saveSender(SmsSender sender) =>
      _guard(() async {
        final canonical = SmsSender(
          number: SmsSender.canonicalAddress(sender.number),
          bankKey: sender.bankKey,
          enabled: sender.enabled,
          autoDetected: sender.autoDetected,
        );
        await _local.putSender(SmsSenderMapper.toDto(canonical));
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteSender(String number) =>
      _guard(() async {
        final canonical = SmsSender.canonicalAddress(number);
        final targetDto = _local.senders().where(
          (s) => s.number == number || s.number == canonical,
        ).firstOrNull;
        await _local.deleteSender(targetDto?.number ?? number);
        if (targetDto != null) {
          final target = SmsSenderMapper.toEntity(targetDto);
          await _local.deleteMessagesAndAutoTransactionsMatching(
            target.matchesAddress,
          );
        }
        return unit;
      });

  @override
  Future<Either<Failure, List<CustomCategory>>> getCustomCategories() =>
      _guard(
        () async => _local
            .customCategories()
            .map(CustomCategoryMapper.toEntity)
            .toList(),
      );

  @override
  Future<Either<Failure, Unit>> saveCustomCategory(CustomCategory category) =>
      _guard(() async {
        await _local.putCustomCategory(CustomCategoryMapper.toDto(category));
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteCustomCategory(String name) =>
      _guard(() async {
        await _local.deleteCustomCategory(name);
        return unit;
      });

  @override
  Future<Either<Failure, List<CategoryRule>>> getCategoryRules() =>
      _guard(
        () async => _local
            .categoryRules()
            .map(CategoryRuleMapper.toEntity)
            .toList(),
      );

  @override
  Future<bool> hasSmsPermission() => _inbox.hasPermission();

  @override
  Future<bool> requestSmsPermission() => _inbox.requestPermission();

  static String _buildStableId(String senderKey, DateTime date, String body) =>
      '${senderKey}_${date.millisecondsSinceEpoch}_${_stableHash(body)}';

  /// FNV-1a, stable across app launches.
  static int _stableHash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } catch (_) {
      return const Left(CacheFailure());
    }
  }
}

/// Top-level batch worker executed via [Isolate.run] to keep regex parsing off
/// the Dart UI thread.
List<_ParsedBatchItem> _parseBatchInIsolate(
  List<RawSmsDto> messages,
  List<SmsSender> knownSenders,
) {
  final pipeline = SmsParserPipeline();
  final workingSenders = List<SmsSender>.of(knownSenders);
  final results = <_ParsedBatchItem>[];

  for (final sms in messages) {
    final outcome = pipeline.process(
      address: sms.address,
      body: sms.body,
      receivedAt: sms.date,
      knownSenders: workingSenders,
    );
    if (!outcome.isBankSms) continue;

    final canonical = SmsSender.canonicalAddress(sms.address);
    if (outcome.matchedSender == null &&
        (outcome.isOfficialSender || outcome.kind == BankSmsKind.transaction)) {
      workingSenders.add(
        SmsSender(
          number: canonical,
          bankKey: outcome.bankKey,
          enabled: true,
          autoDetected: true,
        ),
      );
    }

    results.add(
      _ParsedBatchItem(
        sms: sms,
        outcome: outcome,
        canonicalAddress: canonical,
      ),
    );
  }

  return results;
}

class _ParsedBatchItem {
  const _ParsedBatchItem({
    required this.sms,
    required this.outcome,
    required this.canonicalAddress,
  });

  final RawSmsDto sms;
  final SmsParseOutcome outcome;
  final String canonicalAddress;
}

class _SingleSmsResult {
  const _SingleSmsResult({
    this.message,
    this.transaction,
    this.discoveredNewSender = false,
  });

  final BankSmsMessage? message;
  final BankTransaction? transaction;
  final bool discoveredNewSender;
}
