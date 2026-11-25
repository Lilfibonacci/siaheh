import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:siaheh/core/theme/siaheh_glass.dart';
import 'package:siaheh/domain/entities/sms_sender.dart';
import 'package:siaheh/presentation/bloc/finance/finance_bloc.dart';
import 'package:siaheh/presentation/bloc/finance/finance_event.dart';
import 'package:siaheh/core/utils/bank_icon_resolver.dart';
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
    final ColorScheme scheme = theme.colorScheme;
    final bool canSubmit = _number.text.trim().isNotEmpty && _bankKey != null;

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
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'سرشماره یا شناسه فرستنده',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          GlassInteractionSilence(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: GlassTextField(
                controller: _number,
                useOwnLayer: true,
                quality: GlassQuality.standard,
                settings: SiahehGlass.inputSettings(theme.brightness),
                shape: const LiquidRoundedSuperellipse(borderRadius: 16),
                keyboardType: TextInputType.text,
                placeholder: 'BluBank / +9830007100',
                selectionControls: materialTextSelectionHandleControls,
                onChanged: (_) => setState(() {}),
                prefixIcon: Icon(
                  Icons.sms_outlined,
                  size: 20,
                  color: scheme.primary,
                ),
                textStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                ),
                placeholderStyle: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'نام بانک',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          GlassInteractionSilence(
            child: GlassTextField(
              controller: _bankName,
              useOwnLayer: true,
              quality: GlassQuality.standard,
              settings: SiahehGlass.inputSettings(theme.brightness),
              shape: const LiquidRoundedSuperellipse(borderRadius: 16),
              textInputAction: TextInputAction.done,
              placeholder: 'مثلاً ملی، ملت، بلوبانک، پاسارگاد',
              selectionControls: materialTextSelectionHandleControls,
              onChanged: (v) =>
                  setState(() => _bankKey = BankIconResolver.resolve(v)),
              prefixIcon: _bankKey == null
                  ? Icon(
                      Icons.account_balance_rounded,
                      size: 20,
                      color: scheme.primary,
                    )
                  : BankLogo(
                      key: ValueKey(_bankKey),
                      bankKey: _bankKey!,
                      size: 26,
                    ),
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
              placeholderStyle: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.48),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SiahehPrimaryGlassButton(
            label: 'افزودن',
            enabled: canSubmit,
            height: 50,
            onTap: () {
              if (!canSubmit) return;
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
          ),
        ],
      ),
    );
  }
}
