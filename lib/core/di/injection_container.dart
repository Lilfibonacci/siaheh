import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

final GetIt sl = GetIt.instance;

/// Composition root. Every feature registers its own dependencies via a
/// dedicated `init<Feature>()` function that is called from here, so this file
/// only depends on abstractions of each feature (Dependency Inversion).
Future<void> configureDependencies() async {
  await Hive.initFlutter();

  // Feature modules will be registered here, e.g.:
  // initAccountsFeature();
  // initTransactionsFeature();
  // initSmsFeature();
}
