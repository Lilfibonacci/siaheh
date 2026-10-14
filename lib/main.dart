import 'package:flutter/material.dart';
import 'package:siaheh/core/router/app_global_router.dart';
import 'package:siaheh/core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const new({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'siaheh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appGlobalRouter,
    );
  }
}
