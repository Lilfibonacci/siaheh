import 'package:flutter/material.dart';
import 'package:siaheh/core/utils/persian_format.dart';
import 'package:siaheh/presentation/mock/mock_data.dart';
import 'package:siaheh/presentation/mock/ui_models.dart';
import 'package:siaheh/presentation/widgets/add_sender_sheet.dart';
import 'package:siaheh/presentation/widgets/bank_logo.dart';

class SendersTab extends StatefulWidget {
  const SendersTab({super.key});

  @override
  State<SendersTab> createState() => _SendersTabState();
}

class _SendersTabState extends State<SendersTab> {
  late final List<bool> _enabled = MockData.senders.map((s) => s.enabled).toList();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Text('منابع پیامک', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'فقط پیامک فرستنده‌های فعال ذخیره می‌شود. همه‌ی پردازش‌ها روی گوشی شما انجام می‌شود.',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < MockData.senders.length; i++)
                _SenderTile(
                  sender: MockData.senders[i],
                  enabled: _enabled[i],
                  onChanged: (v) => setState(() => _enabled[i] = v),
                ),
            ],
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              onPressed: () => showAddSenderSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('افزودن سرشماره'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SenderTile extends StatelessWidget {
  const _SenderTile({required this.sender, required this.enabled, required this.onChanged});

  final UiSender sender;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          BankLogo(bankKey: sender.bank.key, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sender.bank.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  PersianFormat.digits(sender.number),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.55)),
                ),
                Text(
                  PersianFormat.digits('${sender.messageCount} پیامک در صندوق'),
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}
