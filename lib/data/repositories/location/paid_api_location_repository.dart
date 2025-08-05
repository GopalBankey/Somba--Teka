import 'package:SombaTeka/utils/api.dart';

class PaidApiLocationRepository {
  Future<Map<String, dynamic>> fetchPredictionResults({
    required String search,
  }) async {
    Map<String, dynamic> parameters = {
      Api.search: search,
    };

    Map<String, dynamic> response = await Api.get(
      url: Api.getLocationApi,
      queryParameters: parameters,
    );


    return response['data'] ?? {};
  }

  Future<Map<String, dynamic>> fetchPlaceDetail({
    String? placeId,
    double? lat,
    double? lng,
  }) async {
    Map<String, dynamic> parameters = {'lang': 'en'};

    if (placeId != null && placeId.isNotEmpty) {
      parameters['place_id'] = placeId;
    } else if (lat != null && lng != null) {
      parameters['lat'] = lat;
      parameters['lng'] = lng;
    } else {
      throw Exception('Either placeId or lat/lng must be provided');
    }
    Map<String, dynamic> response = await Api.get(
      url: Api.getLocationApi,
      queryParameters: parameters,
      //useBaseUrl: false, // Usually external APIs like Google Places
    );

    return response['data']['results'][0];
  }
}
