import 'package:equatable/equatable.dart';
import 'package:siaheh/features/sms/domain/entities/bank_sms_message.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/features/sms/domain/entities/category_rule.dart';
import 'package:siaheh/features/sms/domain/entities/custom_category.dart';
import 'package:siaheh/features/sms/domain/entities/sms_sender.dart';
import 'package:siaheh/features/sms/domain/repositories/sms_repository.dart';

class FinanceState extends Equatable {
  const FinanceState({
    this.transactions = const [],
    this.bankMessages = const [],
    this.senders = const [],
    this.customCategories = const [],
    this.categoryRules = const [],
    this.hasPermission = false,
    this.loading = true,
    this.syncing = false,
    this.error,
    this.lastSyncResult,
  });

  final List<BankTransaction> transactions;
  final List<BankSmsMessage> bankMessages;
  final List<SmsSender> senders;
  final List<CustomCategory> customCategories;
  final List<CategoryRule> categoryRules;
  final bool hasPermission;
  final bool loading;
  final bool syncing;
  final String? error;
  final SyncResult? lastSyncResult;

  FinanceState copyWith({
    List<BankTransaction>? transactions,
    List<BankSmsMessage>? bankMessages,
    List<SmsSender>? senders,
    List<CustomCategory>? customCategories,
    List<CategoryRule>? categoryRules,
    bool? hasPermission,
    bool? loading,
    bool? syncing,
    String? error,
    SyncResult? lastSyncResult,
  }) => FinanceState(
    transactions: transactions ?? this.transactions,
    bankMessages: bankMessages ?? this.bankMessages,
    senders: senders ?? this.senders,
    customCategories: customCategories ?? this.customCategories,
    categoryRules: categoryRules ?? this.categoryRules,
    hasPermission: hasPermission ?? this.hasPermission,
    loading: loading ?? this.loading,
    syncing: syncing ?? this.syncing,
    error: error,
    lastSyncResult: lastSyncResult ?? this.lastSyncResult,
  );

  @override
  List<Object?> get props => [
    transactions,
    bankMessages,
    senders,
    customCategories,
    categoryRules,
    hasPermission,
    loading,
    syncing,
    error,
    lastSyncResult,
  ];
}
