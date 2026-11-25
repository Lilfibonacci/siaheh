import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/entities/category_ids.dart';
import 'package:siaheh/data/parsers/internal_transfer_detector.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';
import 'package:siaheh/domain/entities/category_rule.dart';
import 'package:siaheh/domain/entities/custom_category.dart';
import 'package:siaheh/domain/entities/sms_sender.dart';
import 'package:siaheh/domain/entities/sync_result.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';
import 'package:siaheh/presentation/bloc/finance/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance/finance_event.dart';
import 'package:siaheh/presentation/bloc/finance/finance_state.dart';
import 'package:siaheh/presentation/bloc/finance/finance_mapper.dart';
import 'package:siaheh/presentation/bloc/finance/finance_ui_models.dart';

import '../../helpers/finance_bloc_test_helper.dart';

class _FakeSmsRepository implements SmsRepository {
  bool permission = true;
  final List<BankTransaction> txs = [];
  final List<BankSmsMessage> messages = [];
  final List<SmsSender> senders = [];
  final List<CustomCategory> customCategories = [];
  final List<CategoryRule> categoryRules = [];
  final StreamController<BankSmsMessage> incoming =
      StreamController<BankSmsMessage>.broadcast();

  final List<bool> syncCallsFullRescan = [];

  @override
  Future<bool> hasSmsPermission() async => permission;

  @override
  Future<bool> requestSmsPermission() async {
    permission = true;
    return true;
  }

  @override
  Stream<BankSmsMessage> get incomingMessages => incoming.stream;

  @override
  Future<Either<Failure, List<BankSmsMessage>>> getBankMessages() async =>
      Right(List.of(messages));

  @override
  Future<Either<Failure, List<SmsSender>>> getSenders() async =>
      Right(List.of(senders));

  @override
  Future<Either<Failure, List<BankTransaction>>> getTransactions() async =>
      Right(List.of(txs));

  @override
  Future<Either<Failure, List<CustomCategory>>> getCustomCategories() async =>
      Right(List.of(customCategories));

