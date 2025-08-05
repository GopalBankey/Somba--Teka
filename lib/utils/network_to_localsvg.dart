import 'package:dio/dio.dart';
import 'package:SombaTeka/utils/hive_keys.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';

class NetworkToLocalSvg {
  Dio dio = Dio();

  Future<String?> convert(String url) async {
    try {
      Response response = await dio.get(url);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw "Error while load svg";
      }
    } catch (e) {
      rethrow;
    }
  }

  Widget svg(String url, {Color? color, double? width, double? height}) {
    return FutureBuilder<String?>(
      future: convert(url),
      builder: (context, AsyncSnapshot<String?> snapshot) {
        String? imgUrl;
        if (Hive.box(HiveKeys.svgBox).containsKey(url) ||
            snapshot.connectionState == ConnectionState.done) {
          if (Hive.box(HiveKeys.svgBox).containsKey(url)) {
            imgUrl = Hive.box(HiveKeys.svgBox).get(url);
          }
          if (imgUrl == null) {
            Hive.box(HiveKeys.svgBox).put(url, snapshot.data);
            imgUrl = snapshot.data;
          }
          return SvgPicture.string(
            imgUrl ?? "",
            colorFilter:
                color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
            width: width,
            height: height,
          );
        } else {
          return Container();
        }
      },
    );
  }
}
