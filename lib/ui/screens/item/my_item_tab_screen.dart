import 'package:SombaTeka/app/routes.dart';
import 'package:SombaTeka/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:SombaTeka/data/helper/designs.dart';
import 'package:SombaTeka/data/model/item/item_model.dart';
import 'package:SombaTeka/ui/screens/home/home_screen.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_data_found.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_internet.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:SombaTeka/ui/screens/widgets/promoted_widget.dart';
import 'package:SombaTeka/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/api.dart';
import 'package:SombaTeka/utils/app_icon.dart';
import 'package:SombaTeka/utils/cloud_state/cloud_state.dart';
import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

Map<String, FetchMyItemsCubit> myAdsCubitReference = {};

class MyItemTab extends StatefulWidget {
  //final bool? getActiveItems;
  final String? getItemsWithStatus;

  const MyItemTab({super.key, this.getItemsWithStatus});

  @override
  CloudState<MyItemTab> createState() => _MyItemTabState();
}

class _MyItemTabState extends CloudState<MyItemTab> {
  late final ScrollController _pageScrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    if (HiveUtils.isUserAuthenticated()) {
      context.read<FetchMyItemsCubit>().fetchMyItems(
            getItemsWithStatus: widget.getItemsWithStatus,
          );
      _pageScrollController.addListener(_pageScroll);
      setReferenceOfCubit();
    }

