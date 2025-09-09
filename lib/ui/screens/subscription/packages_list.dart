import 'dart:io';

import 'package:SombaTeka/data/cubits/subscription/assign_free_package_cubit.dart';
import 'package:SombaTeka/data/cubits/subscription/fetch_ads_listing_subscription_packages_cubit.dart';
import 'package:SombaTeka/data/cubits/subscription/fetch_featured_subscription_packages_cubit.dart';
import 'package:SombaTeka/data/cubits/subscription/get_payment_intent_cubit.dart';
import 'package:SombaTeka/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:SombaTeka/data/cubits/system/get_api_keys_cubit.dart';
import 'package:SombaTeka/data/model/subscription_package_model.dart';
import 'package:SombaTeka/data/model/system_settings_model.dart';
import 'package:SombaTeka/settings.dart';
import 'package:SombaTeka/ui/screens/subscription/widget/featured_ads_subscription_plan_item.dart';
import 'package:SombaTeka/ui/screens/subscription/widget/item_listing_subscription_plans_item.dart';

import 'package:SombaTeka/ui/screens/widgets/errors/no_data_found.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_internet.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:SombaTeka/ui/screens/widgets/intertitial_ads_screen.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/api.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/payment/gateaways/inapp_purchase_manager.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubscriptionPackageListScreen extends StatefulWidget {
  const SubscriptionPackageListScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(builder: (context) {
      return SubscriptionPackageListScreen();
    });
  }

  @override
  State<SubscriptionPackageListScreen> createState() =>
      _SubscriptionPackageListScreenState();
}

