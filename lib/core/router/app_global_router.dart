import 'package:go_router/go_router.dart';
import 'package:siaheh/presentation/screen/dashboard_screen.dart';
import 'package:siaheh/presentation/screen/loading_screaan.dart';

final GoRouter appGlobalRouter = GoRouter(
  routes: [
    //loadingSreen
    GoRoute(
      path: '/',
      name: LoadingScreaan.routeName,
      builder: (context, state) => const LoadingScreaan(),
    ),

    //dashboardScreen
    GoRoute(
      path: '/DashboardScreen',
      name: DashboardScreen.routeName,
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);
