import 'dart:async';
import 'package:SombaTeka/app/app_theme.dart';
import 'package:SombaTeka/app/routes.dart';
import 'package:SombaTeka/data/cubits/location/fetch_countries_cubit.dart';
import 'package:SombaTeka/data/cubits/location/fetch_free_api_location_cubit.dart';
import 'package:SombaTeka/data/cubits/location/fetch_paid_api_location_cubit.dart';
import 'package:SombaTeka/data/cubits/system/app_theme_cubit.dart';
import 'package:SombaTeka/data/model/location/countries_model.dart';
import 'package:SombaTeka/ui/screens/location/locationHelperWidget.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_data_found.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_internet.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/app_icon.dart';
import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/hive_keys.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';

class CountriesScreen extends StatefulWidget {
  final String from;

  const CountriesScreen({
    super.key,
    required this.from,
  });

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;

    return MaterialPageRoute(
      builder: (context) => BlocProvider(
          create: (context) => FetchCountriesCubit(),
          child: CountriesScreen(
            from: arguments!['from'] ?? "",
          )),
    );
  }

  @override
  CountriesScreenState createState() => CountriesScreenState();
}

class CountriesScreenState
    extends State<CountriesScreen> {
  bool isFocused = false;
  String previousSearchQuery = "";
  TextEditingController searchController = TextEditingController(text: null);
  final ScrollController controller = ScrollController();
  Timer? _searchDelay;


  @override
  void initState() {
    super.initState();
    context
        .read<FetchCountriesCubit>()
        .fetchCountries(search: searchController.text);

    searchController = TextEditingController();

    searchController.addListener(searchItemListener);
    controller.addListener(pageScrollListen);
  }


  void pageScrollListen() {
    if (controller.isEndReached()) {
      if (context.read<FetchCountriesCubit>().hasMoreData()) {
        context.read<FetchCountriesCubit>().fetchCountriesMore();
      }
    }
  }

//this will listen and manage search
  void searchItemListener() {
    _searchDelay?.cancel();
    if (searchController.text.length >= 2) {
      searchCallAfterDelay();
    }
    setState(() {});
  }

  void searchCallAfterDelay() {
    _searchDelay = Timer(const Duration(milliseconds: 500), itemSearch);
  }

  void itemSearch() {
    if (previousSearchQuery != searchController.text) {
      if (Constant.mapProvider == "free_api") {
        context.read<FreeApiLocationDataCubit>().fetchLocations(
              search: searchController.text,
            );
      } else {
        context.read<PaidApiLocationDataCubit>().fetchPaidApiLocations(
              search: searchController.text,
            );
      }
      previousSearchQuery = searchController.text;
      setState(() {});
    }
  }

  PreferredSizeWidget appBarWidget(List<CountriesModel> countriesModel) {
    return AppBar(
      systemOverlayStyle: UiUtils.getSystemUiOverlayStyle(
          context: context, statusBarColor: context.color.secondaryColor),
      bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                    width: double.maxFinite,
                    height: 48,
                    margin: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    alignment: AlignmentDirectional.center,
                    decoration: BoxDecoration(
                        border: Border.all(
                            width:
                                context.watch<AppThemeCubit>().state.appTheme ==
                                        AppTheme.dark
                                    ? 0
                                    : 1,
                            color: context.color.textLightColor
                                .withValues(alpha: 0.18)),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        color: context.color.secondaryColor),
                    child: TextFormField(
                        controller: searchController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          //OutlineInputBorder()
                          fillColor:
                              Theme.of(context).colorScheme.secondaryColor,
                          hintText:
                              "${"search".translate(context)}\t${"country".translate(context)}",
                          prefixIcon:
                              LocationHelperWidget().setSearchIcon(context),
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
                        })),
              ),
            ],
          )),
      automaticallyImplyLeading: false,
      title: CustomText(
        "locationLbl".translate(context),
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
      backgroundColor: context.color.secondaryColor,
      actions: [
        if (widget.from != "addItem")
          Padding(
            padding: EdgeInsetsDirectional.only(end: 8.0),
            child: TextButton(
                onPressed: () {
                  HiveUtils.clearLocation();
                  LocationHelperWidget().setDataFromHome(context);
                },
                child: CustomText(
                  "reset".translate(context),
                  fontSize: 16,
                  color: context.color.textDefaultColor.withValues(alpha: 0.6),
                )),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchCountriesCubit, FetchCountriesState>(
        builder: (context, state) {
      List<CountriesModel> countriesModel = [];
      if (state is FetchCountriesSuccess) {
        countriesModel = state.countriesModel;
      }
      return Scaffold(
        appBar: appBarWidget(countriesModel),
        body: bodyData(),
        backgroundColor: context.color.backgroundColor,
      );
    });
  }

  Widget bodyData() {
    return searchItemsWidget();
  }


  Widget selectedLocation() {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, Routes.nearbyLocationScreen,
            arguments: {"from": widget.from});
      },
      child: Container(
        margin: EdgeInsets.only(top: 20),
        padding: EdgeInsets.only(top: 5),
        color: context.color.secondaryColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                spacing: 13,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    color: context.color.territoryColor,
                  ),
                  Expanded(
                    child: Column(
                      spacing: 3,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          "selectedLocation".translate(context),
                          color: context.color.territoryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        ValueListenableBuilder(
                            valueListenable:
                                Hive.box(HiveKeys.userDetailsBox).listenable(),
                            builder: (context, value, child) {
                              return LocationHelperWidget()
                                  .selectedDefaultLocation();
                            })
                      ],
                    ),
                  ),
                  Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: context.color.territoryColor
                              .withValues(alpha: 0.1)),
                      child: Icon(
                        Icons.chevron_right_outlined,
                        color: context.color.territoryColor,
                      )),
                ],
              ),
            ),
            Divider(
              thickness: 12,
              height: 10,
              color: context.color.backgroundColor,
            ),
          ],
        ),
      ),
    );
  }

  String _formatLocationLine(List<String?> parts) {
    return parts
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(', ');
  }

  Widget searchItemsWidget() {
    return Stack(
      children: [
        Column(
          children: [
            if (widget.from != "addItem") selectedLocation(),
            Expanded(
              child: BlocBuilder<FetchCountriesCubit, FetchCountriesState>(
                builder: (context, state) {
                  if (state is FetchCountriesInProgress) {
                    return LocationHelperWidget().shimmerEffect();
                  }

                  if (state is FetchCountriesFailure) {
                    if (state.errorMessage == "no-internet") {
                      return SingleChildScrollView(
                        child: NoInternet(
                          onRetry: () {
                            context
                                .read<FetchCountriesCubit>()
                                .fetchCountries(search: searchController.text);
                          },
                        ),
                      );
                    }
                    return Center(child: const SomethingWentWrong());
                  }

                  if (state is FetchCountriesSuccess) {
                    if (state.countriesModel.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(child: NoDataFound()),
                      );
                    }

                    return Container(
                      width: double.infinity,
                      color: context.color.secondaryColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LocationHelperWidget().firstIndexWidget(
                            context,
                            widget.from,
                            "${"chooseLbl".translate(context)}\t${"country".translate(context)}",
                            "${"lblall".translate(context)}\t${"countriesLbl".translate(context)}",
                            noOfPopBeforeResult: 0,
                          ),
                          Flexible(
                            child: ListView.separated(
                              controller: controller,
                              itemCount: state.countriesModel.length,
                              padding: EdgeInsets.zero,
                              physics: AlwaysScrollableScrollPhysics(),
                              separatorBuilder: (context, index) => Divider(
                                thickness: 3.5,
                                height: 10,
                                color: context.color.backgroundColor,
                              ),
                              itemBuilder: (context, index) {
                                final country = state.countriesModel[index];
                                return ListTile(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.statesScreen,
                                      arguments: {
                                        "countryId": country.id!,
                                        "countryName": country.name!,
                                        "latitude": country.latitude,
                                        "longitude": country.longitude,
                                        "from": widget.from
                                      },
                                    );
                                  },
                                  title: CustomText(
                                    country.name!,
                                    textAlign: TextAlign.start,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    color: context.color.textDefaultColor,
                                    fontSize: context.font.normal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  trailing: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: context.color.textLightColor
                                          .withValues(alpha: 0.1),
                                    ),
                                    child: Icon(
                                      Icons.chevron_right_outlined,
                                      color: context.color.textDefaultColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (state.isLoadingMore)
                            Center(
                              child: UiUtils.progress(
                                normalProgressColor:
                                    context.color.territoryColor,
                              ),
                            )
                        ],
                      ),
                    );
                  }

                  return SizedBox.shrink();
                },
              ),
            ),
          ],
        ),

        /// 🔽 Suggestion Overlay
        if (searchController.text.length >= 2)
          Positioned(
            top: 7, // Adjust as needed (below selectedLocation)
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                    minHeight: 50.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: Constant.mapProvider == "free_api"
                      ? BlocBuilder<FreeApiLocationDataCubit,
                          FreeApiLocationState>(
                          builder: (context, state) {
                            if (state is FreeApiLocationSuccess) {
                              if (state.locations.isNotEmpty) {
                                return ListView.separated(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  itemCount: state.locations.length,
                                  shrinkWrap: true,
                                  physics: AlwaysScrollableScrollPhysics(),
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: context.color.backgroundColor,
                                  ),
                                  itemBuilder: (context, index) {
                                    final location = state.locations[index];
                                    return ListTile(
                                      title: CustomText(
                                        _formatLocationLine([
                                          location.area,
                                          location.city,
                                        ]),
                                        color: context.color.textDefaultColor,
                                      ),
                                      subtitle: CustomText(
                                        _formatLocationLine([
                                          location.state,
                                          location.country,
                                        ]),
                                        color: context.color.textLightColor,
                                      ),
                                      onTap: () {
                                        if (widget.from == "home") {
                                          if (Constant.isDemoModeOn) {
                                            LocationHelperWidget()
                                                .setDefaultLocationValue(
                                                    false, true, context);
                                          } else {
                                            double? lat = double.tryParse(
                                                location.latitude ?? '');
                                            double? lng = double.tryParse(
                                                location.longitude ?? '');

                                            LocationHelperWidget()
                                                .setDataFromHome(context,
                                                    areaName: location.area,
                                                    cityName: location.city,
                                                    stateName: location.state,
                                                    countryName:
                                                        location.country,
                                                    latitude: lat,
                                                    longitude: lng,
                                                    fetchHomeCityName:
                                                        location.city,
                                                    fetchHomeStateName:
                                                        location.state,
                                                    fetchHomeCountryName:
                                                        location.country);
                                          }
                                        } else if (widget.from == "location") {
                                          if (Constant.isDemoModeOn) {
                                            LocationHelperWidget()
                                                .setDefaultLocationValue(
                                                    false, false, context,
                                                    killToMain: true);
                                          } else {
                                            LocationHelperWidget()
                                                .setDataFromLocation(
                                              context,
                                              areaName: location.area,
                                              cityName: location.city,
                                              stateName: location.state,
                                              countryName: location.country,
                                              latitude: double.parse(
                                                  location.latitude!),
                                              longitude: double.parse(
                                                  location.longitude!),
                                            );
                                          }
                                        } else {
                                          LocationHelperWidget().setResult(
                                              context,
                                              areaName: location.area,
                                              cityName: location.city,
                                              stateName: location.state,
                                              countryName: location.country,
                                              latitude: double.parse(
                                                  location.latitude!),
                                              longitude: double.parse(
                                                  location.longitude!),
                                              noOfPopBeforeResult: 0);
                                        }
                                      },
                                    );
                                  },
                                );
                              } else {
                                return Center(
                                    child: SingleChildScrollView(
                                        child: NoDataFound(
                                  height: 100,
                                  mainMsgStyle: context.font.larger,
                                  subMsgStyle: context.font.large,
                                )));
                              }
                            }
                            if (state is FreeApiLocationLoading) {
                              return LocationHelperWidget().shimmerEffect();
                            }

                            if (state is FreeApiLocationFailure) {
                              if (state.errorMessage == "no-internet") {
                                return SingleChildScrollView(
                                  child: NoInternet(
                                    onRetry: () {
                                      context
                                          .read<FetchCountriesCubit>()
                                          .fetchCountries(
                                              search: searchController.text);
                                    },
                                  ),
                                );
                              }
                              return Center(
                                  child: SingleChildScrollView(
                                      child: NoDataFound(
                                height: 100,
                                mainMsgStyle: context.font.larger,
                                subMsgStyle: context.font.large,
                                mainMessage: state.errorMessage.toString(),
                              )));
                            }

                            return SizedBox.shrink();
                          },
                        )
                      : BlocBuilder<PaidApiLocationDataCubit,
                          PaidApiLocationState>(
                          builder: (context, state) {
                            if (state is PaidApiLocationSuccess) {
                              if (state.locations.isNotEmpty) {
                                return ListView.separated(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  itemCount: state.locations.length,
                                  physics: AlwaysScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: context.color.backgroundColor,
                                  ),
                                  itemBuilder: (context, index) {
                                    final location = state.locations[index];
                                    return ListTile(
                                      title: CustomText(
                                        _formatLocationLine([
                                          location.sublocality,
                                          location.locality,
                                          location.state,
                                          location.country,
                                        ]),
                                        color: context.color.textDefaultColor,
                                      ),
                                      onTap: () {
                                        if (widget.from == "home") {
                                          if (Constant.isDemoModeOn) {
                                            LocationHelperWidget()
                                                .setDefaultLocationValue(
                                                    false, true, context);
                                          } else {
                                            LocationHelperWidget()
                                                .setDataFromHome(
                                              context,
                                              areaName: location.sublocality,
                                              cityName: location.locality,
                                              stateName: location.state,
                                              countryName: location.country,
                                              latitude: location.lat,
                                              longitude: location.lng,
                                              fetchHomeCityName:
                                                  location.locality,
                                              fetchHomeStateName:
                                                  location.state,
                                              fetchHomeCountryName:
                                                  location.country,
                                            );
                                          }
                                        } else if (widget.from == "location") {
                                          if (Constant.isDemoModeOn) {
                                            LocationHelperWidget()
                                                .setDefaultLocationValue(
                                                    false, false, context,
                                                    killToMain: true);
                                          } else {
                                            LocationHelperWidget()
                                                .setDataFromLocation(
                                              context,
                                              countryName: location.country,
                                              stateName: location.state,
                                              cityName: location.locality,
                                              latitude: location.lat,
                                              longitude: location.lng,
                                              areaName: location.sublocality,
                                            );
                                          }
                                        } else {
                                          LocationHelperWidget().setResult(
                                              context,
                                              countryName: location.country,
                                              stateName: location.state,
                                              cityName: location.locality,
                                              latitude: location.lat,
                                              longitude: location.lng,
                                              areaName: location.sublocality,
                                              noOfPopBeforeResult: 0);
                                        }
                                      },
                                    );
                                  },
                                );
                              } else {
                                return Center(
                                    child: SingleChildScrollView(
                                        child: NoDataFound(
                                  height: 100,
                                  mainMsgStyle: context.font.larger,
                                  subMsgStyle: context.font.large,
                                )));
                              }
                            }
                            if (state is PaidApiLocationLoading) {
                              return LocationHelperWidget().shimmerEffect();
                            }

                            if (state is PaidApiLocationFailure) {
                              if (state.errorMessage == "no-internet") {
                                return SingleChildScrollView(
                                  child: NoInternet(
                                    onRetry: () {
                                      context
                                          .read<FetchCountriesCubit>()
                                          .fetchCountries(
                                              search: searchController.text);
                                    },
                                  ),
                                );
                              }
                              return Center(
                                  child: SingleChildScrollView(
                                      child: NoDataFound(
                                height: 100,
                                mainMsgStyle: context.font.larger,
                                subMsgStyle: context.font.large,
                                mainMessage: state.errorMessage.toString(),
                              )));
                            }

                            return SizedBox.shrink();
                          },
                        ),
                ),
              ),
            ),
          ),
      ],
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
