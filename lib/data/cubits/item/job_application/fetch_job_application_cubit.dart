import 'dart:developer';

import 'package:SombaTeka/data/model/data_output.dart';
import 'package:SombaTeka/data/model/item/job_application.dart';
import 'package:SombaTeka/data/repositories/item/job_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FetchJobApplicationState {}

class FetchJobApplicationInitial extends FetchJobApplicationState {}

class FetchJobApplicationInProgress extends FetchJobApplicationState {}

class FetchJobApplicationSuccess extends FetchJobApplicationState {
  final int total;
  final int page;
  final bool isLoadingMore;
  final bool hasError;
  final List<JobApplication> applications;

  FetchJobApplicationSuccess(
      {required this.total,
      required this.page,
      required this.isLoadingMore,
      required this.hasError,
      required this.applications});

  FetchJobApplicationSuccess copyWith({
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? hasError,
    List<JobApplication>? applications,
    bool? getActiveapplications,
  }) {
    return FetchJobApplicationSuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      applications: applications ?? this.applications,
    );
  }
}

class FetchJobApplicationFailed extends FetchJobApplicationState {
  final dynamic error;

  FetchJobApplicationFailed(this.error);
}

class FetchJobApplicationCubit extends Cubit<FetchJobApplicationState> {
  FetchJobApplicationCubit() : super(FetchJobApplicationInitial());
  final JobRepository _jobRepository = JobRepository();

  void fetchApplications(
      {required int itemId, required bool isMyJobApplications}) async {
    try {
      emit(FetchJobApplicationInProgress());
      DataOutput<JobApplication> result =
          await _jobRepository.fetchApplications(
              page: 1,
              itemId: itemId,
              isMyJobApplications: isMyJobApplications);
      emit(FetchJobApplicationSuccess(
        hasError: false,
        isLoadingMore: false,
        page: 1,
        applications: result.modelList,
        total: result.total,
      ));
    } catch (e) {
      emit(FetchJobApplicationFailed(e.toString()));
    }
  }

  JobApplication? getJobAppliedItem(int itemId) {
    if (state is FetchJobApplicationSuccess) {
      List<JobApplication> offerList =
          (state as FetchJobApplicationSuccess).applications;

      int matchingOffer = offerList.indexWhere(
        (offer) => offer.itemId == itemId,
      );
      if (matchingOffer != -1) {
        return (state as FetchJobApplicationSuccess)
            .applications[matchingOffer];
      } else {
        return null;
      }
    }
    return null;
  }

  void addJobApplication(JobApplication item) {
    if (state is! FetchJobApplicationSuccess) return;
    final applications = (state as FetchJobApplicationSuccess).applications;

    applications.insert(0, item);
    emit((state as FetchJobApplicationSuccess)
        .copyWith(applications: applications));
  }

  void edit(JobApplication item) {
    if (state is FetchJobApplicationSuccess) {
      List<JobApplication> applications =
          (state as FetchJobApplicationSuccess).applications;
      log('$state');
      int index = applications.indexWhere((element) {
        log('${element.id} - ${item.id}');
        return element.id == item.id;
      });
      applications[index] = item;
      if (!isClosed) {
        emit((state as FetchJobApplicationSuccess)
            .copyWith(applications: applications));
      }
    }
  }

  Future<void> fetchMyMoreapplications(
      {required int itemId, required bool isMyJobApplications}) async {
    try {
      if (state is FetchJobApplicationSuccess) {
        if ((state as FetchJobApplicationSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchJobApplicationSuccess)
            .copyWith(isLoadingMore: true));

        DataOutput<JobApplication> result =
            await _jobRepository.fetchApplications(
                page: (state as FetchJobApplicationSuccess).page + 1,
                itemId: itemId,
                isMyJobApplications: isMyJobApplications);

        FetchJobApplicationSuccess myapplicationsState =
            (state as FetchJobApplicationSuccess);
        myapplicationsState.applications.addAll(result.modelList);
        emit(
          FetchJobApplicationSuccess(
            isLoadingMore: false,
            hasError: false,
            applications: myapplicationsState.applications,
            page: (state as FetchJobApplicationSuccess).page + 1,
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchJobApplicationSuccess).copyWith(
          isLoadingMore: false,
          hasError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchJobApplicationSuccess) {
      return (state as FetchJobApplicationSuccess).applications.length <
          (state as FetchJobApplicationSuccess).total;
    }
    return false;
  }

  void resetState() {
    emit(FetchJobApplicationInProgress());
  }
}
