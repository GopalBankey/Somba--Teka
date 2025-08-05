import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:SombaTeka/data/model/location/paid_api_location_model.dart';
import 'package:SombaTeka/data/repositories/location/paid_api_location_repository.dart';

abstract class PaidApiLocationState {}

class PaidApiLocationInitial extends PaidApiLocationState {}

class PaidApiLocationLoading extends PaidApiLocationState {}

class PaidApiLocationSuccess extends PaidApiLocationState {
  final List<PaidAPILocationModel> locations;

  PaidApiLocationSuccess({required this.locations});
}

class PaidApiLocationFailure extends PaidApiLocationState {
  final String errorMessage;

  PaidApiLocationFailure(this.errorMessage);
}

class PaidApiLocationDataCubit extends Cubit<PaidApiLocationState> {
  PaidApiLocationDataCubit() : super(PaidApiLocationInitial());

  final PaidApiLocationRepository _repository = PaidApiLocationRepository();

  Future<void> fetchPaidApiLocations({
    String? search,
    String? placeId,
    double? lat,
    double? lng,
  }) async {
    emit(PaidApiLocationLoading());

    try {
      if (search != null && search.isNotEmpty) {
        final predictionJson =
            await _repository.fetchPredictionResults(search: search);

        final List predictions = (predictionJson['predictions'] as List?) ?? [];

        List<PaidAPILocationModel> results = predictions
            .map((json) => PaidAPILocationModel.fromPrediction(
                json as Map<String, dynamic>))
            .toList();

        emit(PaidApiLocationSuccess(locations: results));
      } else if ((placeId != null && placeId.isNotEmpty) ||
          (lat != null && lng != null)) {
        final Map<String, dynamic> resultJson =
            await _repository.fetchPlaceDetail(
          placeId: placeId,
          lat: lat,
          lng: lng,
        );

        final result = PaidAPILocationModel.fromResult(resultJson);

        emit(PaidApiLocationSuccess(locations: [result]));
      } else {

        emit(PaidApiLocationFailure(
            "Invalid input: provide search or placeId/lat/lng"));
      }
    } catch (e) {
      emit(PaidApiLocationFailure(e.toString()));
    }
  }
}
