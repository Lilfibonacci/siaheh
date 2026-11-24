import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/domain/models/failure.dart';
import 'package:siaheh/ui/core/theme/app_theme.dart';
import 'package:siaheh/ui/core/theme/siaheh_glass.dart';
import 'package:siaheh/domain/models/bank_sms_message.dart';
import 'package:siaheh/domain/models/bank_transaction.dart';
import 'package:siaheh/domain/models/category_rule.dart';
import 'package:siaheh/domain/models/custom_category.dart';
import 'package:siaheh/domain/models/sms_sender.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';
import 'package:siaheh/ui/core/bloc/finance_bloc.dart';
import 'package:siaheh/ui/core/bloc/finance_event.dart';
import 'package:siaheh/ui/core/bloc/theme_bloc.dart';
import 'package:siaheh/ui/features/dashboard/views/dashboard_screen.dart';
import 'package:siaheh/ui/features/home/widgets/account_card.dart';
import 'package:siaheh/ui/features/home/widgets/balance_header_card.dart';
import 'package:siaheh/ui/features/home/widgets/expense_donut.dart';
import 'package:siaheh/ui/features/transactions/widgets/transaction_tile.dart';

class _TestSmsRepository implements SmsRepository {
  final StreamController<BankSmsMessage> _incoming =
      StreamController<BankSmsMessage>.broadcast();

  final DateTime now = DateTime.now();

  late final List<SmsSender> _senders = const [
    SmsSender(number: '+9830007100', bankKey: 'blubank', autoDetected: true),
  ];

  late final List<BankSmsMessage> _messages = [
    BankSmsMessage(
      id: 'm1',
      senderAddress: '+9830007100',
      bankKey: 'blubank',
      body: 'برداشت از حساب ۱۲۳۴ مبلغ ۲۵۰,۰۰۰ ریال اسنپ\nموجودی: ۴,۵۰۰,۰۰۰ ریال',
      receivedAt: now,
      kind: BankSmsKind.transaction,
      transactionId: 't1',
    ),
  ];

  late final List<BankTransaction> _txs = [
    BankTransaction(
      id: 't1',
      smsId: 'm1',
      bankKey: 'blubank',
      senderNumber: '+9830007100',
      accountNumber: '1234',
      type: TransactionType.expense,
      amountRial: 250000,
      balanceRial: 4500000,
      occurredAt: now,
      rawBody: 'برداشت از حساب ۱۲۳۴ مبلغ ۲۵۰,۰۰۰ ریال اسنپ',
      title: 'اسنپ',
      merchantName: 'اسنپ',
      categoryId: 'حمل‌ونقل',
    ),
  ];

  @override
  Future<bool> hasSmsPermission() async => true;

  @override
  Future<bool> requestSmsPermission() async => true;

  @override
  Stream<BankSmsMessage> get incomingMessages => _incoming.stream;

  @override
  Future<Either<Failure, List<BankSmsMessage>>> getBankMessages() async =>
      Right(_messages);

  @override
  Future<Either<Failure, List<SmsSender>>> getSenders() async =>
      Right(_senders);

  @override
  Future<Either<Failure, List<BankTransaction>>> getTransactions() async =>
      Right(_txs);

  @override
  Future<Either<Failure, List<CustomCategory>>> getCustomCategories() async =>
      const Right([]);

  @override
  Future<Either<Failure, Unit>> saveCustomCategory(
    CustomCategory category,
  ) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> deleteCustomCategory(String name) async =>
      const Right(unit);

  @override
  Future<Either<Failure, List<CategoryRule>>> getCategoryRules() async =>
      const Right([]);

