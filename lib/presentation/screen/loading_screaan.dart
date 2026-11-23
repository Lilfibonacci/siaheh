import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
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
    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final double haloSize = (size.shortestSide * 0.56).clamp(180.0, 240.0);

    return SiahehAmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassContainer(
                useOwnLayer: true,
                width: haloSize,
                height: haloSize,
                shape: const LiquidOval(),
                settings: SiahehGlass.cardSettings(theme.brightness),
                alignment: Alignment.center,
                child: Lottie.asset(
                  "assets/lottie/loading.json",
                  height: haloSize * 0.82,
                  width: haloSize * 0.82,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'سیاهه',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
