import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/ui/core/theme/siaheh_glass.dart';
import 'package:siaheh/ui/core/utils/persian_format.dart';
import 'package:siaheh/domain/models/bank_sms_message.dart';
import 'package:siaheh/domain/models/iranian_bank_registry.dart';
import 'package:siaheh/ui/core/bloc/finance_bloc.dart';
import 'package:siaheh/ui/core/bloc/finance_event.dart';
import 'package:siaheh/ui/core/bloc/finance_state.dart';
import 'package:siaheh/ui/core/mappers/finance_mapper.dart';
import 'package:siaheh/ui/core/models/finance_ui_models.dart';
import 'package:siaheh/ui/core/widgets/bank_logo.dart';
import 'package:siaheh/ui/core/widgets/jalali_period_picker.dart';
import 'package:siaheh/ui/features/transactions/widgets/transaction_edit_sheet.dart';

/// Dedicated inbox tab displaying ALL detected bank SMS across all banks
/// (transactions, info alerts, OTPs, and unparsed financial messages).
class BankMessagesTab extends StatefulWidget {
  const BankMessagesTab({super.key});

  @override
  State<BankMessagesTab> createState() => _BankMessagesTabState();
}

class _BankMessagesTabState extends State<BankMessagesTab> {
  String? _selectedBankKey;
  BankSmsKind? _selectedKind;
  JalaliDateFilter _dateFilter = const JalaliDateFilter.all();
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openDateFilterPicker(FinanceMapper mapper) async {
    final JalaliDateFilter? picked = await showJalaliPeriodPickerSheet(
      context: context,
      title: 'فیلتر زمانی پیامک‌ها',
      initialFilter: _dateFilter,
      countsByYearMonth: mapper.messageCountsByYearMonth,
      allowAll: true,
      allowWholeYear: true,
      allowQuickRanges: true,
      itemUnitLabel: 'پیامک',
    );
    if (picked != null && mounted) {
      setState(() => _dateFilter = picked);
    }
  }

