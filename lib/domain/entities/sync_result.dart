import 'package:equatable/equatable.dart';

/// Summary of an inbox sync pass.
class SyncResult extends Equatable {
  const SyncResult({
    this.newMessages = 0,
    this.newTransactions = 0,
    this.discoveredSenders = 0,
    this.linkedTransfers = 0,
  });

  final int newMessages;
  final int newTransactions;
  final int discoveredSenders;
  final int linkedTransfers;

  @override
  List<Object?> get props => [
    newMessages,
    newTransactions,
    discoveredSenders,
    linkedTransfers,
  ];
}