class _SubscriptionPackageListScreenState
    extends State<SubscriptionPackageListScreen>
    with SingleTickerProviderStateMixin {
  bool isLifeTimeSubscription = false;
  bool hasAlreadyPackage = false;
  bool isInterstitialAdShown = false;

  PageController adsPageController =
      PageController(initialPage: 0, viewportFraction: 0.8);
  PageController featuredPageController =
      PageController(initialPage: 0, viewportFraction: 0.8);

  int currentIndex = 0;
  TabController? _tabController;

  List<SubscriptionPackageModel> iapListingAdsProducts = [];
  List<String> listingAdsProducts = [];
  List<SubscriptionPackageModel> iapFeaturedAdsProducts = [];
  List<String> featuredAdsProducts = [];
  final InAppPurchaseManager _inAppPurchaseManager = InAppPurchaseManager();

  late final bool isFreeAdListingEnabled;

  @override
  void initState() {
    super.initState();
    AdHelper.loadInterstitialAd();
    if (HiveUtils.isUserAuthenticated()) {
      context.read<GetApiKeysCubit>().fetch();
    }
    context.read<FetchAdsListingSubscriptionPackagesCubit>().fetchPackages();
    context.read<FetchFeaturedSubscriptionPackagesCubit>().fetchPackages();
    if (Platform.isIOS) {
      InAppPurchaseManager.getPending();
      _inAppPurchaseManager.listenIAP(context);
    }
    isFreeAdListingEnabled = context
            .read<FetchSystemSettingsCubit>()
            .getSetting(SystemSetting.freeAdListing) ==
        "1";
    if (!isFreeAdListingEnabled) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(_handleTabSelection);
    }
  }

  @override
  void dispose() {
    if (_tabController != null) {
      _tabController?.removeListener(_handleTabSelection);
    }
    if (Platform.isIOS) {
      _inAppPurchaseManager.dispose();
    }
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController!.indexIsChanging) {
      setState(() {
        currentIndex = 0;
      });
    }
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index; //update current index for Next button
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: "subsctiptionPlane".translate(context),
        bottomHeight: isFreeAdListingEnabled ? 0 : 49,
        bottom: isFreeAdListingEnabled
            ? null
            : [
                Container(
                  decoration: BoxDecoration(
                      color: context.color.secondaryColor,
                      // Set background color here
                      boxShadow: [
                        BoxShadow(
                          color:
                              context.color.borderColor.withValues(alpha: 0.8),
                          // Shadow color
                          spreadRadius: 3,
                          // Spread radius
                          blurRadius: 2,
                          // Blur radius
                          offset: Offset(0, 1), // Shadow offset
                        ),
                      ]),
                  child: TabBar(
                    controller: _tabController!,
                    tabs: [
                      Tab(text: "adsListing".translate(context)),
                      Tab(text: "featuredAdsLbl".translate(context)),
                    ],

                    indicatorColor: context.color.territoryColor,
                    // Line color
                    indicatorWeight: 3,

                    // Line thickness
                    labelColor: context.color.territoryColor,
                    // Selected tab text color
                    unselectedLabelColor:
                        context.color.textDefaultColor.withValues(alpha: 0.5),
                    // Unselected tab text color
                    labelStyle: TextStyle(
                      fontSize: 16,
                    ),
                    // Selected tab text style
                    labelPadding: EdgeInsets.symmetric(horizontal: 16),
                    // Padding around the tab text
                    indicatorSize: TabBarIndicatorSize.tab,
                  ),
                ),
              ],
      ),
      body: BlocListener<GetApiKeysCubit, GetApiKeysState>(
        listener: (context, state) {
          if (state is GetApiKeysSuccess) {
            setPaymentGateways(state);
          }
        },
        child: isFreeAdListingEnabled
            ? featuredAds()
            : TabBarView(
                controller: _tabController!,
                children: [
                  adsListing(),
                  featuredAds(),
                ],
              ),
      ),
    );
  }

  void showInterstitialAdIfNotShown() {
    if (!isInterstitialAdShown) {
      AdHelper.showInterstitialAd();
      isInterstitialAdShown = true; // Update the flag
    }
  }

  Builder adsListing() {
    return Builder(builder: (context) {
      showInterstitialAdIfNotShown();

      return BlocBuilder<FetchAdsListingSubscriptionPackagesCubit,
          FetchAdsListingSubscriptionPackagesState>(builder: (context, state) {
        if (state is FetchAdsListingSubscriptionPackagesInProgress) {
          return Center(
            child: UiUtils.progress(),
          );
        }
        if (state is FetchAdsListingSubscriptionPackagesFailure) {
          if (state.errorMessage is ApiException) {
            if (state.errorMessage == "no-internet") {
              return NoInternet(
                onRetry: () {
                  context
                      .read<FetchAdsListingSubscriptionPackagesCubit>()
                      .fetchPackages();
                },
              );
            }
          }

          return const SomethingWentWrong();
        }
        if (state is FetchAdsListingSubscriptionPackagesSuccess) {
          if (state.subscriptionPackages.isEmpty) {
            return NoDataFound(
              onTap: () {
                context
                    .read<FetchAdsListingSubscriptionPackagesCubit>()
                    .fetchPackages();
              },
            );
          }

          return PageView.builder(
              onPageChanged: onPageChanged,
              //update index and fetch nex index details
              controller: adsPageController,
              itemBuilder: (context, index) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (context) => AssignFreePackageCubit(),
                    ),
                    BlocProvider(
                      create: (context) => GetPaymentIntentCubit(),
                    ),
                  ],
                  child: ItemListingSubscriptionPlansItem(
                    itemIndex: currentIndex,
                    index: index,
                    model: state.subscriptionPackages[index],
                    inAppPurchaseManager: _inAppPurchaseManager,
                  ),
                );
              },
              itemCount: state.subscriptionPackages.length);
        }

        return Container();
      });
    });
  }

  Widget featuredAds() {
    showInterstitialAdIfNotShown();
    return BlocBuilder<FetchFeaturedSubscriptionPackagesCubit,
        FetchFeaturedSubscriptionPackagesState>(builder: (context, state) {
      if (state is FetchFeaturedSubscriptionPackagesInProgress) {
        return Center(
          child: UiUtils.progress(),
        );
      }
      if (state is FetchFeaturedSubscriptionPackagesFailure) {
        if (state.errorMessage is ApiException) {
          if (state.errorMessage == "no-internet") {
            return NoInternet(
              onRetry: () {
                context
                    .read<FetchFeaturedSubscriptionPackagesCubit>()
                    .fetchPackages();
              },
            );
          }
        }

        return const SomethingWentWrong();
      }
      if (state is FetchFeaturedSubscriptionPackagesSuccess) {
        if (state.subscriptionPackages.isEmpty) {
          return NoDataFound(
            onTap: () {
              context
                  .read<FetchFeaturedSubscriptionPackagesCubit>()
                  .fetchPackages();
            },
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => AssignFreePackageCubit(),
            ),
            BlocProvider(
              create: (context) => GetPaymentIntentCubit(),
            ),
          ],
          child: FeaturedAdsSubscriptionPlansItem(
            modelList: state.subscriptionPackages,
            inAppPurchaseManager: _inAppPurchaseManager,
          ),
        );
      }

      return Container();
    });
  }

  void setPaymentGateways(GetApiKeysSuccess state) {
    AppSettings.stripeCurrency = state.stripeCurrency ?? "";
    AppSettings.stripePublishableKey = state.stripePublishableKey ?? "";
    AppSettings.stripeStatus = state.stripeStatus;
    AppSettings.payStackCurrency = state.payStackCurrency ?? "";
    AppSettings.payStackKey = state.payStackApiKey ?? "";
    AppSettings.payStackStatus = state.payStackStatus;
    AppSettings.razorpayKey = state.razorPayApiKey ?? "";
    AppSettings.kelpayApiKey=state.kelpayApiKey ?? "";
    AppSettings.kelpayPayCurrency=state.kelpayPayCurrency ?? "";
    AppSettings.kelpayStatus=state.kelpayStatus;
    AppSettings.razorpayStatus = state.razorPayStatus;
    AppSettings.phonePeCurrency = state.phonePeCurrency ?? "";
    AppSettings.phonePeKey = state.phonePeKey ?? "";
    AppSettings.phonePeStatus = state.phonePeStatus;
    AppSettings.flutterwaveKey = state.flutterWaveKey ?? "";
    AppSettings.flutterwaveCurrency = state.flutterWaveCurrency ?? "";
    AppSettings.flutterwaveStatus = state.flutterWaveStatus;
    AppSettings.phonePeCurrency = state.phonePeCurrency ?? "";
    AppSettings.bankAccountNumber = state.bankAccountNumber ?? "";
    AppSettings.bankAccountHolderName = state.bankAccountHolder ?? "";
    AppSettings.bankIfscSwiftCode = state.bankIfscSwiftCode ?? "";
    AppSettings.bankName = state.bankName ?? "";
    AppSettings.bankTransferStatus = state.bankTransferStatus;

    AppSettings.updatePaymentGateways();
  }
}
