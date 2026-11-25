import 'package:flutter_test/flutter_test.dart';
import 'package:siaheh/data/parsers/internal_transfer_detector.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';

void main() {
  const detector = InternalTransferDetector();
  final baseTime = DateTime(2026, 10, 28, 14, 0);

  BankTransaction makeTx({
    required String id,
    required String bankKey,
    required String account,
    required int amountRial,
    required TransactionType type,
    required DateTime at,
    bool userEdited = false,
  }) => BankTransaction(
    id: id,
    bankKey: bankKey,
    accountNumber: account,
    senderNumber: bankKey,
    amountRial: amountRial,
    type: type,
    occurredAt: at,
    rawBody: 'sample',
    userEdited: userEdited,
  );

  test('detects exact-amount transfer between two different banks', () {
    final outTx = makeTx(
      id: 'tx1',
      bankKey: 'melli',
      account: '11112222',
      amountRial: 50000000,
      type: TransactionType.expense,
      at: baseTime,
    );
    final inTx = makeTx(
      id: 'tx2',
      bankKey: 'blubank',
      account: 'اصلی',
      amountRial: 50000000,
      type: TransactionType.income,
      at: baseTime.add(const Duration(minutes: 2)),
    );

    final changes = detector.detectChanges([outTx, inTx]);
    expect(changes.length, 2);
    expect(changes.every((t) => t.type == TransactionType.transfer), isTrue);
    expect(changes.firstWhere((t) => t.id == 'tx1').linkedTransferId, 'tx2');
    expect(changes.firstWhere((t) => t.id == 'tx2').linkedTransferId, 'tx1');
  });

  test('detects card-to-card transfer including Shaparak fee', () {
    final outTx = makeTx(
      id: 'tx1',
      bankKey: 'mellat',
      account: '12345678',
      amountRial: 10007200, // 1,000,000 Toman + 720 Toman fee
      type: TransactionType.expense,
      at: baseTime,
    );
    final inTx = makeTx(
      id: 'tx2',
      bankKey: 'saman',
      account: '87654321',
      amountRial: 10000000,
      type: TransactionType.income,
      at: baseTime.add(const Duration(seconds: 40)),
    );

    final changes = detector.detectChanges([outTx, inTx]);
    expect(changes.length, 2);
  });

  test('does not link transactions from the same account or outside time window', () {
    final sameAccOut = makeTx(
      id: 'tx1',
      bankKey: 'melli',
      account: '11112222',
      amountRial: 1000000,
      type: TransactionType.expense,
      at: baseTime,
    );
    final sameAccIn = makeTx(
      id: 'tx2',
      bankKey: 'melli',
      account: '11112222',
      amountRial: 1000000,
      type: TransactionType.income,
      at: baseTime.add(const Duration(minutes: 1)),
    );
    expect(detector.detectChanges([sameAccOut, sameAccIn]), isEmpty);

    final lateIn = makeTx(
      id: 'tx3',
      bankKey: 'blubank',
      account: 'اصلی',
      amountRial: 1000000,
      type: TransactionType.income,
      at: baseTime.add(const Duration(minutes: 25)),
    );
    expect(detector.detectChanges([sameAccOut, lateIn]), isEmpty);
  });

  test('respects userEdited flag', () {
    final outTx = makeTx(
      id: 'tx1',
      bankKey: 'melli',
      account: '11112222',
      amountRial: 2000000,
      type: TransactionType.expense,
      at: baseTime,
      userEdited: true,
    );
    final inTx = makeTx(
      id: 'tx2',
      bankKey: 'blubank',
      account: 'اصلی',
      amountRial: 2000000,
      type: TransactionType.income,
      at: baseTime.add(const Duration(minutes: 1)),
    );
    expect(detector.detectChanges([outTx, inTx]), isEmpty);
  });
}
