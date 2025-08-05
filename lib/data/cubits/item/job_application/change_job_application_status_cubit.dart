import 'package:SombaTeka/data/repositories/item/job_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ChangeJobApplicationStatusState {}

class ChangeJobApplicationStatusInitial
    extends ChangeJobApplicationStatusState {}

class ChangeJobApplicationStatusInProgress
    extends ChangeJobApplicationStatusState {}

class ChangeJobApplicationStatusSuccess
    extends ChangeJobApplicationStatusState {
  final String message;
  final int id;
  final String status;

  ChangeJobApplicationStatusSuccess(this.message, this.id, this.status);
}

class ChangeJobApplicationStatusFailure
    extends ChangeJobApplicationStatusState {
  final String errorMessage;

  ChangeJobApplicationStatusFailure(this.errorMessage);
}

class ChangeJobApplicationStatusCubit
    extends Cubit<ChangeJobApplicationStatusState> {
  final JobRepository _jobRepository = JobRepository();

  ChangeJobApplicationStatusCubit()
      : super(ChangeJobApplicationStatusInitial());

  Future<void> changeJobApplicationStatus(
      {required int id, required String status}) async {
    try {
      emit(ChangeJobApplicationStatusInProgress());

      await _jobRepository
          .changeJobApplicationStatus(jobId: id, status: status)
          .then((value) {
        emit(ChangeJobApplicationStatusSuccess(value["message"], id, status));
      });
    } catch (e) {
      emit(ChangeJobApplicationStatusFailure(e.toString()));
    }
  }
}
