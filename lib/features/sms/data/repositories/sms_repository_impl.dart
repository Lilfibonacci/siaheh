import 'dart:async';
import 'dart:isolate';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/features/sms/data/datasources/sms_inbox_data_source.dart';
import 'package:siaheh/features/sms/data/datasources/sms_local_data_source.dart';
import 'package:siaheh/features/sms/data/parsers/internal_transfer_detector.dart';
import 'package:siaheh/features/sms/data/parsers/sms_parser_pipeline.dart';
import 'package:siaheh/features/sms/domain/entities/bank_sms_message.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/features/sms/domain/entities/sms_sender.dart';
import 'package:siaheh/features/sms/domain/repositories/sms_repository.dart';

class SmsRepositoryImpl implements SmsRepository {
  SmsRepositoryImpl(
    this._local,
    this._inbox,
    this._pipeline,
    this._transferDetector,
  );

  /// Increment whenever bank detection / filtering rules change so cached
  /// auto-detected records on existing devices are automatically purged and
  /// rescanned cleanly.
  static const int currentDetectorVersion = 2;

  static const int _pageSize = 500;
  static const int _maxPages = 120; // Up to 60,000 SMS

  final SmsLocalDataSource _local;
  final SmsInboxDataSource _inbox;
  final SmsParserPipeline _pipeline;
  final InternalTransferDetector _transferDetector;

  final StreamController<BankSmsMessage> _incoming =
      StreamController<BankSmsMessage>.broadcast();
  bool _listening = false;
  Future<Either<Failure, SyncResult>>? _inFlightSync;

  /// Small overlap when performing incremental inbox sync so delayed SMS
  /// delivery timestamps are never skipped.
  static const Duration _syncOverlap = Duration(minutes: 2);

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
          final senders = _local.senders();
          final result = await _processSingleSms(sms, senders);
          if (result.message != null) {
            if (result.transaction != null) {
              await _linkInternalTransfers();
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
    RawSms sms,
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
        await _local.putSender(sender);
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
      await _local.putSender(sender);
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
      await _local.putTransaction(createdTx);
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
      await _local.putBankMessage(createdMessage);
    }

    return _SingleSmsResult(
      message: createdMessage,
      transaction: createdTx,
      discoveredNewSender: discoveredNewSender,
    );
  }

  Future<int> _linkInternalTransfers() async {
    final all = _local.transactions();
    final changes = _transferDetector.detectChanges(all);
    if (changes.isNotEmpty) {
      await _local.putTransactions(changes);
    }
    return changes.length ~/ 2;
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
      final effectiveFullRescan = fullRescan || needsUpgradePurge;

      if (kDebugMode) {
        debugPrint(
          '[SiahehSync] start fullRescan=$fullRescan upgradePurge=$needsUpgradePurge',
        );
      }

      if (effectiveFullRescan) {
        await _local.purgeAutoDetectedData();
      }

      final lastSync = effectiveFullRescan ? null : _local.lastSyncedAt();
      final since = lastSync?.subtract(_syncOverlap);
      final senders = _local.senders();

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
            await _local.putSenders(pendingSenders.values);
          }
          if (pendingTransactions.isNotEmpty) {
            await _local.putTransactions(pendingTransactions.values);
          }
          if (pendingMessages.isNotEmpty) {
            await _local.putBankMessages(pendingMessages.values);
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

      if (newestSeen != null) {
        await _local.setLastSyncedAt(newestSeen);
      }

      if (needsUpgradePurge) {
        await _local.setDetectorVersion(currentDetectorVersion);
      }

      if (kDebugMode) {
        debugPrint(
          '[SiahehSync] done in ${sw.elapsedMilliseconds}ms '
          '(scanned=$totalScanned, msgs=$newMessages, txs=$newTransactions, senders=$discoveredSenders)',
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
      _guard(() async => _local.transactions());

  @override
  Future<Either<Failure, Unit>> updateTransaction(BankTransaction tx) =>
      _guard(() async {
        await _local.putTransaction(tx.copyWith(userEdited: true));
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteTransaction(String id) =>
      _guard(() async {
        await _local.deleteTransaction(id);
        return unit;
      });

  @override
  Future<Either<Failure, List<BankSmsMessage>>> getBankMessages() =>
      _guard(() async => _local.bankMessages());

  @override
  Future<Either<Failure, List<SmsSender>>> getSenders() =>
      _guard(() async => _local.senders());

  @override
  Future<Either<Failure, Unit>> saveSender(SmsSender sender) =>
      _guard(() async {
        final canonical = SmsSender(
          number: SmsSender.canonicalAddress(sender.number),
          bankKey: sender.bankKey,
          enabled: sender.enabled,
          autoDetected: sender.autoDetected,
        );
        await _local.putSender(canonical);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteSender(String number) =>
      _guard(() async {
        final canonical = SmsSender.canonicalAddress(number);
        final target = _local.senders().where(
          (s) => s.number == number || s.number == canonical,
        ).firstOrNull;
        await _local.deleteSender(target?.number ?? number);
        if (target != null) {
          await _local.deleteMessagesAndAutoTransactionsForSender(target);
        }
        return unit;
      });

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
  List<RawSms> messages,
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

  final RawSms sms;
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
