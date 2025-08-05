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
import 'package:intl/intl.dart' as intl;

class ItemListingSubscriptionPlansItem extends StatefulWidget {
  final int itemIndex, index;
  final SubscriptionPackageModel model;
  final InAppPurchaseManager inAppPurchaseManager;

  const ItemListingSubscriptionPlansItem({
    super.key,
    required this.itemIndex,
    required this.index,
    required this.model,
    required this.inAppPurchaseManager,
  });

  @override
  _ItemListingSubscriptionPlansItemState createState() =>
      _ItemListingSubscriptionPlansItemState();
}

class _ItemListingSubscriptionPlansItemState
    extends State<ItemListingSubscriptionPlansItem> {
  String? _selectedGateway;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid && AppSettings.stripeStatus == 1) {
      StripeService.initStripe(
        AppSettings.stripePublishableKey,
        "test",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        bottomNavigationBar: bottomWidget(),
        body:
            Padding(
                padding: EdgeInsets.only(
                    top: (widget.index == widget.itemIndex) ? 40 : 70,
                    bottom: (widget.index == widget.itemIndex) ? 100 : 120),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (widget.model.isActive!)
                      ClipPath(
                        clipper: CapShapeClipper(),
                        child: Container(
                          alignment: Alignment.center,
                          color: context.color.territoryColor,
                          width: MediaQuery.of(context).size.width / 1.6,
                          height: 33,
                          padding: EdgeInsets.only(top: 3),
                          child: CustomText('activePlanLbl'.translate(context),
                              color: context.color.secondaryColor,
                              textAlign: TextAlign.center,
                              fontWeight: FontWeight.w500,
                              fontSize: 15),
                        ),
                      ),
                    Card(
                      color: context.color.secondaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side: BorderSide(
                              color: widget.model.isActive!
                                  ? context.color.territoryColor
                                  : context.color.secondaryColor,
                              width: 1.5)),
                      elevation: 0,
                      margin: EdgeInsets.fromLTRB(14, 33, 14, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start, //temp
                        children: [
                          SizedBox(height: 50),
                          ClipPath(
                            clipper: HexagonClipper(),
                            child: Container(
                              width: 100,
                              height: 110,
                              padding: EdgeInsets.all(30),
                              color: context.color.primaryColor,
                              child: UiUtils.imageType(widget.model.icon!,
                                  fit: BoxFit.contain),
                            ),
                          ),
                          SizedBox(height: 18),
                          activeAdsData(widget.model.isActive! &&
                              widget.model.finalPrice! > 0),
                          const Spacer(),
                          CustomText(
                            widget.model.finalPrice! > 0
                                ? widget.model.finalPrice!.currencyFormat
                                : "free".translate(context),
                            fontSize: context.font.xxLarge,
                            fontWeight: FontWeight.bold,
                            color: context.color.textDefaultColor,
                          ),
                          if (widget.model.discount! > 0)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                spacing: 5,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomText(
                                    "${widget.model.discount}%\t${"OFF".translate(context)}",
                                    color: context.color.forthColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  Text(
                                    " ${Constant.currencySymbol}${widget.model.price.toString()}",
                                    style: const TextStyle(
                                        decoration: TextDecoration.lineThrough),
                                  )
                                ],
                              ),
                            ),
                          payButtonWidget()
                        ],
                      ),
                    ),
                  ],
                )),
      ),
    );
  }

  Widget activeAdsData(bool isActiveAds) {
    return Expanded(
      flex: 10,
      child: ListView(
        physics: BouncingScrollPhysics(),
        shrinkWrap: true,
        children: [
          CustomText(
            widget.model.name!,
            firstUpperCaseWidget: true,
            fontWeight: FontWeight.w600,
            fontSize: context.font.larger,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          if (widget.model.type == Constant.itemTypeListing ||
              widget.model.type == Constant.itemTypeAdvertisement) ...[
            if (isActiveAds)
              checkmarkPoint(context,
                  "${widget.model.userPurchasedPackages![0].remainingItemLimit}/${widget.model.limit == Constant.itemLimitUnlimited ? "unlimitedLbl".translate(context) : widget.model.limit.toString()}\t${(widget.model.type == Constant.itemTypeListing ? "adsListing" : "featuredAdsListing").translate(context)}")
            else
              checkmarkPoint(context,
                  "${widget.model.limit == Constant.itemLimitUnlimited ? "unlimitedLbl".translate(context) : widget.model.limit.toString()}\t${(widget.model.type == Constant.itemTypeListing ? "adsListing" : "featuredAdsListing").translate(context)}"),
          ],
          if (isActiveAds)
            checkmarkPoint(context,
                "${widget.model.userPurchasedPackages![0].remainingDays}/${widget.model.duration.toString()}\t${"days".translate(context)}")
          else
            checkmarkPoint(context,
                "${widget.model.duration.toString()}\t${"days".translate(context)}"),
          if (widget.model.description != null &&
              widget.model.description!.trim().isNotEmpty)
            Container(
              alignment: AlignmentDirectional.centerStart,
              padding:
                  const EdgeInsetsDirectional.only(start: 20, end: 20, top: 20),
              child: CustomText(
                widget.model.description!,
                color: context.color.textDefaultColor.withValues(alpha: 0.7),
                textAlign: TextAlign.start,
              ),
            ),
        ],
      ),
    );
  }

  SingleChildRenderObjectWidget bottomWidget() {
    if (widget.model.isActive! &&
        widget.model.finalPrice! > 0 &&
        widget.model.userPurchasedPackages != null &&
        widget.model.userPurchasedPackages![0].endDate != null) {
      DateTime dateTime =
          DateTime.parse(widget.model.userPurchasedPackages![0].endDate!);
      String formattedDate = intl.DateFormat.yMMMMd().format(dateTime);
      return Padding(
        padding: EdgeInsetsDirectional.only(
            bottom: 15.0,
            start: 15,
            end: 15), // EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: CustomText(
            "${"yourSubscriptionWillExpireOn".translate(context)} $formattedDate"),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget checkmarkPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        // width: context.screenWidth * 0.55,
        children: [
          UiUtils.getSvg(
            AppIcons.active_mark,
          ),
          Expanded(
              child: CustomText(
            text,
            textAlign: TextAlign.start,
          )),
        ],
      ),
    );
  }

  Widget payButtonWidget() {
    return PlanHelper().purchaseButtonWidget(
        context, widget.model, _selectedGateway,
        iosCallback: (String productId, String packageId) {
          widget.inAppPurchaseManager.buy(productId, packageId);
        },
        btnTitle: widget.model.isActive ?? false
            ? "purchased".translate(context)
            : "purchaseThisPackage".translate(context),
        changePaymentGateway: (String selectedPaymentGateway) {
          setState(() {
            _selectedGateway = selectedPaymentGateway;
          });
        });
  }
}
