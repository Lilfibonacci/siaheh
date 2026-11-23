import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
import 'package:siaheh/features/sms/domain/entities/sms_sender.dart';
import 'package:siaheh/presentation/bloc/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance_event.dart';
import 'package:siaheh/presentation/widgets/bank_icon_resolver.dart';
import 'package:siaheh/presentation/widgets/bank_logo.dart';

/// Liquid Glass bottom sheet to manually register a numeric or alphanumeric
/// bank SMS sender.
Future<void> showAddSenderSheet(BuildContext context) {
  final ThemeData capturedTheme = Theme.of(context);
  final FinanceBloc capturedBloc = context.read<FinanceBloc>();

  return GlassSheet.show<void>(
    context: context,
    settings: SiahehGlass.sheetSettings(capturedTheme.brightness),
    topBorderRadius: 34,
    margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
    isScrollable: true,
    interactionScale: 1.0,
    stretch: 0.12,
    enableInteractionGlow: false,
    enableSaturationGlow: false,
    suppressInteractionOnChildren: true,
    dragIndicatorColor: capturedTheme.colorScheme.onSurface.withValues(
      alpha: 0.28,
    ),
    builder: (_) => BlocProvider.value(
      value: capturedBloc,
      child: Theme(
        data: capturedTheme,
        child: const Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            type: MaterialType.transparency,
            child: _AddSenderSheet(),
          ),
        ),
      ),
    ),
  );
}

class _AddSenderSheet extends StatefulWidget {
  const _AddSenderSheet();

  @override
  State<_AddSenderSheet> createState() => _AddSenderSheetState();
}

class _AddSenderSheetState extends State<_AddSenderSheet> {
  final TextEditingController _number = TextEditingController();
  final TextEditingController _bankName = TextEditingController();
  String? _bankKey;

  @override
  void dispose() {
    _number.dispose();
    _bankName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text('افزودن سرشماره بانک', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'سرشماره عددی (مثلاً +9830007100) یا شناسه حروفی بانک (مثلاً BluBank) را وارد کنید.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _number,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.text,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'سرشماره یا شناسه فرستنده',
                hintText: 'BluBank یا +9830007100',
                prefixIcon: Icon(Icons.sms_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bankName,
              textInputAction: TextInputAction.done,
              onChanged: (v) =>
                  setState(() => _bankKey = BankIconResolver.resolve(v)),
              decoration: InputDecoration(
                labelText: 'نام بانک',
                hintText: 'مثلاً ملی، ملت، بلوبانک، پاسارگاد',
                border: const OutlineInputBorder(),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _bankKey == null
                      ? const Icon(Icons.account_balance_rounded)
                      : BankLogo(
                          key: ValueKey(_bankKey),
                          bankKey: _bankKey!,
                          size: 32,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _number.text.trim().isEmpty || _bankKey == null
                  ? null
                  : () {
                      context.read<FinanceBloc>().add(
                        FinanceSenderAdded(
                          SmsSender(
                            number: _number.text.trim(),
                            bankKey: _bankKey!,
                            autoDetected: false,
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('افزودن'),
            ),
          ],
        ),
      );
  }
}
