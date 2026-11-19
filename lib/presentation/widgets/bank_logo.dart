import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:siaheh/features/sms/domain/entities/iranian_bank_registry.dart';

/// Round bank logo backed by the `persianlabs/icons` SVG set (MIT),
/// with a safe fallback icon for unknown or unmapped bank keys.
class BankLogo extends StatelessWidget {
  const BankLogo({super.key, required this.bankKey, this.size = 44});

  final String bankKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool hasLogo = IranianBankRegistry.hasLogo(bankKey);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: hasLogo
          ? SvgPicture.asset(
              'assets/icons/banks/$bankKey.svg',
              fit: BoxFit.contain,
              placeholderBuilder: (_) => Icon(
                Icons.account_balance_rounded,
                size: size * 0.52,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Icon(
              Icons.account_balance_rounded,
              size: size * 0.52,
              color: Theme.of(context).colorScheme.primary,
            ),
    );
  }
}
