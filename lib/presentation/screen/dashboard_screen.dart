import 'package:flutter/material.dart';
import 'package:siaheh/presentation/screen/tabs/home_tab.dart';
import 'package:siaheh/presentation/screen/tabs/senders_tab.dart';
import 'package:siaheh/presentation/screen/tabs/transactions_tab.dart';

class DashboardScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();

  static String get routeName => "/DashboardScreen";
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(onSeeAllTransactions: () => setState(() => _index = 1)),
          const TransactionsTab(),
          const SendersTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'تراکنش‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.sms_outlined),
            selectedIcon: Icon(Icons.sms_rounded),
            label: 'منابع پیامک',
          ),
        ],
      ),
    );
  }
}
