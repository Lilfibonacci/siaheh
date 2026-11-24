import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/config/di/injection_container.dart';
import 'package:siaheh/config/router/app_router.dart';
import 'package:siaheh/ui/core/bloc/finance_bloc.dart';
import 'package:siaheh/ui/core/bloc/finance_event.dart';
import 'package:siaheh/ui/core/bloc/theme_bloc.dart';
import 'package:siaheh/ui/core/theme/app_theme.dart';
import 'package:siaheh/ui/core/theme/siaheh_glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  await configureDependencies();
  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      adaptiveConfig: const GlassAdaptiveScopeConfig(
        initialQuality: GlassQuality.standard,
        frostStep: true,
        targetFrameMs: 16,
      ),
      brightnessResolver: Theme.maybeBrightnessOf,
      theme: SiahehGlass.themeData,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sl<FinanceBloc>().add(const FinanceStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<FinanceBloc>()),
        BlocProvider.value(value: sl<ThemeBloc>()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) => MaterialApp.router(
          title: 'siaheh',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeState.mode,
          routerConfig: appRouter,
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
        ),
      ),
    );
  }
}
