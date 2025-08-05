import 'package:SombaTeka/data/model/data_output.dart';
import 'package:SombaTeka/data/model/transaction_model.dart';
import 'package:SombaTeka/utils/api.dart';

class TransactionRepository {
  Future<DataOutput<TransactionModel>> fetchTransactions(
      {required int page}) async {
    Map<String, dynamic> parameters = {
      Api.page: page,
    };

    Map<String, dynamic> response = await Api.get(
        url: Api.getPaymentDetailsApi, queryParameters: parameters);

    List<TransactionModel> transactionList = (response['data']['data'] as List)
        .map((e) => TransactionModel.fromJson(e))
        .toList();

    return DataOutput<TransactionModel>(
        total: response['data']['total'] ?? 0, modelList: transactionList);
  }
}
