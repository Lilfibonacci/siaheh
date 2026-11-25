import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:siaheh/data/datasources/sms_inbox_data_source.dart';
import 'package:siaheh/data/datasources/sms_inbox_data_source_impl.dart';
import 'package:siaheh/data/datasources/sms_local_data_source.dart';
import 'package:siaheh/data/datasources/sms_local_data_source_impl.dart';
import 'package:siaheh/data/datasources/theme_local_data_source.dart';
import 'package:siaheh/data/datasources/theme_local_data_source_impl.dart';
import 'package:siaheh/data/parsers/bank_detector.dart';
import 'package:siaheh/data/parsers/expense_categorizer.dart';
import 'package:siaheh/data/parsers/generic_sms_parser.dart';
import 'package:siaheh/data/parsers/internal_transfer_detector.dart';
import 'package:siaheh/data/parsers/sms_parser_pipeline.dart';
import 'package:siaheh/data/repositories/sms_repository_impl.dart';
import 'package:siaheh/data/repositories/theme_repository_impl.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';
import 'package:siaheh/domain/repositories/theme_repository.dart';
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
import 'package:siaheh/domain/usecases/theme/get_theme_preference_usecase.dart';
import 'package:siaheh/domain/usecases/theme/set_theme_preference_usecase.dart';
import 'package:siaheh/presentation/bloc/finance/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/theme/theme_bloc.dart';

final GetIt sl = GetIt.instance;

/// Composition root wiring data sources, parsers, repositories, use cases,
/// and presentation BLoCs.
Future<void> configureDependencies() async {
  await Hive.initFlutter();

  await _initDataSources();
  _initParsers();
  _initRepositories();
  _initUseCases();
  _initBlocs();
}

Future<void> _initDataSources() async {
  final syncMetaBox = await Hive.openBox<dynamic>(
    SmsLocalDataSourceImpl.syncMetaBox,
  );
  final smsLocalDataSource = await SmsLocalDataSourceImpl.open(
    syncMeta: syncMetaBox,
  );
  final themeLocalDataSource = ThemeLocalDataSourceImpl(syncMetaBox);

  sl
    ..registerSingleton<SmsLocalDataSource>(smsLocalDataSource)
    ..registerSingleton<ThemeLocalDataSource>(themeLocalDataSource)
    ..registerLazySingleton<SmsInboxDataSource>(SmsInboxDataSourceImpl.new);
}

void _initParsers() {
  sl
    ..registerLazySingleton<BankDetector>(() => const BankDetector())
    ..registerLazySingleton<GenericSmsParser>(() => const GenericSmsParser())
    ..registerLazySingleton<SmsParserPipeline>(
      () => SmsParserPipeline(detector: sl(), genericParser: sl()),
    )
    ..registerLazySingleton<InternalTransferDetector>(
      () => const InternalTransferDetector(),
    )
    ..registerLazySingleton<ExpenseCategorizer>(
      () => const ExpenseCategorizer(),
    );
}

void _initRepositories() {
  sl
    ..registerLazySingleton<SmsRepository>(
      () => SmsRepositoryImpl(sl(), sl(), sl(), sl(), sl()),
    )
    ..registerLazySingleton<ThemeRepository>(
      () => ThemeRepositoryImpl(sl()),
    );
}

void _initUseCases() {
  sl
    ..registerLazySingleton(() => GetTransactionsUseCase(sl()))
    ..registerLazySingleton(() => GetBankMessagesUseCase(sl()))
    ..registerLazySingleton(() => GetSendersUseCase(sl()))
    ..registerLazySingleton(() => GetCustomCategoriesUseCase(sl()))
    ..registerLazySingleton(() => GetCategoryRulesUseCase(sl()))
    ..registerLazySingleton(() => SyncInboxUseCase(sl()))
    ..registerLazySingleton(() => SaveSenderUseCase(sl()))
    ..registerLazySingleton(() => DeleteSenderUseCase(sl()))
    ..registerLazySingleton(() => UpdateTransactionUseCase(sl()))
    ..registerLazySingleton(() => DeleteTransactionUseCase(sl()))
    ..registerLazySingleton(() => SaveCustomCategoryUseCase(sl()))
    ..registerLazySingleton(() => DeleteCustomCategoryUseCase(sl()))
    ..registerLazySingleton(() => WatchIncomingMessagesUseCase(sl()))
    ..registerLazySingleton(() => HasSmsPermissionUseCase(sl()))
    ..registerLazySingleton(() => RequestSmsPermissionUseCase(sl()))
    ..registerLazySingleton(() => GetThemePreferenceUseCase(sl()))
    ..registerLazySingleton(() => SetThemePreferenceUseCase(sl()));
}

void _initBlocs() {
  sl
    ..registerLazySingleton<FinanceBloc>(
      () => FinanceBloc(
        getTransactions: sl(),
        getBankMessages: sl(),
        getSenders: sl(),
        getCustomCategories: sl(),
        getCategoryRules: sl(),
        syncInbox: sl(),
        saveSender: sl(),
        deleteSender: sl(),
        updateTransaction: sl(),
        deleteTransaction: sl(),
        saveCustomCategory: sl(),
        deleteCustomCategory: sl(),
        watchIncomingMessages: sl(),
        hasSmsPermission: sl(),
        requestSmsPermission: sl(),
      ),
    )
    ..registerLazySingleton<ThemeBloc>(
      () => ThemeBloc(
        getThemePreference: sl(),
        setThemePreference: sl(),
      ),
    );
}
