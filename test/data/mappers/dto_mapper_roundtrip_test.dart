import 'package:flutter_test/flutter_test.dart';
import 'package:siaheh/data/dtos/bank_sms_message_dto.dart';
import 'package:siaheh/data/dtos/bank_transaction_dto.dart';
import 'package:siaheh/data/dtos/category_rule_dto.dart';
import 'package:siaheh/data/dtos/custom_category_dto.dart';
import 'package:siaheh/data/dtos/sms_sender_dto.dart';
import 'package:siaheh/data/mappers/bank_sms_message_mapper.dart';
import 'package:siaheh/data/mappers/bank_transaction_mapper.dart';
import 'package:siaheh/data/mappers/category_rule_mapper.dart';
import 'package:siaheh/data/mappers/custom_category_mapper.dart';
import 'package:siaheh/data/mappers/sms_sender_mapper.dart';
import 'package:siaheh/data/mappers/theme_preference_mapper.dart';
import 'package:siaheh/domain/entities/app_theme_preference.dart';
import 'package:siaheh/domain/entities/bank_sms_message.dart';
import 'package:siaheh/domain/entities/bank_transaction.dart';
import 'package:siaheh/domain/entities/category_ids.dart';
import 'package:siaheh/domain/entities/category_rule.dart';
import 'package:siaheh/domain/entities/custom_category.dart';
import 'package:siaheh/domain/entities/sms_sender.dart';

void main() {
  test('BankTransaction DTO and Mapper preserve entity and Hive map keys', () {
    final entity = BankTransaction(
      id: 'tx_1',
      bankKey: 'blubank',
      accountNumber: '1234',
      senderNumber: '+9830007100',
      amountRial: 2500000,
      type: TransactionType.expense,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(1760000000000),
      rawBody: 'برداشت ۲۵۰,۰۰۰ تومان',
      smsId: 'tx_1',
      balanceRial: 9000000,
      categoryId: CategoryIds.food,
      title: 'اسنپ‌فود',
      merchantName: 'اسنپ‌فود',
      needsReview: true,
      linkedTransferId: 'tx_2',
      userEdited: true,
    );

    final dto = BankTransactionMapper.toDto(entity);
    final map = dto.toMap();
    expect(map.keys, {
      'id',
      'bankKey',
      'accountNumber',
      'senderNumber',
      'amountRial',
      'type',
      'occurredAt',
      'rawBody',
      'smsId',
      'balanceRial',
      'categoryId',
      'title',
      'merchantName',
      'needsReview',
      'linkedTransferId',
      'userEdited',
    });

    final decoded = BankTransactionMapper.toEntity(
      BankTransactionDto.fromMap(map),
    );
    expect(decoded, entity);
  });

  test('BankSmsMessage DTO and Mapper preserve entity and Hive map keys', () {
    final entity = BankSmsMessage(
      id: 'msg_1',
      senderAddress: 'BluBank',
      bankKey: 'blubank',
      body: 'رمز پویا: ۱۲۳۴۵۶',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(1760000100000),
      kind: BankSmsKind.otp,
      transactionId: null,
    );

    final map = BankSmsMessageMapper.toDto(entity).toMap();
    expect(map.keys, {
      'id',
      'senderAddress',
      'bankKey',
      'body',
      'receivedAt',
      'kind',
      'transactionId',
    });
    expect(
      BankSmsMessageMapper.toEntity(BankSmsMessageDto.fromMap(map)),
      entity,
    );
  });

  test('SmsSender DTO and Mapper preserve entity and Hive map keys', () {
    const entity = SmsSender(
      number: 'BluBank',
      bankKey: 'blubank',
      enabled: false,
      autoDetected: true,
    );

    final map = SmsSenderMapper.toDto(entity).toMap();
    expect(map.keys, {'number', 'bankKey', 'enabled', 'autoDetected'});
    expect(SmsSenderMapper.toEntity(SmsSenderDto.fromMap(map)), entity);
  });

  test('CustomCategory DTO and Mapper preserve entity and Hive map keys', () {
    const entity = CustomCategory(
      name: 'قهوه',
      iconCodePoint: 0xe123,
      colorValue: 0xFF14B8A6,
    );

    final map = CustomCategoryMapper.toDto(entity).toMap();
    expect(map.keys, {'name', 'iconCodePoint', 'colorValue'});
    expect(
      CustomCategoryMapper.toEntity(CustomCategoryDto.fromMap(map)),
      entity,
    );
  });

  test('CategoryRule DTO and Mapper preserve entity and Hive map keys', () {
    const entity = CategoryRule(
      pattern: 'کافه لمیز',
      categoryId: 'قهوه',
      preferredTitle: 'لمیز',
    );

    final map = CategoryRuleMapper.toDto(entity).toMap();
    expect(map.keys, {'pattern', 'categoryId', 'preferredTitle'});
    expect(CategoryRuleMapper.toEntity(CategoryRuleDto.fromMap(map)), entity);
  });

  test('ThemePreferenceMapper maps storage strings cleanly', () {
    expect(
      ThemePreferenceMapper.fromStorageName('light'),
      AppThemePreference.light,
    );
    expect(
      ThemePreferenceMapper.fromStorageName('dark'),
      AppThemePreference.dark,
    );
    expect(
      ThemePreferenceMapper.fromStorageName(null),
      AppThemePreference.system,
    );
    expect(
      ThemePreferenceMapper.toStorageName(AppThemePreference.light),
      'light',
    );
  });
}
