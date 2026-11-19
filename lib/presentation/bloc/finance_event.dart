import 'package:equatable/equatable.dart';
import 'package:siaheh/features/sms/domain/entities/bank_sms_message.dart';
import 'package:siaheh/features/sms/domain/entities/bank_transaction.dart';
import 'package:siaheh/features/sms/domain/entities/sms_sender.dart';

/// All events handled by [FinanceBloc].
sealed class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

/// Initial app startup: loads cached data, checks SMS permission, syncs, and
/// attaches foreground incoming SMS listener.
final class FinanceStarted extends FinanceEvent {
  const FinanceStarted();
}

/// Dispatched when the app returns to the foreground (runs a fast incremental
/// sync to catch SMS received while the app was backgrounded/closed).
final class FinanceAppResumed extends FinanceEvent {
  const FinanceAppResumed();
}

/// Requests runtime SMS permission from Android.
final class FinancePermissionRequested extends FinanceEvent {
  const FinancePermissionRequested();
}

/// Syncs SMS inbox. Set [fullRescan] to `true` to re-scan the entire inbox
/// instead of only messages newer than the last sync cursor.
final class FinanceSyncRequested extends FinanceEvent {
  const FinanceSyncRequested({this.fullRescan = false});

  final bool fullRescan;

  @override
  List<Object?> get props => [fullRescan];
}

/// Internal event triggered when a new bank SMS arrives while the app is open.
final class FinanceIncomingSmsReceived extends FinanceEvent {
  const FinanceIncomingSmsReceived(this.message);

  final BankSmsMessage message;

  @override
  List<Object?> get props => [message];
}

/// User manually adds a bank sender (numeric shortcode or alphanumeric ID).
final class FinanceSenderAdded extends FinanceEvent {
  const FinanceSenderAdded(this.sender);

  final SmsSender sender;

  @override
  List<Object?> get props => [sender];
}

/// User enables or disables a tracked bank sender.
final class FinanceSenderToggled extends FinanceEvent {
  const FinanceSenderToggled({required this.sender, required this.enabled});

  final SmsSender sender;
  final bool enabled;

  @override
  List<Object?> get props => [sender, enabled];
}

/// User removes a sender from the tracked list.
final class FinanceSenderDeleted extends FinanceEvent {
  const FinanceSenderDeleted(this.number);

  final String number;

  @override
  List<Object?> get props => [number];
}

/// User edits a parsed transaction (type, amount, title, category).
final class FinanceTransactionUpdated extends FinanceEvent {
  const FinanceTransactionUpdated(this.transaction);

  final BankTransaction transaction;

  @override
  List<Object?> get props => [transaction];
}

/// User deletes a parsed transaction.
final class FinanceTransactionDeleted extends FinanceEvent {
  const FinanceTransactionDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
