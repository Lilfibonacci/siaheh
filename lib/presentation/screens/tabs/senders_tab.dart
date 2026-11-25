import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
import 'package:siaheh/core/utils/persian_format.dart';
import 'package:siaheh/presentation/bloc/finance/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance/finance_event.dart';
import 'package:siaheh/presentation/bloc/finance/finance_state.dart';
import 'package:siaheh/presentation/bloc/finance/finance_mapper.dart';
import 'package:siaheh/presentation/bloc/finance/finance_ui_models.dart';
import 'package:siaheh/presentation/widgets/add_sender_sheet.dart';
import 'package:siaheh/presentation/widgets/bank_logo.dart';

class SendersTab extends StatelessWidget {
  const SendersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final FinanceState state = context.watch<FinanceBloc>().state;
    final List<UiSender> senders = FinanceMapper.of(state).senders;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 176),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'منابع پیامک',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (state.hasPermission)
                    GlassButton.custom(
                      useOwnLayer: true,
                      height: 40,
                      stretch: 0.15,
                      enabled: !state.syncing,
                      shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                      label: 'اسکن کامل',
                      onTap: () => context.read<FinanceBloc>().add(
                        const FinanceSyncRequested(fullRescan: true),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.radar_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'اسکن کامل',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SiahehGlassCard(
                radius: 18,
                padding: const EdgeInsets.all(14),
                tintColor: scheme.primary,
                borderColor: scheme.primary.withValues(alpha: 0.35),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'بانک‌های شما به صورت خودکار شناسایی می‌شوند و همه‌ی پردازش‌ها کاملاً آفلاین روی گوشی خودتان انجام می‌شود.',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!state.hasPermission)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SiahehPrimaryGlassButton(
                    onTap: () => context.read<FinanceBloc>().add(
                      const FinancePermissionRequested(),
                    ),
                    icon: Icons.lock_open_rounded,
                    label: 'دادن دسترسی به پیامک',
                  ),
                ),
              if (senders.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'هنوز سرشماره بانکی شناسایی نشده است.\nدکمه «اسکن کامل» یا «افزودن سرشماره» را بزنید.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.7,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              if (senders.isNotEmpty)
                for (final UiSender sender in senders)
                  _SenderTile(
                    sender: sender,
                    enabled: sender.enabled,
                    onChanged: (v) {
                      final entity = state.senders.firstWhere(
                        (s) => s.number == sender.number,
                      );
                      context.read<FinanceBloc>().add(
                        FinanceSenderToggled(sender: entity, enabled: v),
                      );
                    },
                    onDelete: () => context.read<FinanceBloc>().add(
                      FinanceSenderDeleted(sender.number),
                    ),
                  ),
            ],
          ),
          Positioned(
            left: 20,
            bottom: 102,
            child: GlassButton.custom(
              useOwnLayer: true,
              height: 52,
              shape: const LiquidRoundedSuperellipse(borderRadius: 26),
              tintColor: scheme.primary.withValues(alpha: 0.24),
              glowColor: scheme.primary.withValues(alpha: 0.35),
              label: 'افزودن سرشماره',
              onTap: () => showAddSenderSheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 22, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'افزودن سرشماره',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SenderTile extends StatelessWidget {
  const _SenderTile({
    required this.sender,
    required this.enabled,
    required this.onChanged,
    required this.onDelete,
  });

  final UiSender sender;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return SiahehGlassCard(
      radius: 20,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          BankLogo(bankKey: sender.bank.key, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sender.bank.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (sender.autoDetected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'خودکار',
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  PersianFormat.digits(sender.number),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  PersianFormat.digits('${sender.messageCount} پیامک بانکی'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'حذف سرشماره',
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 4),
          GlassSwitch(
            useOwnLayer: true,
            quality: GlassQuality.standard,
            value: enabled,
            onChanged: onChanged,
            width: 42,
            height: 21,
            activeColor: scheme.secondary,
            inactiveColor: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.14),
            semanticLabel: sender.bank.name,
          ),
        ],
      ),
    );
  }
}
