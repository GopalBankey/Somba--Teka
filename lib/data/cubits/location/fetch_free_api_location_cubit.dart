import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:SombaTeka/data/model/location/free_api_location_model.dart';
import 'package:SombaTeka/data/repositories/location/free_api_location_repository.dart';
import 'package:SombaTeka/data/model/data_output.dart';

abstract class FreeApiLocationState {}

class FreeApiLocationInitial extends FreeApiLocationState {}

class FreeApiLocationLoading extends FreeApiLocationState {}

class FreeApiLocationSuccess extends FreeApiLocationState {
  final List<FreeAPILocationModel> locations;

  FreeApiLocationSuccess({required this.locations});
}

class FreeApiLocationFailure extends FreeApiLocationState {
  final String errorMessage;

  FreeApiLocationFailure(this.errorMessage);
}

class FreeApiLocationDataCubit extends Cubit<FreeApiLocationState> {
  FreeApiLocationDataCubit() : super(FreeApiLocationInitial());

  final FreeApiLocationRepository _repository = FreeApiLocationRepository();

  Future<void> fetchLocations({
    String? search,
    double? lat,
    double? long,
  }) async {
    emit(FreeApiLocationLoading());

    try {
      DataOutput<FreeAPILocationModel> result = await _repository
          .fetchLocations(search: search, lat: lat, long: long);
      emit(FreeApiLocationSuccess(locations: result.modelList));
    } catch (e) {
      emit(FreeApiLocationFailure(e.toString()));
    }
  }
}
