import 'package:go_router/go_router.dart';
import 'package:siaheh/ui/features/dashboard/views/dashboard_screen.dart';
import 'package:siaheh/ui/features/splash/views/loading_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: LoadingScreen.routeName,
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: '/DashboardScreen',
      name: DashboardScreen.routeName,
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);
