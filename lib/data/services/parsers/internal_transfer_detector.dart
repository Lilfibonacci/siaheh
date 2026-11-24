import 'package:siaheh/domain/models/bank_transaction.dart';
import 'package:siaheh/domain/models/iranian_bank_registry.dart';

/// Detects internal transfers (کارت‌به‌کارت / انتقال بین حساب‌های خود کاربر)
/// across multiple accounts or banks so they don't inflate monthly income and
/// expense totals.
class InternalTransferDetector {
  const InternalTransferDetector({
    this.maxTimeWindow = const Duration(minutes: 10),
    this.maxFeeRial = 150000, // up to 15,000 Toman (covers Shaparak / Paya / Satna fees)
  });

  final Duration maxTimeWindow;
  final int maxFeeRial;

  /// Returns only the transactions whose state changed (marked as
  /// [TransactionType.transfer] with [BankTransaction.linkedTransferId]).
  ///
  /// Uses a sorted two-pointer time window for O(N log N) performance even on
  /// thousands of transactions. Transactions with `userEdited == true` or
  /// already linked are untouched.
  List<BankTransaction> detectChanges(List<BankTransaction> allTransactions) {
    final expenses = allTransactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              !t.userEdited &&
              t.linkedTransferId == null,
        )
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    final incomes = allTransactions
        .where(
          (t) =>
              t.type == TransactionType.income &&
              !t.userEdited &&
              t.linkedTransferId == null,
        )
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    if (expenses.isEmpty || incomes.isEmpty) return const [];

    final windowMs = maxTimeWindow.inMilliseconds;
    final usedIncomeIds = <String>{};
    final updated = <BankTransaction>[];
    var left = 0;

    for (final outTx in expenses) {
      final outMs = outTx.occurredAt.millisecondsSinceEpoch;
      while (left < incomes.length &&
          incomes[left].occurredAt.millisecondsSinceEpoch < outMs - windowMs) {
        left++;
      }

      BankTransaction? bestMatch;
      var bestDeltaMs = windowMs + 1;

      for (var i = left; i < incomes.length; i++) {
        final inTx = incomes[i];
        final inMs = inTx.occurredAt.millisecondsSinceEpoch;
        if (inMs > outMs + windowMs) break;

        if (usedIncomeIds.contains(inTx.id)) continue;
        // Must be two distinct accounts (different bank or different account number).
        if (outTx.accountKey == inTx.accountKey) continue;

        final diffMs = (outMs - inMs).abs();
        if (!_amountsMatchWithFee(outTx.amountRial, inTx.amountRial)) continue;

        if (diffMs < bestDeltaMs) {
          bestDeltaMs = diffMs;
          bestMatch = inTx;
        }
      }

      if (bestMatch != null) {
        usedIncomeIds.add(bestMatch.id);
        final destBank = IranianBankRegistry.byKey(bestMatch.bankKey).name;
        final srcBank = IranianBankRegistry.byKey(outTx.bankKey).name;

        updated.add(
          outTx.copyWith(
            type: TransactionType.transfer,
            linkedTransferId: bestMatch.id,
            title: outTx.title ?? 'انتقال به $destBank',
            categoryId: outTx.categoryId ?? 'انتقال',
            needsReview: false,
          ),
        );
        updated.add(
          bestMatch.copyWith(
            type: TransactionType.transfer,
            linkedTransferId: outTx.id,
            title: bestMatch.title ?? 'انتقال از $srcBank',
            categoryId: bestMatch.categoryId ?? 'انتقال',
            needsReview: false,
          ),
        );
      }
    }

    return updated;
  }

  bool _amountsMatchWithFee(int outgoingRial, int incomingRial) {
    if (outgoingRial == incomingRial) return true;
    // Outgoing may include a transfer fee (outgoing >= incoming).
    final diff = outgoingRial - incomingRial;
    if (diff < 0 || diff > maxFeeRial) return false;
    // Also ensure the fee is not a huge fraction of a tiny transaction.
    return diff <= (incomingRial * 0.05).round();
  }
}