  @override
  Future<Either<Failure, Unit>> saveSender(SmsSender sender) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> deleteSender(String number) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> updateTransaction(
    BankTransaction tx, {
    bool applyToSimilar = false,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> deleteTransaction(String id) async =>
      const Right(unit);

  @override
  Future<Either<Failure, SyncResult>> syncInbox({bool fullRescan = false}) async =>
      const Right(SyncResult(newMessages: 0, newTransactions: 0));

  void dispose() => _incoming.close();
}

Widget _buildHarness(
  FinanceBloc bloc,
  ThemeMode mode, {
  ThemeBloc? themeBloc,
}) {
  final effectiveThemeBloc = themeBloc ?? ThemeBloc(initialMode: mode);
  return LiquidGlassWidgets.wrap(
    brightnessResolver: Theme.maybeBrightnessOf,
    theme: SiahehGlass.themeData,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bloc),
        BlocProvider.value(value: effectiveThemeBloc),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) => MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeState.mode,
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const DashboardScreen(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Liquid Glass Dashboard renders all tabs and sheets in Dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _TestSmsRepository();
    final bloc = FinanceBloc(repo)..add(const FinanceStarted());
    addTearDown(() {
      bloc.close();
      repo.dispose();
    });

    await tester.pumpWidget(_buildHarness(bloc, ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(find.byType(BalanceHeaderCard), findsOneWidget);
    expect(find.byType(AccountCard), findsOneWidget);
    expect(find.byType(ExpenseDonut), findsOneWidget);
    expect(find.byType(GlassSegmentedControl), findsOneWidget);
    expect(find.text('انتخاب ماه'), findsOneWidget);
    expect(find.text('کل'), findsNothing);

    // Open custom month picker from ExpenseDonut and verify it renders cleanly.
    await tester.tap(find.text('انتخاب ماه'));
    await tester.pumpAndSettle();
    expect(find.text('انتخاب ماه و سال'), findsOneWidget);
    await tester.tap(find.text('فروردین'));
    await tester.pumpAndSettle();
    expect(find.text('انتخاب ماه و سال'), findsNothing);

    // Switch to Senders tab, verify compact GlassSwitch, and open AddSender glass sheet.
    await tester.tap(find.text('منابع').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    final GlassSwitch senderSwitch = tester.widget<GlassSwitch>(
      find.byType(GlassSwitch),
    );
    expect(senderSwitch.width, 42);
    expect(senderSwitch.height, 21);

    await tester.tap(find.text('افزودن سرشماره'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassSheet), findsOneWidget);
    expect(find.byType(GlassTextField), findsNWidgets(2));
    expect(find.text('افزودن سرشماره بانک'), findsOneWidget);
    Navigator.of(tester.element(find.text('افزودن سرشماره بانک'))).pop();
    await tester.pumpAndSettle();

    // Switch to Bank Messages tab and test Jalali date filter sheet & GlassSearchBar.
    await tester.tap(find.text('پیامک‌ها').last, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('پیامک‌های بانکی'), findsOneWidget);
    // Selected GlassChip must use a single uniform glass tint (transparent
    // selectedColor prevents two-tone nested pill inside horizontal lists).
    final GlassChip selectedMsgChip = tester.widget<GlassChip>(
      find.byType(GlassChip).first,
    );
    expect(selectedMsgChip.selected, isTrue);
    expect(selectedMsgChip.selectedColor, Colors.transparent);
    expect(selectedMsgChip.settings?.glassColor.a ?? 0, greaterThan(0.15));
    expect(
      selectedMsgChip.labelStyle?.color != selectedMsgChip.settings?.glassColor,
      isTrue,
    );
    expect(find.text('همه زمان‌ها'), findsNothing);
    await tester.tap(find.byIcon(Icons.search_rounded).last);
    await tester.pumpAndSettle();
    expect(find.byType(GlassSearchBar), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_month_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('فیلتر زمانی پیامک‌ها'), findsOneWidget);
    await tester.tap(find.text('امروز'));
    await tester.pumpAndSettle();
    expect(find.text('امروز'), findsWidgets);

    // Switch to Transactions tab, test Jalali date filter sheet via calendar icon, and edit sheet.
    await tester.tap(find.text('تراکنش‌ها').last, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(TransactionTile), findsOneWidget);
    final GlassChip selectedTxChip = tester.widget<GlassChip>(
      find.byType(GlassChip).first,
    );
    expect(selectedTxChip.selected, isTrue);
    expect(selectedTxChip.selectedColor, Colors.transparent);
    expect(selectedTxChip.settings?.glassColor.a ?? 0, greaterThan(0.15));
    expect(
      selectedTxChip.labelStyle?.color != selectedTxChip.settings?.glassColor,
      isTrue,
    );
    expect(find.text('همه زمان‌ها'), findsNothing);

    await tester.tap(find.byIcon(Icons.calendar_month_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('فیلتر زمانی تراکنش‌ها'), findsOneWidget);
    await tester.tap(find.text('این ماه').last);
    await tester.pumpAndSettle();
    expect(find.byType(TransactionTile), findsOneWidget);

    await tester.tap(find.byType(TransactionTile));
    await tester.pumpAndSettle();
    expect(find.byType(GlassSheet), findsOneWidget);
    expect(find.byType(GlassTextField), findsNWidgets(2));
    expect(find.text('ویرایش تراکنش'), findsOneWidget);
  });

  testWidgets('Liquid Glass Dashboard renders cleanly in Light mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _TestSmsRepository();
    final bloc = FinanceBloc(repo)..add(const FinanceStarted());
    final themeBloc = ThemeBloc(initialMode: ThemeMode.light);
    addTearDown(() {
      bloc.close();
      themeBloc.close();
      repo.dispose();
    });

    await tester.pumpWidget(
      _buildHarness(bloc, ThemeMode.light, themeBloc: themeBloc),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(find.byType(BalanceHeaderCard), findsOneWidget);
    expect(find.byType(ExpenseDonut), findsOneWidget);

    // BalanceHeaderCard should be genuinely light in Light mode (dark label ink).
    final Text lightLabel = tester.widget<Text>(find.text('موجودی کل'));
    expect(lightLabel.style?.color?.computeLuminance(), lessThan(0.25));

    // Toggle theme from Light -> Dark via the HomeTab header icon button.
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();
    expect(themeBloc.state.mode, ThemeMode.dark);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    // BalanceHeaderCard should flip to luminous light ink on dark obsidian card.
    final Text darkLabel = tester.widget<Text>(find.text('موجودی کل'));
    expect(darkLabel.style?.color?.computeLuminance(), greaterThan(0.75));

    // Toggle back Dark -> Light.
    await tester.tap(find.byIcon(Icons.light_mode_rounded));
    await tester.pumpAndSettle();
    expect(themeBloc.state.mode, ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
  });
}
