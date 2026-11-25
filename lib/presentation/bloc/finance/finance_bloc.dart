import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';
import 'package:siaheh/domain/entities/sync_result.dart';
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
import 'package:siaheh/presentation/bloc/finance/finance_event.dart';
import 'package:siaheh/presentation/bloc/finance/finance_state.dart';

/// Standard event-driven BLoC managing bank SMS messages, transactions,
/// accounts, senders, custom categories, learned rules, and incremental sync.
class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  FinanceBloc({
    required this._getTransactions,
    required this._getBankMessages,
    required this._getSenders,
    required this._getCustomCategories,
    required this._getCategoryRules,
    required this._syncInbox,
    required this._saveSender,
    required this._deleteSender,
    required this._updateTransaction,
    required this._deleteTransaction,
    required this._saveCustomCategory,
    required this._deleteCustomCategory,
    required this._watchIncomingMessages,
    required this._hasSmsPermission,
    required this._requestSmsPermission,
  }) : super(const FinanceState()) {
    on<FinanceStarted>(_onStarted);
    on<FinanceAppResumed>(_onAppResumed);
    on<FinancePermissionRequested>(_onPermissionRequested);
    on<FinanceSyncRequested>(_onSyncRequested);
    on<FinanceIncomingSmsReceived>(_onIncomingSmsReceived);
    on<FinanceSenderAdded>(_onSenderAdded);
    on<FinanceSenderToggled>(_onSenderToggled);
    on<FinanceSenderDeleted>(_onSenderDeleted);
    on<FinanceTransactionUpdated>(_onTransactionUpdated);
    on<FinanceTransactionDeleted>(_onTransactionDeleted);
    on<FinanceCustomCategoryAdded>(_onCustomCategoryAdded);
    on<FinanceCustomCategoryDeleted>(_onCustomCategoryDeleted);
  }

  final GetTransactionsUseCase _getTransactions;
  final GetBankMessagesUseCase _getBankMessages;
  final GetSendersUseCase _getSenders;
  final GetCustomCategoriesUseCase _getCustomCategories;
  final GetCategoryRulesUseCase _getCategoryRules;
  final SyncInboxUseCase _syncInbox;
  final SaveSenderUseCase _saveSender;
  final DeleteSenderUseCase _deleteSender;
  final UpdateTransactionUseCase _updateTransaction;
  final DeleteTransactionUseCase _deleteTransaction;
  final SaveCustomCategoryUseCase _saveCustomCategory;
  final DeleteCustomCategoryUseCase _deleteCustomCategory;
  final WatchIncomingMessagesUseCase _watchIncomingMessages;
  final HasSmsPermissionUseCase _hasSmsPermission;
  final RequestSmsPermissionUseCase _requestSmsPermission;

  StreamSubscription<BankSmsMessage>? _incomingSub;

  Future<void> _onStarted(
    FinanceStarted event,
    Emitter<FinanceState> emit,
  ) async {
    const noParams = NoParams();
    final tx = await _getTransactions(noParams);
    final msgs = await _getBankMessages(noParams);
    final senders = await _getSenders(noParams);
    final customCats = await _getCustomCategories(noParams);
    final rules = await _getCategoryRules(noParams);
    final granted = await _hasSmsPermission(noParams);

    emit(
      state.copyWith(
        transactions: tx.getOrElse(() => state.transactions),
        bankMessages: msgs.getOrElse(() => state.bankMessages),
        senders: senders.getOrElse(() => state.senders),
        customCategories: customCats.getOrElse(() => state.customCategories),
        categoryRules: rules.getOrElse(() => state.categoryRules),
        hasPermission: granted,
        loading: false,
        syncing: granted,
      ),
    );

    if (granted) {
      await _performSync(emit, fullRescan: false, emitSyncing: false);
      _attachIncomingListener();
    }
  }

  Future<void> _onAppResumed(
    FinanceAppResumed event,
    Emitter<FinanceState> emit,
  ) async {
    final granted = await _hasSmsPermission(const NoParams());
    if (!granted) {
      if (state.hasPermission) {
        emit(state.copyWith(hasPermission: false));
      }
      return;
    }

    if (!state.hasPermission) {
      emit(state.copyWith(hasPermission: true));
    }
    _attachIncomingListener();
    await _performSync(emit, fullRescan: false);
  }

  Future<void> _onPermissionRequested(
    FinancePermissionRequested event,
    Emitter<FinanceState> emit,
  ) async {
    final granted = await _requestSmsPermission(const NoParams());
    emit(state.copyWith(hasPermission: granted));
    if (granted) {
      _attachIncomingListener();
      await _performSync(emit, fullRescan: true);
    }
  }

  Future<void> _onSyncRequested(
    FinanceSyncRequested event,
    Emitter<FinanceState> emit,
  ) async {
    if (!await _hasSmsPermission(const NoParams())) {
      emit(state.copyWith(hasPermission: false, loading: false, syncing: false));
      return;
    }
    await _performSync(emit, fullRescan: event.fullRescan);
  }

  Future<void> _onIncomingSmsReceived(
    FinanceIncomingSmsReceived event,
    Emitter<FinanceState> emit,
  ) async {
    await _reloadLocal(emit);
  }

  Future<void> _onSenderAdded(
    FinanceSenderAdded event,
    Emitter<FinanceState> emit,
  ) async {
    await _saveSender(event.sender);
    if (state.hasPermission) {
      await _performSync(emit, fullRescan: true);
    } else {
      await _reloadLocal(emit);
    }
  }

  Future<void> _onSenderToggled(
    FinanceSenderToggled event,
    Emitter<FinanceState> emit,
  ) async {
    await _saveSender(event.sender.copyWith(enabled: event.enabled));
    if (event.enabled && state.hasPermission) {
      await _performSync(emit, fullRescan: true);
    } else {
      await _reloadLocal(emit);
    }
  }

  Future<void> _onSenderDeleted(
    FinanceSenderDeleted event,
    Emitter<FinanceState> emit,
  ) async {
    await _deleteSender(event.number);
    await _reloadLocal(emit);
  }

  Future<void> _onTransactionUpdated(
    FinanceTransactionUpdated event,
    Emitter<FinanceState> emit,
  ) async {
    await _updateTransaction(
      UpdateTransactionParams(
        event.transaction,
        applyToSimilar: event.applyToSimilar,
      ),
    );
    await _reloadLocal(emit);
  }

  Future<void> _onTransactionDeleted(
    FinanceTransactionDeleted event,
    Emitter<FinanceState> emit,
  ) async {
    await _deleteTransaction(event.id);
    await _reloadLocal(emit);
  }

  Future<void> _onCustomCategoryAdded(
    FinanceCustomCategoryAdded event,
    Emitter<FinanceState> emit,
  ) async {
    await _saveCustomCategory(event.category);
    await _reloadLocal(emit);
  }

  Future<void> _onCustomCategoryDeleted(
    FinanceCustomCategoryDeleted event,
    Emitter<FinanceState> emit,
  ) async {
    await _deleteCustomCategory(event.name);
    await _reloadLocal(emit);
  }

  void _attachIncomingListener() {
    _incomingSub ??= _watchIncomingMessages(const NoParams()).listen(
      (msg) => add(FinanceIncomingSmsReceived(msg)),
    );
  }

  Future<void> _performSync(
    Emitter<FinanceState> emit, {
    required bool fullRescan,
    bool emitSyncing = true,
  }) async {
    if (emitSyncing) emit(state.copyWith(syncing: true));
    final result = await _syncInbox(SyncInboxParams(fullRescan: fullRescan));
    String? error;
    SyncResult? syncResult;
    result.fold(
      (f) => error = f.message,
      (r) => syncResult = r,
    );
    await _reloadLocal(emit, error: error, lastSyncResult: syncResult);
  }

  Future<void> _reloadLocal(
    Emitter<FinanceState> emit, {
    String? error,
    SyncResult? lastSyncResult,
  }) async {
    const noParams = NoParams();
    final tx = await _getTransactions(noParams);
    final msgs = await _getBankMessages(noParams);
    final senders = await _getSenders(noParams);
    final customCats = await _getCustomCategories(noParams);
    final rules = await _getCategoryRules(noParams);
    emit(
      state.copyWith(
        transactions: tx.getOrElse(() => state.transactions),
        bankMessages: msgs.getOrElse(() => state.bankMessages),
        senders: senders.getOrElse(() => state.senders),
        customCategories: customCats.getOrElse(() => state.customCategories),
        categoryRules: rules.getOrElse(() => state.categoryRules),
        loading: false,
        syncing: false,
        error: error,
        lastSyncResult: lastSyncResult,
      ),
    );
  }

  @override
  Future<void> close() {
    _incomingSub?.cancel();
    return super.close();
  }
}
