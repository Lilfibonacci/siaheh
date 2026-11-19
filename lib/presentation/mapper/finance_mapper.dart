import 'package:shamsi_date/shamsi_date.dart';
import 'package:siaheh/core/utils/persian_format.dart';
import 'package:siaheh/features/sms/data/parsers/generic_sms_parser.dart';
import 'package:siaheh/features/sms/domain/entities/bank_sms_message.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/features/sms/domain/entities/iranian_bank_registry.dart';
import 'package:siaheh/features/sms/domain/entities/sms_sender.dart';
import 'package:siaheh/presentation/bloc/finance_state.dart';
import 'package:siaheh/presentation/models/finance_ui_models.dart';

/// O(N)-indexed mapper from [FinanceState] into presentation view models.
///
/// Automatically hides items belonging to user-disabled senders and caches
/// derived lookups (`_accountsByKey`, `_txById`, `_messageCountsByBankKey`) so
/// widgets never perform quadratic scans during build.
class FinanceMapper {
  FinanceMapper(this.state);

  final FinanceState state;

  late final DateTime _now = DateTime.now();
  late final DateTime _dayStart = DateTime(_now.year, _now.month, _now.day);
  late final Jalali _nowJalali = Jalali.fromDateTime(_now);

  static UiBank bank(String key) {
    final info = IranianBankRegistry.byKey(key);
    return UiBank(key: info.key, name: info.name);
  }

  static UiCategory categoryOf(String? id) => AppCategories.byName(id);

  String get currentJalaliMonthLabel =>
      PersianFormat.digits('${_nowJalali.formatter.mN} ${_nowJalali.year}');

  late final List<SmsSender> _disabledSenders = state.senders
      .where((s) => !s.enabled)
      .toList(growable: false);

  /// Active (non-disabled) domain transactions, newest first.
  late final List<BankTransaction> activeTransactions = () {
    final disabled = _disabledSenders;
    if (disabled.isEmpty) return state.transactions;
    return state.transactions
        .where((t) => !disabled.any((s) => s.matchesAddress(t.senderNumber)))
        .toList(growable: false);
  }();

  /// Active (non-disabled) domain bank SMS messages, newest first.
  late final List<BankSmsMessage> activeBankMessages = () {
    final disabled = _disabledSenders;
    if (disabled.isEmpty) return state.bankMessages;
    return state.bankMessages
        .where((m) => !disabled.any((s) => s.matchesAddress(m.senderAddress)))
        .toList(growable: false);
  }();

  String resolveBankKey(BankTransaction tx) {
    if (tx.bankKey != IranianBankRegistry.unknownKey && tx.bankKey.isNotEmpty) {
      return tx.bankKey;
    }
    for (final s in state.senders) {
      if (s.matchesAddress(tx.senderNumber)) return s.bankKey;
    }
    return IranianBankRegistry.unknownKey;
  }

  /// Primary numbered account key per bank (newest first), used to fold
  /// fallback `'اصلی'` transactions into the bank's real account instead of
  /// showing a duplicate zero-balance `حساب اصلی` card.
  late final Map<String, String> _primaryNumberedAccountKeyByBank = () {
    final map = <String, String>{};
    for (final t in activeTransactions) {
      if (t.accountNumber == GenericSmsParser.defaultAccountLabel) continue;
      final bKey = resolveBankKey(t);
      map.putIfAbsent(bKey, () => t.accountKey);
    }
    return map;
  }();

  String _canonicalAccountKey(BankTransaction t) {
    if (t.accountNumber == GenericSmsParser.defaultAccountLabel) {
      final primary = _primaryNumberedAccountKeyByBank[resolveBankKey(t)];
      if (primary != null) return primary;
    }
    return t.accountKey;
  }

  /// Single O(N) pass building all accounts keyed by canonical account key.
  late final Map<String, UiAccount> _accountsByKey = () {
    final latestByKey = <String, BankTransaction>{};
    final balanceByKey = <String, int>{};

    for (final t in activeTransactions) {
      final k = _canonicalAccountKey(t);
      // Prefer a real numbered transaction as the representative for display suffix.
      final existing = latestByKey[k];
      if (existing == null ||
          (existing.accountNumber == GenericSmsParser.defaultAccountLabel &&
              t.accountNumber != GenericSmsParser.defaultAccountLabel)) {
        latestByKey[k] = t;
      }
      if (t.balanceRial != null && !balanceByKey.containsKey(k)) {
        balanceByKey[k] = t.balanceRial!;
      }
    }

    return {
      for (final e in latestByKey.entries)
        e.key: UiAccount(
          accountKey: e.key,
          bank: bank(resolveBankKey(e.value)),
          last4: e.value.accountDisplaySuffix,
          balanceRial: balanceByKey[e.key] ?? 0,
        ),
    };
  }();

  /// O(1) transaction lookup map for linking bank messages to transactions.
  late final Map<String, BankTransaction> _txById = {
    for (final t in activeTransactions) t.id: t,
  };

  /// Single O(M) pass counting active messages per bank key.
  late final Map<String, int> _messageCountsByBankKey = () {
    final counts = <String, int>{};
    for (final m in activeBankMessages) {
      counts[m.bankKey] = (counts[m.bankKey] ?? 0) + 1;
    }
    return counts;
  }();

  int messageCountForBank(String bankKey) =>
      _messageCountsByBankKey[bankKey] ?? 0;

