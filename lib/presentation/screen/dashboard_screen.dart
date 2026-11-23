import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/core/theme/app_colors.dart';
import 'package:siaheh/core/theme/app_fonts.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
import 'package:siaheh/presentation/bloc/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance_event.dart';
import 'package:siaheh/presentation/models/finance_ui_models.dart';
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
  String? _selectedCategoryFilter;
  JalaliDateFilter? _selectedDateFilter;
  int _dateFilterVersion = 0;

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

  void _openCategoryTransactions(
    String categoryName,
    JalaliDateFilter monthFilter,
  ) {
    setState(() {
      _selectedCategoryFilter = categoryName;
      _selectedDateFilter = monthFilter;
      _dateFilterVersion++;
      _index = 1;
      _mountedTabs.add(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color activeAccent =
        isDark ? AppColors.goldDarkTheme : AppColors.goldLightTheme;
    final Color activeForeground =
        isDark ? activeAccent : theme.colorScheme.onSurface;
    final Color unselectedColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.66 : 0.62,
    );

    return SiahehAmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: [
            HomeTab(
              onSeeAllTransactions: () {
                setState(() {
                  _selectedCategoryFilter = null;
                  _selectedDateFilter = const JalaliDateFilter.all();
                  _dateFilterVersion++;
                });
                _selectTab(1);
              },
              onSeeAllMessages: () => _selectTab(2),
              onCategorySelected: _openCategoryTransactions,
            ),
            _mountedTabs.contains(1)
                ? TransactionsTab(
                    categoryFilter: _selectedCategoryFilter,
                    externalDateFilter: _selectedDateFilter,
                    externalDateFilterVersion: _dateFilterVersion,
                    onClearCategoryFilter: () =>
                        setState(() => _selectedCategoryFilter = null),
                  )
                : const SizedBox.shrink(),
            _mountedTabs.contains(2)
                ? const BankMessagesTab()
                : const SizedBox.shrink(),
            _mountedTabs.contains(3)
                ? const SendersTab()
                : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: GlassTabBar.bottom(
          selectedIndex: _index,
          onTabSelected: _selectTab,
          barHeight: 66,
          horizontalPadding: 16,
          verticalPadding: 12,
          settings: SiahehGlass.tabBarSettings(theme.brightness),
          interactionBehavior: GlassInteractionBehavior.scaleOnly,
          selectedIconColor: activeForeground,
          unselectedIconColor: unselectedColor,
          selectedLabelColor: activeForeground,
          unselectedLabelColor: unselectedColor,
          selectedLabelStyle: const TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          indicatorColor: isDark
              ? activeAccent.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.92),
          tabs: const [
            GlassTab(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'خانه',
            ),
            GlassTab(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'تراکنش‌ها',
            ),
            GlassTab(
              icon: Icon(Icons.mark_email_unread_outlined),
              activeIcon: Icon(Icons.mark_email_unread_rounded),
              label: 'پیامک‌ها',
            ),
            GlassTab(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune_rounded),
              label: 'منابع',
            ),
          ],
        ),
      ),
    );
  }
}
