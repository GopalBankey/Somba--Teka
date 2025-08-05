import 'dart:io';

import 'package:dio/dio.dart';
import 'package:SombaTeka/data/model/data_output.dart';
import 'package:SombaTeka/data/model/item/job_application.dart';
import 'package:SombaTeka/utils/api.dart';
import 'package:path/path.dart' as path;

class JobRepository {
  Future<dynamic> applyJobApplication(
    Map<String, dynamic> data,
    File? attachment,
  ) async {
    Map<String, dynamic> parameters = {};
    parameters.addAll(data);

    if (attachment != null) {
      MultipartFile image = await MultipartFile.fromFile(attachment.path,
          filename: path.basename(attachment.path));
      parameters['resume'] = image;
    }

    Map<String, dynamic> response = await Api.post(
      url: Api.applyForJobApi,
      parameter: parameters,
    );

    return response;
  }

  Future<DataOutput<JobApplication>> fetchApplications(
      {int? page,
      required int itemId,
      required bool isMyJobApplications}) async {
    try {
      Map<String, dynamic> parameters = {
        if (page != null) Api.page: page,
        Api.itemId: itemId,
        
      };

      Map<String, dynamic> response = await Api.get(
        url: isMyJobApplications
            ? Api.myJobApplicationsApi
            : Api.getJobApplicationsApi,
        queryParameters: parameters,
      );
      if ((response['data']['data'] as List).isNotEmpty) {
        List<JobApplication> itemList = (response['data']['data'] as List)
            .map((element) => JobApplication.fromJson(element))
            .toList();

        return DataOutput(total: itemList.length, modelList: itemList);
      } else {
        return DataOutput(total: response['data']['total'] ?? 0, modelList: []);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map> changeJobApplicationStatus(
      {required int jobId, required String status}) async {
    Map response =
        await Api.post(url: Api.updateJobApplicationsStatusApi, parameter: {
      Api.status: status,
      Api.jobId: jobId,
    });
    return response;
  }
}
