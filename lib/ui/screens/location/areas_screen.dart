import 'dart:async';

import 'package:SombaTeka/app/app_theme.dart';
import 'package:SombaTeka/data/cubits/location/fetch_areas_cubit.dart';
import 'package:SombaTeka/data/cubits/system/app_theme_cubit.dart';
import 'package:SombaTeka/data/model/location/area_model.dart';
import 'package:SombaTeka/ui/screens/location/locationHelperWidget.dart';

import 'package:SombaTeka/ui/screens/widgets/errors/no_data_found.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_internet.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/api.dart';
import 'package:SombaTeka/utils/app_icon.dart';
import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AreasScreen extends StatefulWidget {
  final int cityId;
  final String cityName;
  final String countryName;
  final String stateName;
  final String from;
  final double latitude;
  final double longitude;

  const AreasScreen({
    super.key,
    required this.cityId,
    required this.cityName,
    required this.from,
    required this.countryName,
    required this.stateName,
    required this.latitude,
    required this.longitude,
  });

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;

    return MaterialPageRoute(
      builder: (context) => BlocProvider(
          create: (context) => FetchAreasCubit(),
          child: AreasScreen(
            cityId: arguments?['cityId'],
            cityName: arguments?['cityName'],
            countryName: arguments?['countryName'],
            stateName: arguments?['stateName'],
            from: arguments?['from'],
            latitude: arguments?['latitude'],
            longitude: arguments?['longitude'],
          )),
    );
  }

  @override
  AreasScreenState createState() => AreasScreenState();
}

class AreasScreenState extends State<AreasScreen> {
  bool isFocused = false;
  String previousSearchQuery = "";
  TextEditingController searchController = TextEditingController(text: null);
  final ScrollController controller = ScrollController();
  Timer? _searchDelay;

  @override
  void initState() {
    super.initState();
    context
        .read<FetchAreasCubit>()
        .fetchAreas(search: searchController.text, cityId: widget.cityId);
    searchController = TextEditingController();

    searchController.addListener(searchItemListener);
    controller.addListener(pageScrollListen);
  }

  void pageScrollListen() {
    if (controller.isEndReached()) {
      if (context.read<FetchAreasCubit>().hasMoreData()) {
        context.read<FetchAreasCubit>().fetchAreasMore(cityId: widget.cityId);
      }
    }
  }

//this will listen and manage search
  void searchItemListener() {
    _searchDelay?.cancel();
    searchCallAfterDelay();
    setState(() {});
  }

//This will create delay so we don't face rapid api call
  void searchCallAfterDelay() {
    _searchDelay = Timer(const Duration(milliseconds: 500), itemSearch);
  }

  ///This will call api after some delay
  void itemSearch() {
    // if (searchController.text.isNotEmpty) {
    if (previousSearchQuery != searchController.text) {
      context
          .read<FetchAreasCubit>()
          .fetchAreas(search: searchController.text, cityId: widget.cityId);
      previousSearchQuery = searchController.text;
      setState(() {});
    }
    // } else {
    // context.read<SearchItemCubit>().clearSearch();
    // }
  }

