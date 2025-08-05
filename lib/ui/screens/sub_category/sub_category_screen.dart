import 'package:SombaTeka/app/routes.dart';
import 'package:SombaTeka/data/cubits/category/fetch_sub_categories_cubit.dart';
import 'package:SombaTeka/data/model/category_model.dart';

import 'package:SombaTeka/ui/screens/widgets/errors/no_data_found.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_internet.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/api.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class SubCategoryScreen extends StatefulWidget {
  final List<CategoryModel> categoryList;
  final String catName;
  final int catId;
  final List<String> categoryIds;

  const SubCategoryScreen(
      {super.key,
      required this.categoryList,
      required this.catName,
      required this.catId,
      required this.categoryIds});

  @override
  State<SubCategoryScreen> createState() => _CategoryListState();

  static Route route(RouteSettings routeSettings) {
    Map? args = routeSettings.arguments as Map?;
    return MaterialPageRoute(
      builder: (_) => SubCategoryScreen(
        categoryList: args?['categoryList'],
        catName: args?['catName'],
        catId: args?['catId'],
        categoryIds: args?['categoryIds'],
      ),
    );
  }
}

class _CategoryListState extends State<SubCategoryScreen>
    with TickerProviderStateMixin {
  late final ScrollController controller = ScrollController();

  @override
  void initState() {
    getSubCategories();
    if (widget.categoryList.isEmpty) {
      controller.addListener(pageScrollListen);
    }
    super.initState();
  }

  void getSubCategories() {
    if (widget.categoryList.isEmpty) {
      context
          .read<FetchSubCategoriesCubit>()
          .fetchSubCategories(categoryId: widget.catId);
    }
  }

  void pageScrollListen() {
    if (controller.isEndReached()) {
      if (context.read<FetchSubCategoriesCubit>().hasMoreData()) {
        context
            .read<FetchSubCategoriesCubit>()
            .fetchSubCategories(categoryId: widget.catId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
          context: context, statusBarColor: context.color.secondaryColor),
      child: Scaffold(
          backgroundColor: context.color.backgroundColor,
          appBar: UiUtils.buildAppBar(
            context,
            showBackButton: true,
            title: widget.catName,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 5.0),
            child: Container(
              color: context.color.secondaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 18),
                      child: CustomText(
                        "${"lblall".translate(context)}\t${widget.catName}",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        color: context.color.textDefaultColor,
                        fontWeight: FontWeight.w600,
                        fontSize: context.font.normal,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, Routes.itemsList,
                          arguments: {
                            'catID': widget.catId.toString(),
                            'catName': widget.catName,
                            "categoryIds": [...widget.categoryIds]
                          });
                    },
                  ),
                  const Divider(
                    thickness: 1.2,
                    height: 10,
                  ),
                  widget.categoryList.isNotEmpty
                      ? categoryListWidget(widget.categoryList)
                      : fetchSubCategoriesData()
                ],
              ),
            ),
          )),
    );
  }

  Widget fetchSubCategoriesData() {
    return BlocBuilder<FetchSubCategoriesCubit, FetchSubCategoriesState>(
      builder: (context, state) {
        if (state is FetchSubCategoriesInProgress) {
          return shimmerEffect();
        }

        if (state is FetchSubCategoriesFailure) {
          if (state.errorMessage is ApiException) {
            if (state.errorMessage == "no-internet") {
              return NoInternet(
                onRetry: () {
                  context
                      .read<FetchSubCategoriesCubit>()
                      .fetchSubCategories(categoryId: widget.catId);
                },
              );
            }
          }

          return const SomethingWentWrong();
        }

        if (state is FetchSubCategoriesSuccess) {
          if (state.categories.isEmpty) {
            return NoDataFound(
              onTap: () {
                context
                    .read<FetchSubCategoriesCubit>()
                    .fetchSubCategories(categoryId: widget.catId);
              },
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              categoryListWidget(state.categories),
              if (state.isLoadingMore) UiUtils.progress()
            ],
          );
        }

        return Container();
      },
    );
  }

  Widget shimmerEffect() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 15,
      separatorBuilder: (context, index) {
        return const Divider(
          thickness: 1.2,
          height: 10,
        );
      },
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
          highlightColor: Theme.of(context).colorScheme.shimmerHighlightColor,
          child: Container(
            padding: EdgeInsets.all(5),
            width: double.maxFinite,
            height: 56,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
          ),
        );
      },
    );
  }

  Widget categoryListWidget(List<CategoryModel> categories) {
    return ListView.separated(
      itemCount: categories.length,
      padding: EdgeInsets.zero,
      controller: controller,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      separatorBuilder: (context, index) {
        return const Divider(
          thickness: 1.2,
          height: 10,
        );
      },
      itemBuilder: (context, index) {
        CategoryModel category = categories[index];

        return ListTile(
          onTap: () {
            if (categories[index].children!.isEmpty &&
                categories[index].subcategoriesCount == 0) {
              Navigator.pushNamed(context, Routes.itemsList, arguments: {
                'catID': categories[index].id.toString(),
                'catName': categories[index].name,
                "categoryIds": [
                  ...widget.categoryIds,
                  categories[index].id.toString()
                ]
              });
            } else {
              Navigator.pushNamed(context, Routes.subCategoryScreen,
                  arguments: {
                    "categoryList": categories[index].children,
                    "catName": categories[index].name,
                    "catId": categories[index].id,
                    "categoryIds": [
                      ...widget.categoryIds,
                      categories[index].id.toString()
                    ]
                  });
            }
          },
          leading: FittedBox(
            child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: context.color.territoryColor.withValues(alpha: 0.1)),
                child: UiUtils.imageType(
                  category.url!,
                  color: context.color.territoryColor,
                  fit: BoxFit.cover,
                )),
          ),
          title: CustomText(
            category.name!,
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
                  color: context.color.textLightColor.withValues(alpha: 0.1)),
              child: Icon(
                Icons.chevron_right_outlined,
                color: context.color.textDefaultColor,
              )),
        );
      },
    );
  }
}
