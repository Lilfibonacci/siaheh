import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/features/sms/data/parsers/internal_transfer_detector.dart';
import 'package:siaheh/features/sms/domain/entities/bank_sms_message.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/features/sms/domain/entities/sms_sender.dart';
import 'package:siaheh/features/sms/domain/repositories/sms_repository.dart';
import 'package:siaheh/presentation/bloc/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance_event.dart';
import 'package:siaheh/presentation/bloc/finance_state.dart';
import 'package:siaheh/presentation/mapper/finance_mapper.dart';

class _FakeSmsRepository implements SmsRepository {
  bool permission = true;
  final List<BankTransaction> txs = [];
  final List<BankSmsMessage> messages = [];
  final List<SmsSender> senders = [];
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
  Future<Either<Failure, Unit>> updateTransaction(BankTransaction tx) async {
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
    bloc = FinanceBloc(repo);
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
}
