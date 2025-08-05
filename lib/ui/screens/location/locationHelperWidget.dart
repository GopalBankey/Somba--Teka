import 'package:SombaTeka/app/routes.dart';
import 'package:SombaTeka/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:SombaTeka/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/app_icon.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/helper_utils.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class LocationHelperWidget {
  Widget shimmerEffect() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 15,
      separatorBuilder: (context, index) {
        return Container();
      },
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
          highlightColor: Theme.of(context).colorScheme.shimmerHighlightColor,
          child: Container(
            padding: EdgeInsets.all(5),
            width: double.maxFinite,
            height: 56,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color:
                        context.color.textLightColor.withValues(alpha: 0.18))),
          ),
        );
      },
    );
  }

  Widget setSearchIcon(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: UiUtils.getSvg(AppIcons.search,
            color: context.color.territoryColor));
  }

  Widget firstIndexWidget(BuildContext context, String from,
      String addItemTitle, String nonAddItemTitle,
      {String? countryName,
      String? stateName,
      String? cityName,
      double? latitude,
      double? longitude,
      String? fetchHomeCityName,
      String? fetchHomeCountryName,
      String? fetchHomeStateName,
      int? noOfPopBeforeResult = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        from == "addItem"
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: CustomText(
                  addItemTitle,
                  //textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  color: context.color.textDefaultColor,
                  fontSize: context.font.normal,
                  fontWeight: FontWeight.w600,
                ),
              )
            : InkWell(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  child: Row(
                    children: [
                      CustomText(
                        nonAddItemTitle,
                        //textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        color: context.color.textDefaultColor,
                        fontSize: context.font.normal,
                        fontWeight: FontWeight.w600,
                      ),
                      Spacer(),
                      Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: context.color.textLightColor
                                  .withValues(alpha: 0.1)),
                          child: Icon(
                            Icons.chevron_right_outlined,
                            color: context.color.textDefaultColor,
                          )),
                    ],
                  ),
                ),
                onTap: () {
                  if (from == "home") {
                    setDataFromHome(context,
                        countryName: countryName,
                        stateName: stateName,
                        cityName: cityName,
                        latitude: latitude,
                        longitude: longitude,
                        fetchHomeCityName: fetchHomeCityName,
                        fetchHomeCountryName: fetchHomeCountryName,
                        fetchHomeStateName: fetchHomeStateName);
                  } else if (from == "location") {
                    setDataFromLocation(context,
                        countryName: countryName,
                        stateName: stateName,
                        cityName: cityName,
                        latitude: latitude,
                        longitude: longitude);
                  } else {
                    setResult(context,
                        stateName: stateName,
                        countryName: countryName,
                        cityName: cityName,
                        latitude: latitude,
                        longitude: longitude,
                        noOfPopBeforeResult: noOfPopBeforeResult);
                  }
                },
              ),
        Divider(
          thickness: 3.5,
          height: 10,
          color: context.color.backgroundColor,
        ),
      ],
    );
  }

  void setDataFromLocation(BuildContext context,
      {String? countryName,
      String? stateName,
      String? cityName,
      double? latitude,
      double? longitude,
      String? areaName,
      int? radius,
      int? areaId}) {
    HiveUtils.setLocation(
        area: areaName,
        areaId: areaId,
        country: countryName,
        state: stateName,
        city: cityName,
        latitude: latitude,
        longitude: longitude,
        radius: radius);
    HelperUtils.killPreviousPages(context, Routes.main, {"from": "login"});
  }

  void setResult(BuildContext context,
      {dynamic areaId,
      String? areaName,
      String? countryName,
      String? stateName,
      String? cityName,
      double? latitude,
      double? longitude,
      int? radius,
      int? noOfPopBeforeResult = 0}) {
    Map<String, dynamic> result = {
      'area_id': areaId,
      'area': areaName,
      'state': stateName,
      'country': countryName,
      'city': cityName,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius
    };
    if (noOfPopBeforeResult != null && noOfPopBeforeResult > 0) {
      for (int i = 0; i < noOfPopBeforeResult; i++) {
        Navigator.pop(context);
      }
    }
    Navigator.pop(context, result);
  }

  void setDefaultLocationValue(
      bool isCurrent, bool isHomeUpdate, BuildContext context,
      {bool killToMain = false}) {
    UiUtils.setDefaultLocationValue(
        isCurrent: isCurrent, isHomeUpdate: isHomeUpdate, context: context);
    if (killToMain) {
      HelperUtils.killPreviousPages(context, Routes.main, {"from": "login"});
    } else {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void setDataFromHome(BuildContext context,
      {String? countryName,
      String? stateName,
      String? cityName,
      double? latitude,
      double? longitude,
      String? areaName,
      int? radius,
      int? areaId,
      String? fetchHomeCityName,
      String? fetchHomeCountryName,
      String? fetchHomeStateName,
      double? fetchHomeLatitude,
      double? fetchHomeLongitude,
      bool isPopUntil = true}) {
    HiveUtils.setLocation(
        area: areaName,
        areaId: areaId,
        country: countryName,
        state: stateName,
        city: cityName,
        latitude: latitude,
        longitude: longitude,
        radius: radius);

    Future.delayed(
      Duration.zero,
      () {
        context.read<FetchHomeScreenCubit>().fetch(
            city: fetchHomeCityName,
            country: fetchHomeCountryName,
            state: fetchHomeStateName,
            latitude: fetchHomeLatitude,
            longitude: fetchHomeLongitude,
            radius: radius);
        context.read<FetchHomeAllItemsCubit>().fetch(
            city: fetchHomeCityName,
            country: fetchHomeCountryName,
            state: fetchHomeStateName,
            latitude: fetchHomeLatitude,
            longitude: fetchHomeLongitude,
            radius: radius);
      },
    );
    if (isPopUntil) Navigator.popUntil(context, (route) => route.isFirst);
  }

  Widget selectedDefaultLocation() {
    return CustomText(
      [
        HiveUtils.getAreaName(),
        HiveUtils.getCityName(),
        HiveUtils.getStateName(),
        HiveUtils.getCountryName()
      ]
              .where((element) => element != null && element.isNotEmpty)
              .join(", ")
              .isEmpty
          ? "------"
          : [
              HiveUtils.getAreaName(),
              HiveUtils.getCityName(),
              HiveUtils.getStateName(),
              HiveUtils.getCountryName()
            ]
              .where((element) => element != null && element.isNotEmpty)
              .join(", "),
      softWrap: true,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }
}
