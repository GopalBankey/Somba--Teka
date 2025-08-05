import 'dart:io';
import 'package:SombaTeka/data/model/subscription_package_model.dart';
import 'package:SombaTeka/settings.dart';
import 'package:SombaTeka/ui/screens/subscription/widget/planHelper.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/app_icon.dart';
import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/extensions/lib/currency_formatter.dart';
import 'package:SombaTeka/utils/payment/gateaways/inapp_purchase_manager.dart';
import 'package:SombaTeka/utils/payment/gateaways/stripe_service.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class FeaturedAdsSubscriptionPlansItem extends StatefulWidget {
  final List<SubscriptionPackageModel> modelList;
  final InAppPurchaseManager inAppPurchaseManager;

  const FeaturedAdsSubscriptionPlansItem({
    super.key,
    required this.modelList,
    required this.inAppPurchaseManager,
  });

  @override
  _FeaturedAdsSubscriptionPlansItemState createState() =>
      _FeaturedAdsSubscriptionPlansItemState();
}

class _FeaturedAdsSubscriptionPlansItemState
    extends State<FeaturedAdsSubscriptionPlansItem> {
  String? _selectedGateway;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      if (AppSettings.stripeStatus == 1) {
        StripeService.initStripe(
          AppSettings.stripePublishableKey,
          "test",
        );
      }
    }
  }

  Widget mainUi() {
    return Container(
      height: MediaQuery.of(context).size.height,
      margin: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Card(
        color: context.color.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        elevation: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, //temp
          children: [
            SizedBox(
              height: 50,
            ),
            UiUtils.getSvg(AppIcons.featuredAdsIcon),
            SizedBox(
              height: 35,
            ),
            CustomText(
              "featureAd".translate(context),
              fontWeight: FontWeight.w600,
              fontSize: context.font.larger,
            ),
            Expanded(
              child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  itemBuilder: (context, index) {
                    return itemData(index);
                  },
                  itemCount: widget.modelList.length),
            ),
            if (selectedIndex != null) payButtonWidget(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        body: mainUi(),
      ),
    );
  }

  Widget itemData(int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 7.0),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          if (widget.modelList[index].isActive!)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 13.0),
              child: ClipPath(
                clipper: CapShapeClipper(),
                child: Container(
                  color: context.color.territoryColor,
                  width: MediaQuery.of(context).size.width / 3,
                  height: 17,
                  padding: EdgeInsets.only(top: 3),
                  child: CustomText('activePlanLbl'.translate(context),
                      color: context.color.secondaryColor,
                      textAlign: TextAlign.center,
                      fontWeight: FontWeight.w500,
                      fontSize: 12),
                ),
              ),
            ),
          InkWell(
            onTap: !widget.modelList[index].isActive!
                ? () {
                    setState(() {
                      selectedIndex = index;
                    });
                  }
                : null,
            child: Container(
              margin: EdgeInsets.only(top: 17),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                      color: widget.modelList[index].isActive! ||
                              index == selectedIndex
                          ? context.color.territoryColor
                          : context.color.textDefaultColor
                              .withValues(alpha: 0.13),
                      width: 1.5)),
              child: !widget.modelList[index].isActive!
                  ? adsWidget(index)
                  : activeAdsWidget(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget adsWidget(int index) {
    return Row(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                widget.modelList[index].name!,
                firstUpperCaseWidget: true,
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    '${widget.modelList[index].limit == Constant.itemLimitUnlimited ? "unlimitedLbl".translate(context) : widget.modelList[index].limit.toString()}\t${"adsLbl".translate(context)}\t\t·\t\t',
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    color:
                        context.color.textDefaultColor.withValues(alpha: 0.5),
                  ),
                  Flexible(
                    child: CustomText(
                      '${widget.modelList[index].duration.toString()}\t${"days".translate(context)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      color: context.color.textDefaultColor.withAlpha(50),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        CustomText(
          widget.modelList[index].finalPrice! > 0
              ? widget.modelList[index].finalPrice!.currencyFormat
              : "free".translate(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }

  Widget activeAdsWidget(int index) {
    return Row(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                widget.modelList[index].name!,
                firstUpperCaseWidget: true,
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: widget.modelList[index].limit ==
                              Constant.itemLimitUnlimited
                          ? "${"unlimitedLbl".translate(context)}\t${"adsLbl".translate(context)}\t\t·\t\t"
                          : '',
                      style: TextStyle(
                        color: context.color.textDefaultColor
                            .withValues(alpha: 0.5),
                      ),
                      children: textRichChildNotForUnlimited(
                          widget.modelList[index].limit ==
                              Constant.itemLimitUnlimited,
                          '${widget.modelList[index].userPurchasedPackages![0].remainingItemLimit}',
                          '/${widget.modelList[index].limit.toString()}\t${"adsLbl".translate(context)}\t\t·\t\t'),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: widget.modelList[index].duration ==
                                Constant.itemLimitUnlimited
                            ? "${"unlimitedLbl".translate(context)}\t${"days".translate(context)}"
                            : '',
                        style: TextStyle(
                          color: context.color.textDefaultColor
                              .withValues(alpha: 0.5),
                        ),
                        children: textRichChildNotForUnlimited(
                          widget.modelList[index].limit ==
                              Constant.itemLimitUnlimited,
                          '${widget.modelList[index].userPurchasedPackages![0].remainingDays}',
                          '/${widget.modelList[index].duration.toString()}\t${"days".translate(context)}',
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        CustomText(
          widget.modelList[index].finalPrice! > 0
              ? "${Constant.currencySymbol}${widget.modelList[index].finalPrice.toString()}"
              : "free".translate(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ],
    );
  }

  List<InlineSpan>? textRichChildNotForUnlimited(
      bool isUnlimited, String text1, String text2) {
    if (isUnlimited) return null;
    return [
      TextSpan(
        text: text1,
        style: TextStyle(color: context.color.textDefaultColor),
      ),
      TextSpan(
        text: text2,
      ),
    ];
  }

  Widget payButtonWidget() {
    return PlanHelper().purchaseButtonWidget(
        context, widget.modelList[selectedIndex!], _selectedGateway,
        iosCallback: (String productId, String packageId) {
      widget.inAppPurchaseManager.buy(productId, packageId);
    }, changePaymentGateway: (String selectedPaymentGateway) {
      setState(() {
        _selectedGateway = selectedPaymentGateway;
      });
    });
  }
}