  List<BankSmsMessage> _filtered(List<BankSmsMessage> all) {
    final query = _searchController.text.trim().toLowerCase();
    final (DateTime? start, DateTime? end) = _dateFilter.bounds();

    return all.where((m) {
      if (start != null && m.receivedAt.isBefore(start)) return false;
      if (end != null && !m.receivedAt.isBefore(end)) return false;

      if (_selectedBankKey != null && m.bankKey != _selectedBankKey) {
        return false;
      }
      if (_selectedKind != null && m.kind != _selectedKind) {
        return false;
      }
      if (query.isNotEmpty) {
        final inBody = m.body.toLowerCase().contains(query);
        final inBank =
            IranianBankRegistry.byKey(m.bankKey).name.toLowerCase().contains(query);
        final inSender = m.senderAddress.toLowerCase().contains(query);
        if (!inBody && !inBank && !inSender) return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final FinanceState state = context.watch<FinanceBloc>().state;
    final FinanceMapper mapper = FinanceMapper.of(state);
    final List<BankSmsMessage> allMessages = mapper.activeBankMessages;
    final List<UiBank> banks = mapper.detectedBanks;
    final List<BankSmsMessage> items = _filtered(allMessages);
    final String subtitle = _dateFilter.isActive
        ? PersianFormat.digits(
            '${items.length} از ${allMessages.length} پیامک • ${_dateFilter.label}',
          )
        : PersianFormat.digits(
            '${allMessages.length} پیامک از ${banks.length} بانک',
          );

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'پیامک‌های بانکی',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                GlassBackdropGroup(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassButton.custom(
                        useOwnLayer: true,
                        quality: GlassQuality.standard,
                        width: 42,
                        height: 42,
                        stretch: 0.15,
                        tintColor: _dateFilter.isActive
                            ? scheme.primary.withValues(alpha: 0.20)
                            : null,
                        label: 'فیلتر زمانی',
                        onTap: () => _openDateFilterPicker(mapper),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: _dateFilter.isActive
                              ? scheme.primary
                              : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GlassButton.custom(
                        useOwnLayer: true,
                        quality: GlassQuality.standard,
                        width: 42,
                        height: 42,
                        stretch: 0.15,
                        label: _searching ? 'بستن جستجو' : 'جستجو',
                        onTap: () {
                          setState(() {
                            _searching = !_searching;
                            if (!_searching) _searchController.clear();
                          });
                        },
                        child: Icon(
                          _searching
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          size: 20,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GlassButton.custom(
                        useOwnLayer: true,
                        quality: GlassQuality.standard,
                        width: 42,
                        height: 42,
                        stretch: 0.15,
                        enabled: !state.syncing,
                        label: 'بروزرسانی پیامک‌ها',
                        onTap: () => context.read<FinanceBloc>().add(
                          const FinanceSyncRequested(),
                        ),
                        child: state.syncing
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                size: 20,
                                color: scheme.onSurface,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GlassSearchBar(
                controller: _searchController,
                autofocus: true,
                useOwnLayer: true,
                quality: GlassQuality.standard,
                settings: SiahehGlass.inputSettings(theme.brightness),
                placeholder: 'جستجو در متن پیامک، نام بانک یا سرشماره...',
                searchIconColor: scheme.onSurface.withValues(alpha: 0.65),
                clearIconColor: scheme.onSurface.withValues(alpha: 0.65),
                textStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                ),
                placeholderStyle: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.52),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          if (banks.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: GlassBackdropGroup(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Center(
                      child: _KindChip(
                        label: PersianFormat.digits(
                          'همه بانک‌ها (${allMessages.length})',
                        ),
                        selected: _selectedBankKey == null,
                        onTap: () => setState(() => _selectedBankKey = null),
                      ),
                    ),
                    for (final UiBank b in banks)
                      Center(
                        child: _KindChip(
                          leading: BankLogo(bankKey: b.key, size: 18),
                          label: PersianFormat.digits(
                            '${b.name} (${mapper.messageCountForBank(b.key)})',
                          ),
                          selected: _selectedBankKey == b.key,
                          onTap: () => setState(() => _selectedBankKey = b.key),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: GlassBackdropGroup(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (_dateFilter.isActive) ...[
                    Center(
                      child: JalaliDateFilterChip(
                        filter: _dateFilter,
                        onTap: () => _openDateFilterPicker(mapper),
                        onClear: () => setState(
                          () => _dateFilter = const JalaliDateFilter.all(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Center(
                    child: _KindChip(
                      label: 'همه',
                      selected: _selectedKind == null,
                      onTap: () => setState(() => _selectedKind = null),
                    ),
                  ),
                  Center(
                    child: _KindChip(
                      label: 'تراکنش',
                      selected: _selectedKind == BankSmsKind.transaction,
                      onTap: () => setState(
                        () => _selectedKind = BankSmsKind.transaction,
                      ),
                    ),
                  ),
                  Center(
                    child: _KindChip(
                      label: 'اطلاع‌رسانی',
                      selected: _selectedKind == BankSmsKind.info,
                      onTap: () =>
                          setState(() => _selectedKind = BankSmsKind.info),
                    ),
                  ),
                  Center(
                    child: _KindChip(
                      label: 'رمز پویا',
                      selected: _selectedKind == BankSmsKind.otp,
                      onTap: () =>
                          setState(() => _selectedKind = BankSmsKind.otp),
                    ),
                  ),
                  Center(
                    child: _KindChip(
                      label: 'پارس‌نشده',
                      selected: _selectedKind == BankSmsKind.unparsed,
                      onTap: () =>
                          setState(() => _selectedKind = BankSmsKind.unparsed),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: !state.hasPermission
                ? _PermissionEmptyState(
                    onGrant: () => context.read<FinanceBloc>().add(
                      const FinancePermissionRequested(),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      context.read<FinanceBloc>().add(
                        const FinanceSyncRequested(),
                      );
                    },
                    child: items.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'پیامک بانکی با این فیلتر یافت نشد',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              8,
                              20,
                              SiahehGlass.floatingNavBottomInset,
                            ),
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final UiBankMessage msg =
                                  mapper.toUiMessage(items[i]);
                              final bool hasLinkedTx =
                                  msg.transactionId != null &&
                                  mapper.transactionUiById(msg.transactionId) !=
                                      null;
                              return _BankMessageCard(
                                message: msg,
                                onOpenTransaction: !hasLinkedTx
                                    ? null
                                    : () {
                                        final tx = mapper.transactionUiById(
                                          msg.transactionId,
                                        );
                                        if (tx != null) {
                                          showTransactionEditSheet(context, tx);
                                        }
                                      },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: SiahehGlassChip(
        icon: leading,
        label: label,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

class _BankMessageCard extends StatelessWidget {
  const _BankMessageCard({
    required this.message,
    this.onOpenTransaction,
  });

  final UiBankMessage message;
  final VoidCallback? onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final (String kindLabel, Color kindColor) = switch (message.kind) {
      BankSmsKind.transaction => ('تراکنش', scheme.secondary),
      BankSmsKind.otp => ('رمز پویا', Colors.orange),
      BankSmsKind.info => ('اطلاع‌رسانی', scheme.primary),
      BankSmsKind.unparsed => ('پارس‌نشده', scheme.error),
    };

    return SiahehGlassCard(
      radius: 20,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BankLogo(bankKey: message.bank.key, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.bank.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      PersianFormat.digits(
                        '${message.senderAddress} • ${message.dateLabel} ${message.timeLabel}',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kindColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  kindLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kindColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message.body,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onOpenTransaction != null)
                TextButton.icon(
                  onPressed: onOpenTransaction,
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text('مشاهده تراکنش'),
                ),
              IconButton(
                tooltip: 'کپی متن پیامک',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message.body));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('متن پیامک کپی شد'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionEmptyState extends StatelessWidget {
  const _PermissionEmptyState({required this.onGrant});

  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sms_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'برای نمایش خودکار پیامک‌های بانک‌ها، دسترسی خواندن پیامک را فعال کنید.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SiahehPrimaryGlassButton(
              onTap: onGrant,
              fullWidth: false,
              icon: Icons.lock_open_rounded,
              label: 'دادن دسترسی به پیامک',
            ),
          ],
        ),
      ),
    );
  }
}
