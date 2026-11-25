import 'package:siaheh/data/dtos/bank_sms_message_dto.dart';
import 'package:siaheh/data/dtos/bank_transaction_dto.dart';
import 'package:siaheh/data/dtos/category_rule_dto.dart';
import 'package:siaheh/data/dtos/custom_category_dto.dart';
import 'package:siaheh/data/dtos/sms_sender_dto.dart';

/// Contract for local persistence of parsed transactions, bank SMS messages,
/// tracked senders, custom categories, learned rules, and sync metadata.
abstract interface class SmsLocalDataSource {
  List<BankTransactionDto> transactions();
  bool hasTransaction(String id);
  Future<void> putTransaction(BankTransactionDto tx);
  Future<void> putTransactions(Iterable<BankTransactionDto> items);
  Future<void> deleteTransaction(String id);

  List<BankSmsMessageDto> bankMessages();
  bool hasBankMessage(String id);
  Future<void> putBankMessage(BankSmsMessageDto message);
  Future<void> putBankMessages(Iterable<BankSmsMessageDto> items);

  List<SmsSenderDto> senders();
  Future<void> putSender(SmsSenderDto sender);
  Future<void> putSenders(Iterable<SmsSenderDto> items);
  Future<void> deleteSender(String number);

  List<CustomCategoryDto> customCategories();
  Future<void> putCustomCategory(CustomCategoryDto category);
  Future<void> deleteCustomCategory(String name);

  List<CategoryRuleDto> categoryRules();
  Future<void> putCategoryRule(CategoryRuleDto rule);
  Future<void> deleteCategoryRule(String pattern);

  DateTime? lastSyncedAt();
  Future<void> setLastSyncedAt(DateTime timestamp);
  Future<void> clearLastSyncedAt();

  int detectorVersion();
  Future<void> setDetectorVersion(int version);

  int categorizerVersion();
  Future<void> setCategorizerVersion(int version);

  Future<void> purgeAutoDetectedData();

  Future<void> deleteMessagesAndAutoTransactionsMatching(
    bool Function(String address) matchesAddress,
  );
}
