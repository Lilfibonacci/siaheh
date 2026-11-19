import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/features/sms/domain/entities/bank_sms_message.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/features/sms/domain/entities/sms_sender.dart';

/// Summary of an inbox sync pass.
class SyncResult extends Equatable {
  const SyncResult({
    this.newMessages = 0,
    this.newTransactions = 0,
    this.discoveredSenders = 0,
    this.linkedTransfers = 0,
  });

  final int newMessages;
  final int newTransactions;
  final int discoveredSenders;
  final int linkedTransfers;

  @override
  List<Object?> get props => [
    newMessages,
    newTransactions,
    discoveredSenders,
    linkedTransfers,
  ];
}

abstract interface class SmsRepository {
  Future<Either<Failure, List<BankTransaction>>> getTransactions();
  Future<Either<Failure, Unit>> updateTransaction(BankTransaction tx);
  Future<Either<Failure, Unit>> deleteTransaction(String id);

  Future<Either<Failure, List<BankSmsMessage>>> getBankMessages();

  Future<Either<Failure, List<SmsSender>>> getSenders();
  Future<Either<Failure, Unit>> saveSender(SmsSender sender);
  Future<Either<Failure, Unit>> deleteSender(String number);

  /// Reads the SMS inbox (incrementally by default, or full inbox when
  /// [fullRescan] is `true`), detects bank messages across all banks, stores
  /// both raw bank messages and parsed transactions, and detects internal
  /// transfers between user accounts.
  Future<Either<Failure, SyncResult>> syncInbox({bool fullRescan = false});

  /// Emits whenever a new bank SMS arrives while the app is in foreground.
  Stream<BankSmsMessage> get incomingMessages;

  Future<bool> hasSmsPermission();
  Future<bool> requestSmsPermission();
}
