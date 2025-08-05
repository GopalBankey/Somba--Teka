import 'package:SombaTeka/app/routes.dart';
import 'package:SombaTeka/data/cubits/favorite/favorite_cubit.dart';
import 'package:SombaTeka/data/helper/designs.dart';
import 'package:SombaTeka/data/model/item/item_model.dart';
import 'package:SombaTeka/ui/screens/home/widgets/item_horizontal_card.dart';

import 'package:SombaTeka/ui/screens/widgets/errors/no_data_found.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_internet.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:SombaTeka/ui/screens/widgets/intertitial_ads_screen.dart';
import 'package:SombaTeka/ui/screens/widgets/shimmerLoadingContainer.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/api.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) {
        return const FavoriteScreen();
      },
    );
  }

  @override
  FavoriteScreenState createState() => FavoriteScreenState();
}

class FavoriteScreenState extends State<FavoriteScreen> {
  late final ScrollController _controller = ScrollController()
    ..addListener(
      () {
        if (_controller.offset >= _controller.position.maxScrollExtent) {
          if (context.read<FavoriteCubit>().hasMoreFavorite()) {
            setState(() {});
            context.read<FavoriteCubit>().getMoreFavorite();
          }
        }
      },
    );

  @override
  void initState() {
    super.initState();
    AdHelper.loadInterstitialAd();
    getFavorite();
  }

  void getFavorite() async {
    context.read<FavoriteCubit>().getFavorite();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AdHelper.showInterstitialAd();
    return RefreshIndicator(
      onRefresh: () async {
        getFavorite();
      },
      color: context.color.territoryColor,
      child: Scaffold(
        appBar: UiUtils.buildAppBar(context,
            showBackButton: true, title: "favorites".translate(context)),
        body: BlocBuilder<FavoriteCubit, FavoriteState>(
          builder: (context, state) {
            if (state is FavoriteFetchInProgress) {
              return shimmerEffect();
            } else if (state is FavoriteFetchSuccess) {
              if (state.favorite.isEmpty) {
                return Center(
                  child: NoDataFound(
                    onTap: getFavorite,
                  ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _controller,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: state.favorite.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        ItemModel item = state.favorite[index];
                        return InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.adDetailsScreen,
                              arguments: {
                                'model': item,
                              },
                            );
                          },
                          child: ItemHorizontalCard(
                            item: item,
                            showLikeButton: true,
                            additionalImageWidth: 8,
                          ),
                        );
                      },
                    ),
                  ),
                  if (state.isLoadingMore)
                    UiUtils.progress(
                      normalProgressColor: context.color.territoryColor,
                    )
                ],
              );
            } else if (state is FavoriteFetchFailure) {
              if (state.errorMessage is ApiException &&
                  (state.errorMessage as ApiException).errorMessage ==
                      "no-internet") {
                return NoInternet(
                  onRetry: getFavorite,
                );
              }
              return const SomethingWentWrong();
            }
            return Container();
          },
        ),
      ),
    );
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
}
