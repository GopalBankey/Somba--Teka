import 'dart:io';
import 'package:SombaTeka/data/repositories/item/job_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ApplyJobApplicationState {}

class ApplyJobApplicationInitial extends ApplyJobApplicationState {}

class ApplyJobApplicationInProgress extends ApplyJobApplicationState {}

class ApplyJobApplicationSuccess extends ApplyJobApplicationState {
  final String successMessage;
  final dynamic data;

  ApplyJobApplicationSuccess(this.successMessage, this.data);
}

class ApplyJobApplicationFail extends ApplyJobApplicationState {
  final dynamic error;

  ApplyJobApplicationFail(this.error);
}

class ApplyJobApplicationCubit extends Cubit<ApplyJobApplicationState> {
  ApplyJobApplicationCubit() : super(ApplyJobApplicationInitial());
  final JobRepository _jobRepository = JobRepository();

  void applyJobApplication(Map<String, dynamic> data, File? attachment) async {
    try {
      emit(ApplyJobApplicationInProgress());

      dynamic response =
          await _jobRepository.applyJobApplication(data, attachment);
      emit(ApplyJobApplicationSuccess(response['message'], response['data']));
    } catch (e) {
      emit(ApplyJobApplicationFail(e.toString()));
    }
  }
}
