import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:siaheh/features/sms/data/datasources/sms_inbox_data_source.dart';
import 'package:siaheh/features/sms/data/datasources/sms_local_data_source.dart';
import 'package:siaheh/features/sms/data/parsers/bank_detector.dart';
import 'package:siaheh/features/sms/data/parsers/expense_categorizer.dart';
import 'package:siaheh/features/sms/data/parsers/generic_sms_parser.dart';
import 'package:siaheh/features/sms/data/parsers/internal_transfer_detector.dart';
import 'package:siaheh/features/sms/data/parsers/sms_parser_pipeline.dart';
import 'package:siaheh/features/sms/data/repositories/sms_repository_impl.dart';
import 'package:siaheh/features/sms/domain/repositories/sms_repository.dart';
import 'package:siaheh/presentation/bloc/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/theme_bloc.dart';

final GetIt sl = GetIt.instance;

/// Composition root. Every feature registers its own dependencies via a
/// dedicated `init<Feature>()` function.
Future<void> configureDependencies() async {
  await Hive.initFlutter();

  await initSmsFeature();
}

Future<void> initSmsFeature() async {
  final localDataSource = await SmsLocalDataSource.open();
  sl
    ..registerSingleton<SmsLocalDataSource>(localDataSource)
    ..registerLazySingleton<SmsInboxDataSource>(SmsInboxDataSource.new)
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
    )
    ..registerLazySingleton<SmsRepository>(
      () => SmsRepositoryImpl(sl(), sl(), sl(), sl(), sl()),
    )
    ..registerLazySingleton<FinanceBloc>(() => FinanceBloc(sl()))
    ..registerLazySingleton<ThemeBloc>(
      () => ThemeBloc(
        initialMode: ThemeBloc.parseModeName(localDataSource.themeModeName),
        onModeChanged: (mode) => localDataSource.setThemeModeName(mode.name),
      ),
    );
}
