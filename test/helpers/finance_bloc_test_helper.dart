import 'package:siaheh/domain/repositories/sms_repository.dart';
import 'package:siaheh/domain/usecases/finance/delete_custom_category_usecase.dart';
import 'package:siaheh/domain/usecases/finance/delete_sender_usecase.dart';
import 'package:siaheh/domain/usecases/finance/delete_transaction_usecase.dart';
import 'package:siaheh/domain/usecases/finance/get_bank_messages_usecase.dart';
import 'package:siaheh/domain/usecases/finance/get_category_rules_usecase.dart';
import 'package:siaheh/domain/usecases/finance/get_custom_categories_usecase.dart';
import 'package:siaheh/domain/usecases/finance/get_senders_usecase.dart';
import 'package:siaheh/domain/usecases/finance/get_transactions_usecase.dart';
import 'package:siaheh/domain/usecases/finance/has_sms_permission_usecase.dart';
import 'package:siaheh/domain/usecases/finance/request_sms_permission_usecase.dart';
import 'package:siaheh/domain/usecases/finance/save_custom_category_usecase.dart';
import 'package:siaheh/domain/usecases/finance/save_sender_usecase.dart';
import 'package:siaheh/domain/usecases/finance/sync_inbox_usecase.dart';
import 'package:siaheh/domain/usecases/finance/update_transaction_usecase.dart';
import 'package:siaheh/domain/usecases/finance/watch_incoming_messages_usecase.dart';
import 'package:siaheh/presentation/bloc/finance/finance_bloc.dart';

/// Builds a real [FinanceBloc] wired to all 15 domain use cases backed by [repo].
FinanceBloc createFinanceBloc(SmsRepository repo) => FinanceBloc(
  getTransactions: GetTransactionsUseCase(repo),
  getBankMessages: GetBankMessagesUseCase(repo),
  getSenders: GetSendersUseCase(repo),
  getCustomCategories: GetCustomCategoriesUseCase(repo),
  getCategoryRules: GetCategoryRulesUseCase(repo),
  syncInbox: SyncInboxUseCase(repo),
  saveSender: SaveSenderUseCase(repo),
  deleteSender: DeleteSenderUseCase(repo),
  updateTransaction: UpdateTransactionUseCase(repo),
  deleteTransaction: DeleteTransactionUseCase(repo),
  saveCustomCategory: SaveCustomCategoryUseCase(repo),
  deleteCustomCategory: DeleteCustomCategoryUseCase(repo),
  watchIncomingMessages: WatchIncomingMessagesUseCase(repo),
  hasSmsPermission: HasSmsPermissionUseCase(repo),
  requestSmsPermission: RequestSmsPermissionUseCase(repo),
);