  /// O(1) lookup returning the [UiTransaction] for [id], or `null`.
  UiTransaction? transactionUiById(String? id) {
    if (id == null) return null;
    final tx = _txById[id];
    return tx == null ? null : toUi(tx);
  }

  /// All distinct accounts across all banks, keyed by `(bankKey, accountNumber)`.
  late final List<UiAccount> accounts =
      _accountsByKey.values.toList(growable: false);

  /// Distinct banks that appear in the user's detected bank SMS messages.
  late final List<UiBank> detectedBanks = () {
    final keys = <String>{
      ..._messageCountsByBankKey.keys,
      for (final a in accounts) a.bank.key,
    };
    return keys.map(bank).toList()..sort((a, b) => a.name.compareTo(b.name));
  }();

  /// Converts only the first [limit] transactions (fast path for HomeTab).
  List<UiTransaction> recentTransactions(int limit) =>
      activeTransactions.take(limit).map(toUi).toList(growable: false);

  late final List<UiTransaction> transactions =
      activeTransactions.map(toUi).toList(growable: false);

  UiAccount _accountForTx(BankTransaction t) {
    final key = _canonicalAccountKey(t);
    return _accountsByKey[key] ??
        UiAccount(
          accountKey: key,
          bank: bank(resolveBankKey(t)),
          last4: t.accountDisplaySuffix,
          balanceRial: t.balanceRial ?? 0,
        );
  }

  UiTransaction toUi(BankTransaction t) {
    final (dateLabel, timeLabel) = _formatDateTime(t.occurredAt);
    final defaultTitle = switch (t.type) {
      TransactionType.income => 'واریز به حساب',
      TransactionType.expense => 'برداشت از حساب',
      TransactionType.transfer => 'انتقال بین حساب‌ها',
    };
    return UiTransaction(
      id: t.id,
      title: t.title ?? defaultTitle,
      amountRial: t.amountRial,
      type: switch (t.type) {
        TransactionType.income => UiTxType.income,
        TransactionType.expense => UiTxType.expense,
        TransactionType.transfer => UiTxType.transfer,
      },
      category: t.categoryId != null
          ? categoryOf(t.categoryId)
          : (t.type == TransactionType.transfer
              ? AppCategories.transfer
              : AppCategories.other),
      account: _accountForTx(t),
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      rawBody: t.rawBody,
      needsReview: t.needsReview,
      isAutoTransfer: t.linkedTransferId != null,
    );
  }

  late final List<UiBankMessage> bankMessages =
      activeBankMessages.map(toUiMessage).toList(growable: false);

  UiBankMessage toUiMessage(BankSmsMessage m) {
    final (dateLabel, timeLabel) = _formatDateTime(m.receivedAt);
    return UiBankMessage(
      id: m.id,
      bank: bank(m.bankKey),
      senderAddress: m.senderAddress,
      body: m.body,
      kind: m.kind,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      transactionId: m.transactionId,
    );
  }

  late final List<BankTransaction> _thisMonth = () {
    // Only transactions within the last ~35 days can belong to the current
    // Jalali month, avoiding Jalali conversion on years of older transactions.
    final cutoff = _now.subtract(const Duration(days: 35));
    final list = <BankTransaction>[];
    for (final t in activeTransactions) {
      if (t.occurredAt.isBefore(cutoff)) continue;
      final j = Jalali.fromDateTime(t.occurredAt);
      if (j.year == _nowJalali.year && j.month == _nowJalali.month) {
        list.add(t);
      }
    }
    return list;
  }();

  /// Monthly income excluding internal transfers.
  late final int monthIncome = _thisMonth
      .where((t) => t.type == TransactionType.income)
      .fold(0, (s, t) => s + t.amountRial);

  /// Monthly expense excluding internal transfers.
  late final int monthExpense = _thisMonth
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (s, t) => s + t.amountRial);

  late final Map<UiCategory, int> expenseByCategory = () {
    final map = <UiCategory, int>{};
    for (final t in _thisMonth) {
      if (t.type != TransactionType.expense) continue;
      map.update(
        categoryOf(t.categoryId),
        (v) => v + t.amountRial,
        ifAbsent: () => t.amountRial,
      );
    }
    return map;
  }();

  late final List<UiSender> senders = () {
    // Count messages by canonical sender address in one O(M) pass.
    final countsByCanonical = <String, int>{};
    for (final m in state.bankMessages) {
      final canonical = SmsSender.canonicalAddress(m.senderAddress);
      countsByCanonical[canonical] = (countsByCanonical[canonical] ?? 0) + 1;
    }

    return state.senders.map((SmsSender s) {
      final canonical = SmsSender.canonicalAddress(s.number);
      return UiSender(
        number: s.number,
        bank: bank(s.bankKey),
        enabled: s.enabled,
        autoDetected: s.autoDetected,
        messageCount: countsByCanonical[canonical] ?? 0,
      );
    }).toList(growable: false);
  }();

  (String dateLabel, String timeLabel) _formatDateTime(DateTime dt) {
    final txDay = DateTime(dt.year, dt.month, dt.day);
    final diff = _dayStart.difference(txDay).inDays;
    final String dateLabel;
    if (diff == 0) {
      dateLabel = 'امروز';
    } else if (diff == 1) {
      dateLabel = 'دیروز';
    } else {
      final j = Jalali.fromDateTime(dt);
      dateLabel = '${j.day} ${j.formatter.mN}';
    }
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return (PersianFormat.digits(dateLabel), PersianFormat.digits('$hh:$mm'));
  }
}
