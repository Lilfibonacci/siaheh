import 'package:flutter/material.dart';
import 'package:siaheh/presentation/mock/mock_data.dart';
import 'package:siaheh/presentation/mock/ui_models.dart';
import 'package:siaheh/presentation/widgets/bank_logo.dart';

/// Bottom sheet to register an SMS sender number as a bank (UI only).
Future<void> showAddSenderSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AddSenderSheet(),
  );
}

class _AddSenderSheet extends StatefulWidget {
  const _AddSenderSheet();

  @override
  State<_AddSenderSheet> createState() => _AddSenderSheetState();
}

class _AddSenderSheetState extends State<_AddSenderSheet> {
  UiBank? _bank;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('افزودن سرشماره بانک', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'شماره‌ای که بانک از آن برای شما پیامک می‌فرستد را وارد کنید.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'سرشماره',
                hintText: '+98 3000 xxxx',
                prefixIcon: Icon(Icons.sms_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('بانک', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final UiBank b in MockData.banks)
                  ChoiceChip(
                    selected: _bank == b,
                    onSelected: (_) => setState(() => _bank = b),
                    avatar: BankLogo(bankKey: b.key, size: 24),
                    label: Text(b.name),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );
  }
}
