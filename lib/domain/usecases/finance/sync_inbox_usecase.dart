import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:siaheh/core/error/failure.dart';
import 'package:siaheh/domain/usecases/usecase.dart';
import 'package:siaheh/domain/entities/sync_result.dart';
import 'package:siaheh/domain/repositories/sms_repository.dart';

class SyncInboxParams extends Equatable {
  const SyncInboxParams({this.fullRescan = false});

  final bool fullRescan;

  @override
  List<Object?> get props => [fullRescan];
}

class SyncInboxUseCase implements UseCase<SyncResult, SyncInboxParams> {
  const SyncInboxUseCase(this._repository);

  final SmsRepository _repository;

  @override
  Future<Either<Failure, SyncResult>> call(SyncInboxParams params) =>
      _repository.syncInbox(fullRescan: params.fullRescan);
}
