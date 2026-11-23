import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaheh/features/sms/domain/entities/bank_sms_message.dart';
import 'package:siaheh/features/sms/domain/repositories/sms_repository.dart';
import 'package:siaheh/presentation/bloc/finance_event.dart';
import 'package:siaheh/presentation/bloc/finance_state.dart';

/// Standard event-driven BLoC managing bank SMS messages, transactions,
/// accounts, senders, custom categories, learned rules, and incremental sync.
class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  FinanceBloc(this._repo) : super(const FinanceState()) {
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

  final SmsRepository _repo;
  StreamSubscription<BankSmsMessage>? _incomingSub;

  Future<void> _onStarted(
    FinanceStarted event,
    Emitter<FinanceState> emit,
  ) async {
    final tx = await _repo.getTransactions();
    final msgs = await _repo.getBankMessages();
    final senders = await _repo.getSenders();
    final customCats = await _repo.getCustomCategories();
    final rules = await _repo.getCategoryRules();
    final granted = await _repo.hasSmsPermission();

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
    final granted = await _repo.hasSmsPermission();
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
    final granted = await _repo.requestSmsPermission();
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
    if (!await _repo.hasSmsPermission()) {
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
    await _repo.saveSender(event.sender);
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
    await _repo.saveSender(event.sender.copyWith(enabled: event.enabled));
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
    await _repo.deleteSender(event.number);
    await _reloadLocal(emit);
  }

  Future<void> _onTransactionUpdated(
    FinanceTransactionUpdated event,
    Emitter<FinanceState> emit,
  ) async {
    await _repo.updateTransaction(
      event.transaction,
      applyToSimilar: event.applyToSimilar,
    );
    await _reloadLocal(emit);
  }

  Future<void> _onTransactionDeleted(
    FinanceTransactionDeleted event,
    Emitter<FinanceState> emit,
  ) async {
    await _repo.deleteTransaction(event.id);
    await _reloadLocal(emit);
  }

  Future<void> _onCustomCategoryAdded(
    FinanceCustomCategoryAdded event,
    Emitter<FinanceState> emit,
  ) async {
    await _repo.saveCustomCategory(event.category);
    await _reloadLocal(emit);
  }

  Future<void> _onCustomCategoryDeleted(
    FinanceCustomCategoryDeleted event,
    Emitter<FinanceState> emit,
  ) async {
    await _repo.deleteCustomCategory(event.name);
    await _reloadLocal(emit);
  }

  void _attachIncomingListener() {
    _incomingSub ??= _repo.incomingMessages.listen(
      (msg) => add(FinanceIncomingSmsReceived(msg)),
    );
  }

  Future<void> _performSync(
    Emitter<FinanceState> emit, {
    required bool fullRescan,
    bool emitSyncing = true,
  }) async {
    if (emitSyncing) emit(state.copyWith(syncing: true));
    final result = await _repo.syncInbox(fullRescan: fullRescan);
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
    final tx = await _repo.getTransactions();
    final msgs = await _repo.getBankMessages();
    final senders = await _repo.getSenders();
    final customCats = await _repo.getCustomCategories();
    final rules = await _repo.getCategoryRules();
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
