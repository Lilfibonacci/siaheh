import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Round bank logo backed by the `persianlabs/icons` SVG set (MIT).
class BankLogo extends StatelessWidget {
  const BankLogo({super.key, required this.bankKey, this.size = 44});

  final String bankKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: SvgPicture.asset(
        'assets/icons/banks/$bankKey.svg',
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const Icon(Icons.account_balance_rounded),
      ),
    );
  }
}