    super.initState();
  }

  void _pageScroll() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchMyItemsCubit>().hasMoreData()) {
        context
            .read<FetchMyItemsCubit>()
            .fetchMyMoreItems(getItemsWithStatus: widget.getItemsWithStatus);
      }
    }
  }

  void setReferenceOfCubit() {
    myAdsCubitReference[widget.getItemsWithStatus!] =
        context.read<FetchMyItemsCubit>();
  }

  ListView shimmerEffect() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        vertical: 10 + defaultPadding,
        horizontal: defaultPadding,
      ),
      itemCount: 5,
      separatorBuilder: (context, index) {
        return const SizedBox(
          height: 12,
        );
      },
      itemBuilder: (context, index) {
        return Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const ClipRRect(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                borderRadius: BorderRadius.all(Radius.circular(15)),
                child: CustomShimmer(height: 90, width: 90),
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  return Column(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(
                        height: 10,
                      ),
                      CustomShimmer(
                        height: 10,
                        width: c.maxWidth - 50,
                      ),
                      const CustomShimmer(
                        height: 10,
                      ),
                      CustomShimmer(
                        height: 10,
                        width: c.maxWidth / 1.2,
                      ),
                      Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: CustomShimmer(
                          width: c.maxWidth / 4,
                        ),
                      ),
                    ],
                  );
                }),
              )
            ],
          ),
        );
      },
    );
  }

  Widget showAdminEdited() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      //margin: EdgeInsetsDirectional.only(end: 4, start: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: deactivateButtonColor.withValues(alpha: 0.1),
      ),
      child: CustomText(
        "adminEdited".translate(context),
        fontSize: context.font.small,
        color: deactivateButtonColor,
      ),
    );
  }

  Widget showStatus(ItemModel model) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      //margin: EdgeInsetsDirectional.only(end: 4, start: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: _getStatusColor(model.status),
      ),
      child: CustomText(
        _getStatusCustomText(model)!,
        fontSize: context.font.small,
        color: _getStatusTextColor(model.status),
      ),
    );
  }

  String? _getStatusCustomText(ItemModel model) {
    switch (model.status) {
      case Constant.statusReview:
        return "underReview".translate(context);
      case Constant.statusActive:
        return "active".translate(context);
      case Constant.statusApproved:
        return "approved".translate(context);
      case Constant.statusInactive:
        return "deactivate".translate(context);
      case Constant.statusSoldOut:
        return model.category!.isJobCategory == 1
            ? "jobClosed".translate(context)
            : "soldOut".translate(context);
      case Constant.statusPermanentRejected:
        return "permanentRejected".translate(context);
      case Constant.statusSoftRejected:
        return "softRejected".translate(context);
      case Constant.statusExpired:
        return "expired".translate(context);
      case Constant.statusResubmitted:
        return "resubmitted".translate(context);
      default:
        return model.status;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case Constant.statusReview || Constant.statusResubmitted:
        return pendingButtonColor.withValues(alpha: 0.1);
      case Constant.statusActive || Constant.statusApproved:
        return activateButtonColor.withValues(alpha: 0.1);
      case Constant.statusInactive:
        return deactivateButtonColor.withValues(alpha: 0.1);
      case Constant.statusSoldOut:
        return soldOutButtonColor.withValues(alpha: 0.1);
      case Constant.statusPermanentRejected || Constant.statusSoftRejected:
        return deactivateButtonColor.withValues(alpha: 0.1);
      case Constant.statusExpired:
        return deactivateButtonColor.withValues(alpha: 0.1);
      default:
        return context.color.territoryColor.withValues(alpha: 0.1);
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case Constant.statusReview || Constant.statusResubmitted:
        return pendingButtonColor;
      case Constant.statusActive || Constant.statusApproved:
        return activateButtonColor;
      case Constant.statusInactive:
        return deactivateButtonColor;
      case Constant.statusSoldOut:
        return soldOutButtonColor;
      case Constant.statusPermanentRejected || Constant.statusSoftRejected:
        return deactivateButtonColor;
      case Constant.statusExpired:
        return deactivateButtonColor;
      default:
        return context.color.territoryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchMyItemsCubit, FetchMyItemsState>(
      builder: (context, state) {
        if (state is FetchMyItemsInProgress) {
          return shimmerEffect();
        }

        if (state is FetchMyItemsFailed) {
          if (state.error is ApiException) {
            if (state.error.error == "no-internet") {
              return NoInternet(
                onRetry: () {
                  context.read<FetchMyItemsCubit>().fetchMyItems(
                      getItemsWithStatus: widget.getItemsWithStatus);
                },
              );
            }
          }

          return const SomethingWentWrong();
        }

        if (state is FetchMyItemsSuccess) {
          if (state.items.isEmpty) {
            return NoDataFound(
              mainMessage: "noAdsFound".translate(context),
              subMessage: "noAdsAvailable".translate(context),
              onTap: () {
                context.read<FetchMyItemsCubit>().fetchMyItems(
                    getItemsWithStatus: widget.getItemsWithStatus);
              },
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  key: _refreshIndicatorKey,
                  triggerMode: RefreshIndicatorTriggerMode.anywhere,
                  onRefresh: () async {
                    context.read<FetchMyItemsCubit>().fetchMyItems(
                          getItemsWithStatus: widget.getItemsWithStatus,
                        );

                    setReferenceOfCubit();
                  },
                  color: context.color.territoryColor,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    shrinkWrap: true,
                    controller: _pageScrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: sidePadding,
                      vertical: 8,
                    ),
                    separatorBuilder: (context, index) {
                      return Container(
                        height: 8,
                      );
                    },
                    itemBuilder: (context, index) {
                      ItemModel item = state.items[index];
                      return InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, Routes.adDetailsScreen,
                              arguments: {
                                "model": item,
                              }).then((value) {
                            if (value == "refresh") {
                              context.read<FetchMyItemsCubit>().fetchMyItems(
                                    getItemsWithStatus:
                                        widget.getItemsWithStatus,
                                  );

                              setReferenceOfCubit();
                            }
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            height: 130,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: item.status == Constant.statusInactive
                                    ? context.color.deactivateColor
                                        .withValues(alpha: 0.5)
                                    : context.color.secondaryColor,
                                border: Border.all(
                                    color: context.color.textLightColor
                                        .withValues(alpha: 0.18),
                                    width: 1)),
                            width: double.infinity,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: SizedBox(
                                        width: 116,
                                        height: double.infinity,
                                        child: UiUtils.getImage(
                                            item.image ?? "",
                                            height: double.infinity,
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                    if (item.isFeature ?? false)
                                      const PositionedDirectional(
                                          start: 5,
                                          top: 5,
                                          child: PromotedCard(
                                              type: PromoteCardType.icon))
                                  ],
                                ),
                                Expanded(
                                  flex: 8,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 15),
                                    child: Column(
                                      //mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Row(
                                          children: [
                                            if (item.isEditedByAdmin == 1) ...[
                                              showAdminEdited(),
                                              SizedBox(
                                                width: 10,
                                              ),
                                            ],
                                            showStatus(item)
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (UiUtils.displayPrice(item))
                                              Expanded(
                                                  child: UiUtils.getPriceWidget(
                                                      item, context))
                                            else
                                              Expanded(
                                                child: CustomText(
                                                  item.name ?? "",
                                                  maxLines: 2,
                                                  firstUpperCaseWidget: true,
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (UiUtils.displayPrice(item))
                                          CustomText(
                                            item.name ?? "",
                                            maxLines: 2,
                                            firstUpperCaseWidget: true,
                                          ),
                                        Row(
                                          spacing: 20,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              flex: 1,
                                              child: Row(
                                                spacing: 4,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgPicture.asset(AppIcons.eye,
                                                      width: 14,
                                                      height: 14,
                                                      colorFilter: ColorFilter.mode(
                                                          context.color
                                                              .textDefaultColor,
                                                          BlendMode.srcIn)),
                                                  CustomText(
                                                    "${"views".translate(context)}:${item.views}",
                                                    fontSize:
                                                        context.font.small,
                                                    color: context
                                                        .color.textColorDark
                                                        .withValues(alpha: 0.5),
                                                  )
                                                ],
                                              ),
                                            ),
                                            Flexible(
                                              flex: 1,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgPicture.asset(
                                                      AppIcons.heart,
                                                      width: 14,
                                                      height: 14,
                                                      colorFilter: ColorFilter.mode(
                                                          context.color
                                                              .textDefaultColor,
                                                          BlendMode.srcIn)),
                                                  const SizedBox(
                                                    width: 4,
                                                  ),
                                                  CustomText(
                                                    "${"like".translate(context)}:${item.totalLikes.toString()}",
                                                    fontSize:
                                                        context.font.small,
                                                    color: context
                                                        .color.textColorDark
                                                        .withValues(alpha: 0.5),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: state.items.length,
                  ),
                ),
              ),
              if (state.isLoadingMore) UiUtils.progress()
            ],
          );
        }
        return Container();
      },
    );
  }
}
