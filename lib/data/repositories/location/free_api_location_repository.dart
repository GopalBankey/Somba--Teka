import 'package:SombaTeka/data/model/data_output.dart';
import 'package:SombaTeka/data/model/location/free_api_location_model.dart';
import 'package:SombaTeka/utils/api.dart';

class FreeApiLocationRepository {
  Future<DataOutput<FreeAPILocationModel>> fetchLocations({
    String? search,
    double? lat,
    double? long,
  }) async {
    Map<String, dynamic> parameters = {
      if (search != null && search.isNotEmpty) Api.search: search,
      if (lat != null) 'lat': lat,
      if (long != null) 'lng': long,
      'lang': 'en'
    };

    final response = await Api.get(
      url: Api.getLocationApi,
      queryParameters: parameters,
      useBaseUrl: true,
    );

    // Use array if search param was used
    if (search != null && search.isNotEmpty) {
      List<FreeAPILocationModel> modelList = (response['data'] as List)
          .map((e) => FreeAPILocationModel.fromJson(e))
          .toList();

      return DataOutput<FreeAPILocationModel>(
        total: modelList.length,
        modelList: modelList,
      );
    }

    // Otherwise assume single map response (lat/long case)
    final model = FreeAPILocationModel.fromJson(response['data']);
    return DataOutput<FreeAPILocationModel>(
      total: 1,
      modelList: [model],
    );
  }
}