  @override
  Future<Either<Failure, Unit>> saveCustomCategory(
    CustomCategory category,
  ) async {
    customCategories.removeWhere((c) => c.name == category.name);
    customCategories.add(category);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteCustomCategory(String name) async {
    customCategories.removeWhere((c) => c.name == name);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<CategoryRule>>> getCategoryRules() async =>
      Right(List.of(categoryRules));

  @override
  Future<Either<Failure, Unit>> saveSender(SmsSender sender) async {
    senders.removeWhere((s) => s.number == sender.number);
    senders.add(sender);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteSender(String number) async {
    senders.removeWhere((s) => s.number == number);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> updateTransaction(
    BankTransaction tx, {
    bool applyToSimilar = false,
  }) async {
    final idx = txs.indexWhere((t) => t.id == tx.id);
    if (idx >= 0) txs[idx] = tx;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteTransaction(String id) async {
    txs.removeWhere((t) => t.id == id);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, SyncResult>> syncInbox({bool fullRescan = false}) async {
    syncCallsFullRescan.add(fullRescan);
    return const Right(SyncResult(newMessages: 1, newTransactions: 1));
  }

  void dispose() => incoming.close();
}

void main() {
  late _FakeSmsRepository repo;
  late FinanceBloc bloc;

  setUp(() {
    repo = _FakeSmsRepository();
    bloc = createFinanceBloc(repo);
  });

  tearDown(() async {
    await bloc.close();
    repo.dispose();
  });

  test('FinanceStarted syncs incrementally and reacts to incoming bank SMS', () async {
    bloc.add(const FinanceStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(bloc.state.hasPermission, isTrue);
    expect(bloc.state.loading, isFalse);
    expect(repo.syncCallsFullRescan, [false]);

    final liveMsg = BankSmsMessage(
      id: 'm1',
      senderAddress: 'BluBank',
      bankKey: 'blubank',
      body: 'برداشت 100,000 تومان',
      receivedAt: DateTime(2026, 10, 28),
      kind: BankSmsKind.transaction,
    );
    repo.messages.add(liveMsg);
    repo.incoming.add(liveMsg);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(bloc.state.bankMessages, [liveMsg]);
  });

  test('FinanceSenderAdded triggers full rescan and saves sender', () async {
    bloc.add(const FinanceStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    const sender = SmsSender(number: 'BluBank', bankKey: 'blubank');
    bloc.add(const FinanceSenderAdded(sender));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(bloc.state.senders, [sender]);
    expect(repo.syncCallsFullRescan, [false, true]);
  });

  test('FinanceAppResumed runs incremental sync', () async {
    bloc.add(const FinanceAppResumed());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(repo.syncCallsFullRescan, [false]);
  });

  test('FinanceTransactionDeleted removes transaction from state', () async {
    final tx = BankTransaction(
      id: 'tx1',
      bankKey: 'melli',
      accountNumber: '12345678',
      senderNumber: '99991000',
      amountRial: 500000,
      type: TransactionType.expense,
      occurredAt: DateTime(2026, 10, 28),
      rawBody: '-500,000',
    );
    repo.txs.add(tx);

    bloc.add(const FinanceStarted());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.transactions.length, 1);

    bloc.add(const FinanceTransactionDeleted('tx1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.transactions, isEmpty);
  });

  test('FinanceMapper and InternalTransferDetector handle thousands of records fast (no ANR)', () {
    final now = DateTime.now();
    final txs = List.generate(
      3000,
      (i) => BankTransaction(
        id: 'tx_$i',
        bankKey: i.isEven ? 'melli' : 'blubank',
        accountNumber: i.isEven ? '0304546764008' : 'اصلی',
        senderNumber: i.isEven ? '99991000' : 'BluBank',
        amountRial: 100000 + (i * 100),
        type: i % 3 == 0 ? TransactionType.income : TransactionType.expense,
        occurredAt: now.subtract(Duration(hours: i)),
        rawBody: 'sample $i',
        balanceRial: 50000000 - i * 1000,
      ),
    );
    final msgs = List.generate(
      5000,
      (i) => BankSmsMessage(
        id: 'm_$i',
        senderAddress: i.isEven ? '+9899991000' : 'BluBank',
        bankKey: i.isEven ? 'melli' : 'blubank',
        body: 'sample sms $i',
        receivedAt: now.subtract(Duration(hours: i)),
        kind: i < 3000 ? BankSmsKind.transaction : BankSmsKind.info,
        transactionId: i < 3000 ? 'tx_$i' : null,
      ),
    );
    const senders = [
      SmsSender(number: '99991000', bankKey: 'melli', enabled: true),
      SmsSender(number: 'BluBank', bankKey: 'blubank', enabled: true),
      SmsSender(number: '30007100', bankKey: 'mellat', enabled: false),
    ];

    final sw = Stopwatch()..start();
    final mapper = FinanceMapper(
      FinanceState(
        transactions: txs,
        bankMessages: msgs,
        senders: senders,
        hasPermission: true,
        loading: false,
      ),
    );
    expect(mapper.accounts.length, 2);
    expect(mapper.recentTransactions(5).length, 5);
    expect(mapper.detectedBanks.length, 2);
    expect(mapper.senders.length, 3);
    expect(mapper.transactionUiById('tx_42')?.id, 'tx_42');
    expect(mapper.monthExpense, greaterThan(0));
    const InternalTransferDetector().detectChanges(txs);
    sw.stop();

    expect(
      sw.elapsedMilliseconds,
      lessThan(500),
      reason: 'Mapper + transfer detection took ${sw.elapsedMilliseconds}ms',
    );
  });

  test('FinanceMapper merges fallback اصلی transactions into bank numbered account', () {
    final now = DateTime.now();
    final mapper = FinanceMapper(
      FinanceState(
        transactions: [
          BankTransaction(
            id: 'r1',
            bankKey: 'refah',
            accountNumber: 'اصلی',
            senderNumber: '20008525',
            amountRial: 50000,
            type: TransactionType.expense,
            occurredAt: now,
            rawBody: 'کسر کارمزد',
          ),
          BankTransaction(
            id: 'r2',
            bankKey: 'refah',
            accountNumber: '1234565294',
            senderNumber: '20008525',
            amountRial: 200000,
            type: TransactionType.expense,
            occurredAt: now.subtract(const Duration(hours: 1)),
            rawBody: 'برداشت از حساب 1234565294 مانده 104460',
            balanceRial: 104460,
          ),
          BankTransaction(
            id: 'b1',
            bankKey: 'blubank',
            accountNumber: 'اصلی',
            senderNumber: 'BluBank',
            amountRial: 100000,
            type: TransactionType.expense,
            occurredAt: now,
            rawBody: 'برداشت از بلو',
            balanceRial: 5000000,
          ),
        ],
      ),
    );

    // Refah should appear ONCE (merged into 5294, no duplicate 0-balance اصلی),
    // while BluBank (which never has account numbers) still shows its اصلی card.
    expect(mapper.accounts.length, 2);
    final refah = mapper.accounts.firstWhere((a) => a.bank.key == 'refah');
    expect(refah.last4, '5294');
    expect(refah.balanceRial, 104460);

    final blu = mapper.accounts.firstWhere((a) => a.bank.key == 'blubank');
    expect(blu.last4, 'اصلی');
    expect(blu.balanceRial, 5000000);
  });

  test('FinanceBloc adds custom category and FinanceMapper computes sorted expenseBreakdown', () async {
    const customCat = CustomCategory(
      name: 'کافه و دورهمی',
      iconCodePoint: 0xe191,
      colorValue: 0xFF14B8A6,
    );
    bloc.add(const FinanceCustomCategoryAdded(customCat));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.customCategories, [customCat]);

    final now = DateTime.now();
    final mapper = FinanceMapper(
      FinanceState(
        customCategories: const [customCat],
        transactions: [
          BankTransaction(
            id: '1',
            bankKey: 'blubank',
            accountNumber: 'اصلی',
            senderNumber: 'BluBank',
            amountRial: 3000000,
            type: TransactionType.expense,
            occurredAt: now,
            rawBody: 'اسنپ',
            categoryId: CategoryIds.transport,
          ),
          BankTransaction(
            id: '2',
            bankKey: 'blubank',
            accountNumber: 'اصلی',
            senderNumber: 'BluBank',
            amountRial: 1000000,
            type: TransactionType.expense,
            occurredAt: now,
            rawBody: 'ایرانسل',
            categoryId: CategoryIds.internet,
          ),
          BankTransaction(
            id: '3',
            bankKey: 'blubank',
            accountNumber: 'اصلی',
            senderNumber: 'BluBank',
            amountRial: 1000000,
            type: TransactionType.expense,
            occurredAt: now,
            rawBody: 'کافه',
            categoryId: 'کافه و دورهمی',
          ),
        ],
      ),
    );

    final slices = mapper.expenseBreakdown(JalaliDateFilter.thisMonth(now));
    expect(slices.length, 3);
    expect(slices.first.category.name, CategoryIds.transport);
    expect(slices.first.percentage, closeTo(60.0, 0.1));
    expect(slices.any((s) => s.category.name == 'کافه و دورهمی'), isTrue);
  });

  test('JalaliDateFilter supports custom month, whole year, and year wrap-around', () {
    final farvardin1404 = Jalali(1404, 1, 15).toDateTime();
    final mehr1404 = Jalali(1404, 7, 10).toDateTime();
    final esfand1403 = Jalali(1403, 12, 20).toDateTime();

    const filterMehr1404 = JalaliDateFilter.month(year: 1404, month: 7);
    expect(filterMehr1404.matches(mehr1404), isTrue);
    expect(filterMehr1404.matches(farvardin1404), isFalse);
    expect(filterMehr1404.matches(esfand1403), isFalse);

    const filterYear1404 = JalaliDateFilter.year(1404);
    expect(filterYear1404.matches(farvardin1404), isTrue);
    expect(filterYear1404.matches(mehr1404), isTrue);
    expect(filterYear1404.matches(esfand1403), isFalse);

    // Month wrap-around across Jalali year boundary
    const farvardinFilter = JalaliDateFilter.month(year: 1404, month: 1);
    expect(
      farvardinFilter.previousMonth(),
      const JalaliDateFilter.month(year: 1403, month: 12),
    );
    expect(
      const JalaliDateFilter.month(year: 1403, month: 12).nextMonth(),
      farvardinFilter,
    );

    final mapper = FinanceMapper(
      FinanceState(
        transactions: [
          BankTransaction(
            id: 'old',
            bankKey: 'blubank',
            accountNumber: '1234',
            senderNumber: 'BluBank',
            amountRial: 500000,
            type: TransactionType.expense,
            occurredAt: mehr1404,
            rawBody: 'اسنپ',
            categoryId: CategoryIds.transport,
          ),
          BankTransaction(
            id: 'other',
            bankKey: 'blubank',
            accountNumber: '1234',
            senderNumber: 'BluBank',
            amountRial: 900000,
            type: TransactionType.expense,
            occurredAt: esfand1403,
            rawBody: 'ایرانسل',
            categoryId: CategoryIds.internet,
          ),
        ],
      ),
    );

    final mehrSlices = mapper.expenseBreakdown(filterMehr1404);
    expect(mehrSlices.length, 1);
    expect(mehrSlices.first.category.name, CategoryIds.transport);
    expect(mehrSlices.first.amountRial, 500000);
    expect(mapper.expenseCountsByYearMonth[1404]?[7], 1);
    expect(mapper.expenseCountsByYearMonth[1403]?[12], 1);
  });
}
