import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaheh/presentation/bloc/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance_event.dart';
import 'package:siaheh/presentation/screen/tabs/bank_messages_tab.dart';
import 'package:siaheh/presentation/screen/tabs/home_tab.dart';
import 'package:siaheh/presentation/screen/tabs/senders_tab.dart';
import 'package:siaheh/presentation/screen/tabs/transactions_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();

  static String get routeName => '/DashboardScreen';
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _index = 0;
  final Set<int> _mountedTabs = {0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<FinanceBloc>().add(const FinanceAppResumed());
    }
  }

  void _selectTab(int index) {
    setState(() {
      _index = index;
      _mountedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(
            onSeeAllTransactions: () => _selectTab(1),
            onSeeAllMessages: () => _selectTab(2),
          ),
          _mountedTabs.contains(1)
              ? const TransactionsTab()
              : const SizedBox.shrink(),
          _mountedTabs.contains(2)
              ? const BankMessagesTab()
              : const SizedBox.shrink(),
          _mountedTabs.contains(3)
              ? const SendersTab()
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
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
            icon: Icon(Icons.mark_email_unread_outlined),
            selectedIcon: Icon(Icons.mark_email_unread_rounded),
            label: 'پیامک‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'منابع',
          ),
        ],
      ),
    );
  }
}
