import 'dart:async';
import 'dart:math';

import 'package:SombaTeka/app/routes.dart';
import 'package:SombaTeka/data/cubits/item/fetch_item_from_category_cubit.dart';
import 'package:SombaTeka/data/model/item/item_model.dart';
import 'package:SombaTeka/data/model/item_filter_model.dart';
import 'package:SombaTeka/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:SombaTeka/ui/screens/home/widgets/item_horizontal_card.dart';
import 'package:SombaTeka/ui/screens/main_activity.dart';
import 'package:SombaTeka/ui/screens/native_ads_screen.dart';

import 'package:SombaTeka/ui/screens/widgets/errors/no_data_found.dart';
import 'package:SombaTeka/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/api.dart';
import 'package:SombaTeka/utils/app_icon.dart';
import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/custom_silver_grid_delegate.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ItemsList extends StatefulWidget {
  final String categoryId, categoryName;
  final List<String> categoryIds;

  const ItemsList(
      {super.key,
      required this.categoryId,
      required this.categoryName,
      required this.categoryIds});

  @override
  ItemsListState createState() => ItemsListState();

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return MaterialPageRoute(
      builder: (_) => ItemsList(
        categoryId: arguments?['catID'] as String,
        categoryName: arguments?['catName'],
        categoryIds: arguments?['categoryIds'],
      ),
    );
  }
}

class ItemsListState extends State<ItemsList> {
  late ScrollController controller;
  static TextEditingController searchController = TextEditingController();
  bool isFocused = false;
  bool isList = true;
  String previousSearchQuery = "";
  Timer? _searchDelay;
  String? sortBy;
  ItemFilterModel? filter;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    searchBody = {};
    Constant.itemFilter = null;
    searchController = TextEditingController();
    searchController.addListener(searchItemListener);
    controller = ScrollController()..addListener(_loadMore);

