import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:siaheh/data/repositories/sms_repository_impl.dart';
import 'package:siaheh/data/repositories/theme_repository_impl.dart';
import 'package:siaheh/data/services/local/sms_local_storage_service.dart';
import 'package:siaheh/data/services/local/theme_storage_service.dart';
import 'package:siaheh/data/services/parsers/bank_detector.dart';
import 'package:siaheh/data/services/parsers/expense_categorizer.dart';
import 'package:siaheh/data/services/parsers/generic_sms_parser.dart';
import 'package:siaheh/data/services/parsers/internal_transfer_detector.dart';
import 'package:siaheh/data/services/parsers/sms_parser_pipeline.dart';
import 'package:siaheh/data/services/platform/sms_inbox_service.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';
import 'package:siaheh/domain/repositories/theme_repository.dart';
import 'package:siaheh/ui/core/bloc/finance_bloc.dart';
import 'package:siaheh/ui/core/bloc/theme_bloc.dart';

final GetIt sl = GetIt.instance;

/// Composition root wiring data services, repositories, and UI BLoCs.
Future<void> configureDependencies() async {
  await Hive.initFlutter();

  await _initServices();
  _initRepositories();
  _initBlocs();
}

Future<void> _initServices() async {
  final syncMetaBox = await Hive.openBox<dynamic>(
    SmsLocalStorageService.syncMetaBox,
  );
  final smsLocalStorage = await SmsLocalStorageService.open(
    syncMeta: syncMetaBox,
  );
  final themeStorage = ThemeStorageService(syncMetaBox);

  sl
    ..registerSingleton<SmsLocalStorageService>(smsLocalStorage)
    ..registerSingleton<ThemeStorageService>(themeStorage)
    ..registerLazySingleton<SmsInboxService>(SmsInboxService.new)
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

void _initBlocs() {
  sl
    ..registerLazySingleton<FinanceBloc>(() => FinanceBloc(sl()))
    ..registerLazySingleton<ThemeBloc>(
      () => ThemeBloc(repository: sl()),
    );
}
