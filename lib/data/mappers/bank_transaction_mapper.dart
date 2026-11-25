import 'package:siaheh/data/dtos/bank_transaction_dto.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';

class BankTransactionMapper {
  const BankTransactionMapper._();

  static BankTransaction toEntity(BankTransactionDto dto) => BankTransaction(
    id: dto.id,
    bankKey: dto.bankKey,
    accountNumber: dto.accountNumber,
    senderNumber: dto.senderNumber,
    amountRial: dto.amountRial,
    type: TransactionType.values.byName(dto.type),
    occurredAt: DateTime.fromMillisecondsSinceEpoch(dto.occurredAtMs),
    rawBody: dto.rawBody,
    smsId: dto.smsId,
    balanceRial: dto.balanceRial,
    categoryId: dto.categoryId,
    title: dto.title,
    merchantName: dto.merchantName,
    needsReview: dto.needsReview,
    linkedTransferId: dto.linkedTransferId,
    userEdited: dto.userEdited,
  );

  static BankTransactionDto toDto(BankTransaction entity) =>
      BankTransactionDto(
        id: entity.id,
        bankKey: entity.bankKey,
        accountNumber: entity.accountNumber,
        senderNumber: entity.senderNumber,
        amountRial: entity.amountRial,
        type: entity.type.name,
        occurredAtMs: entity.occurredAt.millisecondsSinceEpoch,
        rawBody: entity.rawBody,
        smsId: entity.smsId,
        balanceRial: entity.balanceRial,
        categoryId: entity.categoryId,
        title: entity.title,
        merchantName: entity.merchantName,
        needsReview: entity.needsReview,
        linkedTransferId: entity.linkedTransferId,
        userEdited: entity.userEdited,
      );
}
