import 'package:siaheh/features/sms/domain/entities/iranian_bank_registry.dart';

/// Resolves a typed (Persian/English) bank name to an icon key in
/// `assets/icons/banks/` using [IranianBankRegistry].
class BankIconResolver {
  const BankIconResolver._();

  static String? resolve(String input) =>
      IranianBankRegistry.matchByName(input, allowPrefixMatch: true)?.key;
}