    context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
        categoryId: int.parse(
          widget.categoryId,
        ),
        search: "",
        filter: ItemFilterModel(
            country: HiveUtils.getCountryName() ?? "",
            areaId: HiveUtils.getAreaId() != null
                ? int.parse(HiveUtils.getAreaId().toString())
                : null,
            city: HiveUtils.getCityName() ?? "",
            state: HiveUtils.getStateName() ?? "",
            categoryId: widget.categoryId,
            radius: HiveUtils.getNearbyRadius() ?? null,
            latitude: HiveUtils.getLatitude() ?? null,
            longitude: HiveUtils.getLongitude() ?? null));

    Future.delayed(Duration.zero, () {
      selectedCategoryId = widget.categoryId;
      selectedCategoryName = widget.categoryName;
      searchBody[Api.categoryId] = widget.categoryId;
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.removeListener(_loadMore);
    controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  //this will listen and manage search
  void searchItemListener() {
    _searchDelay?.cancel();
    searchCallAfterDelay();
  }

//This will create delay so we don't face rapid api call
  void searchCallAfterDelay() {
    _searchDelay = Timer(const Duration(milliseconds: 500), itemSearch);
  }

  ///This will call api after some delay
  void itemSearch() {
    // if (searchController.text.isNotEmpty) {
    if (previousSearchQuery != searchController.text) {
      context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
          categoryId: int.parse(
            widget.categoryId,
          ),
          search: searchController.text);
      previousSearchQuery = searchController.text;
      sortBy = null;
      setState(() {});
    }
  }

  void _loadMore() async {
    if (controller.isEndReached()) {
      if (context.read<FetchItemFromCategoryCubit>().hasMoreData()) {
        context.read<FetchItemFromCategoryCubit>().fetchItemFromCategoryMore(
            catId: int.parse(
              widget.categoryId,
            ),
            search: searchController.text,
            sortBy: sortBy,
            filter: ItemFilterModel(
              country: HiveUtils.getCountryName() ?? "",
              areaId: HiveUtils.getAreaId() != null
                  ? int.parse(HiveUtils.getAreaId().toString())
                  : null,
              city: HiveUtils.getCityName() ?? "",
              state: HiveUtils.getStateName() ?? "",
              categoryId: widget.categoryId,
            ));
      }
    }
  }

  Widget searchBarWidget() {
    return Container(
      height: 56,
      color: context.color.secondaryColor,
      child: LayoutBuilder(builder: (context, c) {
        return SizedBox(
            width: c.maxWidth,
            child: FittedBox(
              fit: BoxFit.none,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 18.0),
                child: Row(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 243,
                        height: 40,
                        alignment: AlignmentDirectional.center,
                        decoration: BoxDecoration(
                            border: Border.all(
                                width: 1,
                                color: context.color.textLightColor
                                    .withValues(alpha: 0.18)),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            color: context.color.primaryColor),
                        child: TextFormField(
                            controller: searchController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 8),
                              //OutlineInputBorder()
                              fillColor:
                                  Theme.of(context).colorScheme.primaryColor,
                              hintText: "searchHintLbl".translate(context),
                              prefixIcon: setSearchIcon(),
                              prefixIconConstraints: const BoxConstraints(
                                  minHeight: 5, minWidth: 5),
                            ),
                            enableSuggestions: true,
                            onEditingComplete: () {
                              changeFocus(false);
                            },
                            onTap: () {
                              //change prefix icon color to primary
                              changeFocus(true);
                            })),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isList = false;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                              width: 1,
                              color: context.color.textLightColor
                                  .withValues(alpha: 0.18)),
                          color: context.color.secondaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: UiUtils.getSvg(AppIcons.gridViewIcon,
                              color: !isList
                                  ? context.color.textDefaultColor
                                  : context.color.textDefaultColor
                                      .withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isList = true;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                              width: 1,
                              color: context.color.textLightColor
                                  .withValues(alpha: 0.18)),
                          color: context.color.secondaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: UiUtils.getSvg(AppIcons.listViewIcon,
                              color: isList
                                  ? context.color.textDefaultColor
                                  : context.color.textDefaultColor
                                      .withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
      }),
    );
  }

  void changeFocus(bool changeFocusVal) {
    isFocused = changeFocusVal; //set icon color to black back if flase
    if (!changeFocusVal) {
      FocusScope.of(context).unfocus(); //dismiss keyboard
    }
    setState(() {});
  }

  Widget setSearchIcon() {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: UiUtils.getSvg(AppIcons.search,
            color: context.color.textDefaultColor));
  }

  Widget setSuffixIcon() {
    return GestureDetector(
      onTap: () {
        searchController.clear();
        changeFocus(false);
      },
      child: Icon(
        Icons.close_rounded,
        color: Theme.of(context).colorScheme.blackColor,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return bodyWidget();
  }

  Widget bodyWidget() {
    return SafeArea(
      top: false,
      child: AnnotatedRegion(
        value: UiUtils.getSystemUiOverlayStyle(
          context: context,
          statusBarColor: context.color.secondaryColor,
        ),
        child: PopScope(
          canPop: true,
          onPopInvokedWithResult: (isPop, result) {
            Constant.itemFilter = null;
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.primaryColor,
            appBar: UiUtils.buildAppBar(context,
                showBackButton: true,
                title: selectedCategoryName.trim().isEmpty
                    ? widget.categoryName
                    : selectedCategoryName),
            bottomNavigationBar: bottomWidget(),
            body: Column(
              children: [
                searchBarWidget(),
                Expanded(child: fetchItems()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container bottomWidget() {
    return Container(
      color: context.color.secondaryColor,
      padding: EdgeInsets.only(top: 3, bottom: 3),
      height: 45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          filterByWidget(),
          VerticalDivider(
            color: context.color.textLightColor.withValues(alpha: 0.3),
          ),
          // Add a vertical divider here
          sortByWidget(),
        ],
      ),
    );
  }

  Widget filterByWidget() {
    return InkWell(
      child: Row(
        spacing: 7,
        children: [
          UiUtils.getSvg(AppIcons.filterByIcon,
              color: context.color.textDefaultColor),
          CustomText("filterTitle".translate(context))
        ],
      ),
      onTap: () {
        Navigator.pushNamed(context, Routes.filterScreen, arguments: {
          "update": getFilterValue,
          "from": "itemsList",
          "categoryIds": widget.categoryIds
        }).then((value) {
          if (value == true) {
            ItemFilterModel updatedFilter =
                filter!.copyWith(categoryId: widget.categoryId);
            context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
                categoryId: int.parse(
                  widget.categoryId,
                ),
                search: searchController.text.toString(),
                filter: updatedFilter);
          }
          setState(() {});
        });
      },
    );
  }

  void getFilterValue(ItemFilterModel model) {
    filter = model;
    setState(() {});
  }

  Widget sortByWidget() {
    return InkWell(
      child: Row(
        spacing: 7,
        children: [
          UiUtils.getSvg(AppIcons.sortByIcon,
              color: context.color.textDefaultColor),
          CustomText("sortBy".translate(context))
        ],
      ),
      onTap: () {
        showSortByBottomSheet();
      },
    );
  }

  void showSortByBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: context.color.borderColor,
                  ),
                  height: 6,
                  width: 60,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 17, horizontal: 20),
                child: CustomText(
                  'sortBy'.translate(context),
                  textAlign: TextAlign.start,
                  fontWeight: FontWeight.bold,
                  fontSize: context.font.large,
                ),
              ),

              Divider(height: 1), // Add some space between title and options
              sortByItemWidget('default', null),

              Divider(height: 1), // Divider between option 1 and option 2
              sortByItemWidget('newToOld', "new-to-old"),

              Divider(height: 1), // Divider between option 2 and option 3
              sortByItemWidget('oldToNew', "old-to-new"),

              Divider(height: 1), // Divider between option 3 and option 4
              sortByItemWidget('priceHighToLow', "price-high-to-low"),

              Divider(height: 1), // Divider between option 4 and option 5
              sortByItemWidget('priceLowToHigh', "price-low-to-high"),
            ],
          ),
        );
      },
    );
  }

  Widget fetchItems() {
    return BlocBuilder<FetchItemFromCategoryCubit, FetchItemFromCategoryState>(
        builder: (context, state) {
      if (state is FetchItemFromCategoryInProgress) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          itemCount: 10,
          itemBuilder: (context, index) {
            return buildItemsShimmer(context);
          },
        );
      }

      if (state is FetchItemFromCategoryFailure) {
        return Center(
          child: CustomText(state.errorMessage),
        );
      }
      if (state is FetchItemFromCategorySuccess) {
        if (state.itemModel.isEmpty) {
          return Center(
            child: NoDataFound(
              onTap: () {
                context
                    .read<FetchItemFromCategoryCubit>()
                    .fetchItemFromCategory(
                        categoryId: int.parse(
                          widget.categoryId,
                        ),
                        search: searchController.text.toString());
              },
            ),
          );
        }
        return Column(
          children: [
            Expanded(child: mainChildren(state.itemModel)),
            if (state.isLoadingMore) UiUtils.progress()
          ],
        );
      }
      return Container();
    });
  }

  Widget sortByItemWidget(String title, String? sortByVal) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20),
      title: CustomText(title.translate(context)),
      onTap: () {
        Navigator.pop(context);
        sortBy = sortByVal;
        context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
            categoryId: int.parse(
              widget.categoryId,
            ),
            search: searchController.text.toString(),
            sortBy: sortByVal);
        setState(() {
          FocusManager.instance.primaryFocus?.unfocus();
        });
      },
    );
  }

  void _navigateToDetails(BuildContext context, ItemModel item) {
    Navigator.pushNamed(
      context,
      Routes.adDetailsScreen,
      arguments: {'model': item},
    );
  }

  Widget mainChildren(List<ItemModel> items) {
    List<Widget> children = [];
    int gridCount = Constant.nativeAdsAfterItemNumber;
    int total = items.length;

    for (int i = 0; i < total; i += gridCount) {
      if (isList) {
        children.add(_buildListViewSection(
            context, i, min(gridCount, total - i), items));
      } else {
        children.add(_buildGridViewSection(
            context, i, min(gridCount, total - i), items));
      }

      int remainingItems = total - i - gridCount;
      if (remainingItems > 0) {
        children.add(NativeAdWidget(type: TemplateType.medium));
      }
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () async {
        // Debug log to check if onRefresh is triggered
        searchBody = {};
        Constant.itemFilter = null;

        context.read<FetchItemFromCategoryCubit>().fetchItemFromCategory(
              categoryId: int.parse(widget.categoryId),
              search: "",
            );
      },
      color: context.color.territoryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        controller: controller,
        padding: EdgeInsetsDirectional.only(bottom: 30),
        children: children,
      ),
    );
  }

  Widget _buildListViewSection(BuildContext context, int startIndex,
      int itemCount, List<ItemModel> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        ItemModel item = items[startIndex + index];
        return GestureDetector(
          onTap: () => _navigateToDetails(context, item),
          child: ItemHorizontalCard(item: item),
        );
      },
    );
  }

  Widget _buildGridViewSection(BuildContext context, int startIndex,
      int itemCount, List<ItemModel> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
          crossAxisCount: 2,
          height: MediaQuery.of(context).size.height / 3.2,
          mainAxisSpacing: 7,
          crossAxisSpacing: 10),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        ItemModel item = items[startIndex + index];
        return GestureDetector(
          onTap: () => _navigateToDetails(context, item),
          child: ItemCard(item: item),
        );
      },
    );
  }

  Widget buildItemsShimmer(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
          border: Border.all(width: 1.5, color: context.color.borderColor),
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(18)),
      child: Row(
        spacing: 10,
        children: [
          CustomShimmer(
            height: 120,
            width: 100,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomShimmer(
                width: 100,
                height: 10,
                borderRadius: 7,
              ),
              CustomShimmer(
                width: 150,
                height: 10,
                borderRadius: 7,
              ),
              CustomShimmer(
                width: 120,
                height: 10,
                borderRadius: 7,
              ),
              CustomShimmer(
                width: 80,
                height: 10,
                borderRadius: 7,
              )
            ],
          )
        ],
      ),
    );
  }
}
