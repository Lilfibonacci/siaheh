import 'package:shamsi_date/shamsi_date.dart';
import 'package:siaheh/domain/models/bank_sms_message.dart';
import 'package:siaheh/domain/models/bank_transaction.dart';
import 'package:siaheh/domain/models/iranian_bank_registry.dart';
import 'package:siaheh/domain/models/sms_sender.dart';
import 'package:siaheh/ui/core/bloc/finance_state.dart';
import 'package:siaheh/ui/core/models/finance_ui_models.dart';
import 'package:siaheh/ui/core/utils/persian_format.dart';

/// O(N)-indexed mapper from [FinanceState] into presentation view models.
///
/// Automatically hides items belonging to user-disabled senders, folds
/// fallback `'اصلی'` accounts into a bank's real numbered account, merges
/// user custom categories, and caches derived lookups so widgets never perform
/// quadratic scans during build.
class FinanceMapper {
  FinanceMapper(this.state);

  static final Expando<FinanceMapper> _cache = Expando<FinanceMapper>();

  /// Returns a cached [FinanceMapper] for an immutable [FinanceState] instance
  /// so tab switches, search typing, filter taps, and chart interactions never
  /// recompute O(N) aggregations from scratch.
  static FinanceMapper of(FinanceState state) =>
      _cache[state] ??= FinanceMapper(state);

  final FinanceState state;
  final Map<JalaliDateFilter, List<CategoryExpenseSlice>> _breakdownCache = {};

  late final DateTime _now = DateTime.now();
  late final DateTime _dayStart = DateTime(_now.year, _now.month, _now.day);
  late final Jalali _nowJalali = Jalali.fromDateTime(_now);

  static UiBank bank(String key) {
    final info = IranianBankRegistry.byKey(key);
    return UiBank(key: info.key, name: info.name);
  }

  /// Built-in + user-created custom categories.
  late final List<UiCategory> allCategories =
      AppCategories.mergeWithCustom(state.customCategories);

  UiCategory categoryOf(String? id) =>
      AppCategories.byName(id, custom: state.customCategories);

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
      if (t.accountNumber == BankTransaction.defaultAccountLabel) continue;
      final bKey = resolveBankKey(t);
      map.putIfAbsent(bKey, () => t.accountKey);
    }
    return map;
  }();

  String _canonicalAccountKey(BankTransaction t) {
    if (t.accountNumber == BankTransaction.defaultAccountLabel) {
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
      final existing = latestByKey[k];
      if (existing == null ||
          (existing.accountNumber == BankTransaction.defaultAccountLabel &&
              t.accountNumber != BankTransaction.defaultAccountLabel)) {
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

  /// All distinct accounts across all banks, keyed by canonical account key.
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
      merchantName: t.merchantName,
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

  List<BankTransaction> transactionsInFilter(JalaliDateFilter filter) {
    if (!filter.isActive) return activeTransactions;
    final (start, end) = filter.bounds(now: _now);
    final list = <BankTransaction>[];
    for (final t in activeTransactions) {
      if (start != null && t.occurredAt.isBefore(start)) continue;
      if (end != null && !t.occurredAt.isBefore(end)) continue;
      list.add(t);
    }
    return list;
  }

  /// Counts of active expense transactions grouped by Jalali `{year: {month: count}}`.
  late final Map<int, Map<int, int>> expenseCountsByYearMonth = () {
    final map = <int, Map<int, int>>{};
    for (final t in activeTransactions) {
      if (t.type != TransactionType.expense) continue;
      final j = Jalali.fromDateTime(t.occurredAt);
      final months = map.putIfAbsent(j.year, () => <int, int>{});
      months[j.month] = (months[j.month] ?? 0) + 1;
    }
    return map;
  }();

  /// Counts of all active transactions grouped by Jalali `{year: {month: count}}`.
  late final Map<int, Map<int, int>> transactionCountsByYearMonth = () {
    final map = <int, Map<int, int>>{};
    for (final t in activeTransactions) {
      final j = Jalali.fromDateTime(t.occurredAt);
      final months = map.putIfAbsent(j.year, () => <int, int>{});
      months[j.month] = (months[j.month] ?? 0) + 1;
    }
    return map;
  }();

  /// Counts of active bank messages grouped by Jalali `{year: {month: count}}`.
  late final Map<int, Map<int, int>> messageCountsByYearMonth = () {
    final map = <int, Map<int, int>>{};
    for (final m in activeBankMessages) {
      final j = Jalali.fromDateTime(m.receivedAt);
      final months = map.putIfAbsent(j.year, () => <int, int>{});
      months[j.month] = (months[j.month] ?? 0) + 1;
    }
    return map;
  }();

  late final List<BankTransaction> _thisMonth =
      transactionsInFilter(JalaliDateFilter.thisMonth(_now));

  /// Monthly income excluding internal transfers.
  late final int monthIncome = _thisMonth
      .where((t) => t.type == TransactionType.income)
      .fold(0, (s, t) => s + t.amountRial);

  /// Monthly expense excluding internal transfers.
  late final int monthExpense = _thisMonth
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (s, t) => s + t.amountRial);

  /// Aggregated expense slices for [filter], sorted largest-first (cached).
  List<CategoryExpenseSlice> expenseBreakdown(JalaliDateFilter filter) {
    final cached = _breakdownCache[filter];
    if (cached != null) return cached;

    final txs = transactionsInFilter(filter);
    final amounts = <UiCategory, int>{};
    final counts = <UiCategory, int>{};
    var total = 0;

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      final cat = categoryOf(t.categoryId);
      amounts[cat] = (amounts[cat] ?? 0) + t.amountRial;
      counts[cat] = (counts[cat] ?? 0) + 1;
      total += t.amountRial;
    }

    if (total <= 0) {
      _breakdownCache[filter] = const [];
      return const [];
    }

    final slices = [
      for (final e in amounts.entries)
        CategoryExpenseSlice(
          category: e.key,
          amountRial: e.value,
          transactionCount: counts[e.key] ?? 0,
          percentage: (e.value * 100.0) / total,
        ),
    ]..sort((a, b) => b.amountRial.compareTo(a.amountRial));

    _breakdownCache[filter] = slices;
    return slices;
  }

  late final List<UiSender> senders = () {
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
      dateLabel = j.year == _nowJalali.year
          ? '${j.day} ${j.formatter.mN}'
          : '${j.day} ${j.formatter.mN} ${j.year}';
    }
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return (PersianFormat.digits(dateLabel), PersianFormat.digits('$hh:$mm'));
  }
}
