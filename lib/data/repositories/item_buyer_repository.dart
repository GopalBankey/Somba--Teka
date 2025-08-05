import 'package:SombaTeka/data/model/data_output.dart';
import 'package:SombaTeka/data/model/user_model.dart';
import 'package:SombaTeka/utils/api.dart';

class ItemBuyerRepository {
  Future<DataOutput<BuyerModel>> fetchItemBuyerList(
      int itemId, bool isJobCategory) async {
    Map<String, dynamic> response = await Api.get(
        url:
            isJobCategory ? Api.getJobApplicationsApi : Api.getItemBuyerListApi,
        queryParameters: {Api.itemId: itemId});
    List<BuyerModel> modelList = [];
    if (isJobCategory) {
      modelList = (response['data']['data'] as List)
          .where((element) => element['status'] != 'rejected')
          .map((element) => BuyerModel.fromJobApplicationJson(element))
          .toList();
    } else {
      modelList = (response['data'] as List).map(
        (e) {
          return BuyerModel.fromJson(e);
        },
      ).toList();
    }

    return DataOutput(total: modelList.length, modelList: modelList);
  }
}
