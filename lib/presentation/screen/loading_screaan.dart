import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:siaheh/presentation/screen/dashboard_screen.dart';

class LoadingScreaan extends StatefulWidget {
  const LoadingScreaan({super.key});

  static String get routeName => "/";

  @override
  State<LoadingScreaan> createState() => _LoadingScreaanState();
}

class _LoadingScreaanState extends State<LoadingScreaan> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      context.goNamed(DashboardScreen.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Center(
        child: Lottie.asset(
          "assets/lottie/loading.json",
          height: size.height * 0.3,
          width: size.height * 0.3,
        ),
      ),
    );
  }
}