  PreferredSizeWidget appBarWidget() {
    return AppBar(
      systemOverlayStyle: UiUtils.getSystemUiOverlayStyle(
          statusBarColor: context.color.backgroundColor, context: context),
      bottom: PreferredSize(
          preferredSize: Size.fromHeight(58),
          child: Container(
              width: double.maxFinite,
              height: 48,
              margin: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                  border: Border.all(
                      width: context.watch<AppThemeCubit>().state.appTheme ==
                              AppTheme.dark
                          ? 0
                          : 1,
                      color:
                          context.color.textLightColor.withValues(alpha: 0.18)),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: context.color.secondaryColor),
              child: TextFormField(
                  controller: searchController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    //OutlineInputBorder()
                    fillColor: Theme.of(context).colorScheme.secondaryColor,
                    hintText:
                        "${"search".translate(context)}\t${"area".translate(context)}",
                    prefixIcon: LocationHelperWidget().setSearchIcon(context),
                    prefixIconConstraints:
                        const BoxConstraints(minHeight: 5, minWidth: 5),
                  ),
                  enableSuggestions: true,
                  onEditingComplete: () {
                    setState(
                      () {
                        isFocused = false;
                      },
                    );
                    FocusScope.of(context).unfocus();
                  },
                  onTap: () {
                    //change prefix icon color to primary
                    setState(() {
                      isFocused = true;
                    });
                  }))),
      automaticallyImplyLeading: false,
      title: CustomText(
        widget.cityName,
        color: context.color.textDefaultColor,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      leading: Material(
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        type: MaterialType.circle,
        child: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: 18.0,
                ),
                child: Directionality(
                  textDirection: Directionality.of(context),
                  child: RotatedBox(
                    quarterTurns:
                        Directionality.of(context) == TextDirection.rtl
                            ? 2
                            : -4,
                    child: UiUtils.getSvg(AppIcons.arrowLeft,
                        fit: BoxFit.none,
                        color: context.color.textDefaultColor),
                  ),
                ))),
      ),
      elevation: context.watch<AppThemeCubit>().state.appTheme == AppTheme.dark
          ? 0
          : 6,
      shadowColor:
          context.watch<AppThemeCubit>().state.appTheme == AppTheme.dark
              ? null
              : context.color.textDefaultColor.withValues(alpha: 0.2),
      backgroundColor: context.color.backgroundColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(),
      body: bodyData(),
      backgroundColor: context.color.backgroundColor,
    );
  }

  Widget bodyData() {
    return searchItemsWidget();
  }

  Widget searchItemsWidget() {
    return BlocBuilder<FetchAreasCubit, FetchAreasState>(
      builder: (context, state) {
        if (state is FetchAreasInProgress) {
          return LocationHelperWidget().shimmerEffect();
        }

        if (state is FetchAreasFailure) {
          if (state.errorMessage is ApiException) {
            if (state.errorMessage == "no-internet") {
              return SingleChildScrollView(
                child: NoInternet(
                  onRetry: () {
                    context.read<FetchAreasCubit>().fetchAreas(
                        search: searchController.text, cityId: widget.cityId);
                  },
                ),
              );
            }
          }

          return Center(child: const SomethingWentWrong());
        }

        if (state is FetchAreasSuccess) {
          if (state.areasModel.isEmpty) {
            return SingleChildScrollView(
              child: NoDataFound(
                onTap: () {
                  context.read<FetchAreasCubit>().fetchAreas(
                      search: searchController.text, cityId: widget.cityId);
                },
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.only(top: 17),
            color: context.color.secondaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocationHelperWidget().firstIndexWidget(
                    context,
                    widget.from,
                    "${"lblall".translate(context)}\t${"area".translate(context)}",
                    "${"allIn".translate(context)}\t${widget.cityName}",
                    noOfPopBeforeResult: 3,
                    fetchHomeCityName: widget.cityName,
                    countryName: widget.countryName,
                    stateName: widget.stateName,
                    cityName: widget.cityName,
                    latitude: widget.latitude,
                    longitude: widget.longitude),
                Expanded(
                  child: ListView.separated(
                    itemCount: state.areasModel.length,
                    padding: EdgeInsets.zero,
                    controller: controller,
                    physics: AlwaysScrollableScrollPhysics(),
                    shrinkWrap: true,
                    separatorBuilder: (context, index) {
                      return  Divider(
                        thickness: 3.5,
                        height: 10,
                        color: context.color.backgroundColor,
                      );
                    },
                    itemBuilder: (context, index) {
                      AreaModel area = state.areasModel[index];

                      return ListTile(
                        onTap: () {
                          if (widget.from == "home") {
                            if (Constant.isDemoModeOn) {
                              LocationHelperWidget().setDefaultLocationValue(
                                  false, true, context);
                            } else {
                              LocationHelperWidget().setDataFromHome(
                                context,
                                cityName: widget.cityName,
                                stateName: widget.stateName,
                                countryName: widget.countryName,
                                areaName: area.name,
                                areaId: area.id,
                                latitude: area.latitude != null
                                    ? double.parse(area.latitude!)
                                    : widget.latitude,
                                longitude: widget.longitude,
                                fetchHomeLatitude: area.latitude != null
                                    ? double.parse(area.latitude!)
                                    : widget.latitude,
                                fetchHomeLongitude: area.longitude != null
                                    ? double.parse(area.longitude!)
                                    : widget.longitude,
                              );
                            }
                          } else if (widget.from == "location") {
                            if (Constant.isDemoModeOn) {
                              LocationHelperWidget().setDefaultLocationValue(
                                  false, false, context,
                                  killToMain: true);
                            } else {
                              LocationHelperWidget().setDataFromLocation(
                                context,
                                areaName: area.name,
                                areaId: area.id,
                                cityName: widget.cityName,
                                stateName: widget.stateName,
                                countryName: widget.countryName,
                                latitude: widget.latitude,
                                longitude: widget.longitude,
                              );
                            }
                          } else {
                            LocationHelperWidget().setResult(context,
                                areaId: area.id,
                                areaName: area.name,
                                countryName: widget.countryName,
                                stateName: widget.stateName,
                                cityName: widget.cityName,
                                latitude: widget.latitude,
                                longitude: widget.longitude,
                                noOfPopBeforeResult: 3);
                          }
                        },
                        title: CustomText(
                          area.name!,
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          color: context.color.textDefaultColor,
                          fontSize: context.font.normal,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                if (state.isLoadingMore)
                  Center(
                    child: UiUtils.progress(
                      normalProgressColor: context.color.territoryColor,
                    ),
                  )
              ],
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget setSuffixIcon() {
    return GestureDetector(
      onTap: () {
        searchController.clear();
        isFocused = false; //set icon color to black back
        FocusScope.of(context).unfocus(); //dismiss keyboard
        setState(() {});
      },
      child: Icon(
        Icons.close_rounded,
        color: Theme.of(context).colorScheme.blackColor,
        size: 30,
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
