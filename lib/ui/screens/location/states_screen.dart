import 'dart:async';

import 'package:SombaTeka/app/app_theme.dart';
import 'package:SombaTeka/app/routes.dart';
import 'package:SombaTeka/data/cubits/location/fetch_cities_cubit.dart';
import 'package:SombaTeka/data/cubits/location/fetch_states_cubit.dart';
import 'package:SombaTeka/data/cubits/system/app_theme_cubit.dart';
import 'package:SombaTeka/data/model/location/states_model.dart';
import 'package:SombaTeka/ui/screens/location/locationHelperWidget.dart';

import 'package:SombaTeka/ui/screens/widgets/errors/no_data_found.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_internet.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/api.dart';
import 'package:SombaTeka/utils/app_icon.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatesScreen extends StatefulWidget {
  final int countryId;
  final String countryName;
  final String latitude;
  final String longitude;
  final String from;

  const StatesScreen({
    super.key,
    required this.countryId,
    required this.countryName,
    required this.from,
    required this.latitude,
    required this.longitude,
  });

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;

    return MaterialPageRoute(
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => FetchStatesCubit(),
          ),
        ],
        child: StatesScreen(
          countryId: arguments?['countryId'],
          countryName: arguments?['countryName'],
          from: arguments?['from'],
          latitude: arguments?['latitude'],
          longitude: arguments?['longitude'],
        ),
      ),
    );
  }

  @override
  StatesScreenState createState() => StatesScreenState();
}

class StatesScreenState extends State<StatesScreen> {
  bool isFocused = false;
  String previousSearchQuery = "";
  TextEditingController searchController = TextEditingController(text: null);
  final ScrollController controller = ScrollController();
  Timer? _searchDelay;

  @override
  void initState() {
    super.initState();
    context.read<FetchStatesCubit>().fetchStates(
        search: searchController.text, countryId: widget.countryId);
    searchController = TextEditingController();

    searchController.addListener(searchItemListener);
    controller.addListener(pageScrollListen);
  }

  void pageScrollListen() {
    if (controller.isEndReached()) {
      if (context.read<FetchStatesCubit>().hasMoreData()) {
        context
            .read<FetchStatesCubit>()
            .fetchStatesMore(countryId: widget.countryId);
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
      context.read<FetchStatesCubit>().fetchStates(
          search: searchController.text, countryId: widget.countryId);
      previousSearchQuery = searchController.text;
      setState(() {});
    }
    // } else {
    // context.read<SearchItemCubit>().clearSearch();
    // }
  }

  PreferredSizeWidget appBarWidget() {
    return AppBar(
      systemOverlayStyle:
      UiUtils.getSystemUiOverlayStyle(context:context,statusBarColor: context.color.backgroundColor),
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
                        "${"search".translate(context)}\t${"state".translate(context)}",
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
        widget.countryName,
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
                  ))),
        ),
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
    return BlocBuilder<FetchStatesCubit, FetchStatesState>(
      builder: (context, state) {
        if (state is FetchStatesInProgress) {
          return LocationHelperWidget().shimmerEffect();
        }

        if (state is FetchStatesFailure) {
          if (state.errorMessage is ApiException) {
            if (state.errorMessage == "no-internet") {
              return SingleChildScrollView(
                child: NoInternet(
                  onRetry: () {
                    context.read<FetchStatesCubit>().fetchStates(
                        search: searchController.text,
                        countryId: widget.countryId);
                  },
                ),
              );
            }
          }

          return Center(child: const SomethingWentWrong());
        }

        if (state is FetchStatesSuccess) {
          if (state.statesModel.isEmpty) {
            return SingleChildScrollView(
              child: NoDataFound(
                onTap: () {
                  context.read<FetchStatesCubit>().fetchStates(
                      search: searchController.text,
                      countryId: widget.countryId);
                },
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.only(top: 17),
            color: context.color.secondaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LocationHelperWidget().firstIndexWidget(
                    context,
                    widget.from,
                    "${"chooseLbl".translate(context)}\t${"state".translate(context)}",
                    "${"allIn".translate(context)}\t${widget.countryName}",
                    countryName: widget.countryName,
                    noOfPopBeforeResult: 1,
                    latitude: double.parse(widget.latitude),
                    longitude: double.parse(widget.longitude),
                    fetchHomeCountryName: widget.countryName),

                // Remove Expanded here
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: state.statesModel.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    separatorBuilder: (context, index) {
                      return  Divider(
                        thickness: 3.5,
                        height: 10,
                        color: context.color.backgroundColor,
                      );
                    },
                    itemBuilder: (context, index) {
                      StatesModel states = state.statesModel[index];

                      return BlocProvider(
                        create: (context) => FetchCitiesCubit(),
                        child: Builder(builder: (context) {
                          return BlocListener<FetchCitiesCubit,
                              FetchCitiesState>(
                            listener: (context, city) {
                              if (city is FetchCitiesSuccess) {
                                if (city.citiesModel.isNotEmpty) {
                                  Navigator.pushNamed(
                                      context, Routes.citiesScreen,
                                      arguments: {
                                        "stateId": states.id!,
                                        "stateName": states.name!,
                                        "from": widget.from,
                                        "countryName": widget.countryName,
                                        "latitude": states.latitude,
                                        "longitude": states.longitude,
                                      });
                                }
                              }
                            },
                            child: ListTile(
                              onTap: () {
                                context
                                    .read<FetchCitiesCubit>()
                                    .fetchCities(stateId: states.id!);
                              },
                              title: CustomText(
                                states.name!,
                                textAlign: TextAlign.start,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                color: context.color.textDefaultColor,
                                fontSize: context.font.normal,
                              ),
                              trailing: Container(
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
                            ),
                          );
                        }),
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
