import 'package:dartz/dartz.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';
import 'package:siaheh/domain/entities/category_rule.dart';
import 'package:siaheh/domain/entities/custom_category.dart';
import 'package:siaheh/domain/entities/sms_sender.dart';
import 'package:siaheh/domain/entities/sync_result.dart';

abstract interface class SmsRepository {
  Future<Either<Failure, List<BankTransaction>>> getTransactions();

  /// Saves an edited transaction. When [applyToSimilar] is `true`, also learns
  /// a [CategoryRule] from its merchant/title and applies the category to all
  /// matching unedited transactions.
  Future<Either<Failure, Unit>> updateTransaction(
    BankTransaction tx, {
    bool applyToSimilar = false,
  });

  Future<Either<Failure, Unit>> deleteTransaction(String id);

  Future<Either<Failure, List<BankSmsMessage>>> getBankMessages();

  Future<Either<Failure, List<SmsSender>>> getSenders();
  Future<Either<Failure, Unit>> saveSender(SmsSender sender);
  Future<Either<Failure, Unit>> deleteSender(String number);

  Future<Either<Failure, List<CustomCategory>>> getCustomCategories();
  Future<Either<Failure, Unit>> saveCustomCategory(CustomCategory category);
  Future<Either<Failure, Unit>> deleteCustomCategory(String name);

  Future<Either<Failure, List<CategoryRule>>> getCategoryRules();

  /// Reads the SMS inbox (incrementally by default, or full inbox when
  /// [fullRescan] is `true`), detects bank messages across all banks, stores
  /// both raw bank messages and parsed transactions, links internal transfers,
  /// and auto-categorizes expenses using OTP correlation + rules.
  Future<Either<Failure, SyncResult>> syncInbox({bool fullRescan = false});

  /// Emits whenever a new bank SMS arrives while the app is in foreground.
  Stream<BankSmsMessage> get incomingMessages;

  Future<bool> hasSmsPermission();
  Future<bool> requestSmsPermission();
}
