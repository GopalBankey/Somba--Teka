import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:SombaTeka/data/cubits/subscription/kelpay_payment_bloc.dart';
import 'package:SombaTeka/settings.dart';
import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/helper_utils.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/payment/gateaways/stripe_service.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentGateways {
  static String generateReference(String email) {
    late String platform;
    if (Platform.isIOS) {
      platform = 'I';
    } else if (Platform.isAndroid) {
      platform = 'A';
    }
    String reference =
        '${platform}_${email.split("@").first}_${DateTime.now().millisecondsSinceEpoch}';
    return reference;
  }

  static Future<void> stripe(BuildContext context,
      {required double price,
      required int packageId,
      required dynamic paymentIntent}) async {
    String paymentIntentId = paymentIntent["id"].toString();
    String clientSecret =
        paymentIntent['payment_gateway_response']["client_secret"].toString();

    await StripeService.payWithPaymentSheet(
      context: context,
      merchantDisplayName: Constant.appName,
      amount: paymentIntent["amount"].toString(),
      currency: AppSettings.stripeCurrency,
      clientSecret: clientSecret,
      paymentIntentId: paymentIntentId,
    );
  }

  static Future<void> phonepeCheckSum(
      {required BuildContext context, required dynamic getData}) async {
    PhonePePaymentSdk.init(getData["Phonepe_environment_mode"],
            getData["merchant_id"], getData["appId"], true)
        .then((isInitialized) {
      startPaymentPhonePe(
          context: context,
          jsonData: getData["payload"],
          checksums: getData["checksum"],
          callBackUrl: getData["callback_url"]);
    }).catchError((error) {
      return error;
    });
  }

  static void startPaymentPhonePe(
      {required BuildContext context,
      required Map<String, dynamic> jsonData,
      required String checksums,
      required String callBackUrl}) async {
    try {
      String body = '';
      String base64Data = base64Encode(utf8.encode(jsonEncode(jsonData)));
      body = base64Data;

      PhonePePaymentSdk.startTransaction(
              body, callBackUrl, checksums, Constant.packageName)
          .then((response) async {
        if (response != null) {
          String status = response['status'].toString();
          if (status == 'SUCCESS') {
            HelperUtils.showSnackBarMessage(
                context, "paymentSuccessfullyCompleted".translate(context));

            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            HelperUtils.showSnackBarMessage(
                context, "purchaseFailed".translate(context),
                type: MessageType.error);
          }
        } else {
          HelperUtils.showSnackBarMessage(
              context, "purchaseFailed".translate(context),
              type: MessageType.error);
        }
      }).catchError((error) {
        HelperUtils.showSnackBarMessage(context, error,
            type: MessageType.error);

        return;
      });
    } catch (error) {}
  }

  static void razorpay(
      {required BuildContext context,
      required price,
      required orderId,
      required packageId}) {
    final Razorpay razorpay = Razorpay();

    var options = {
      'key': AppSettings.razorpayKey,
      'amount': price! * 100,
      'name': HiveUtils.getUserDetails().name ?? "",
      'description': '',
      'order_id': orderId,
      'prefill': {
        'contact': HiveUtils.getUserDetails().mobile ?? "",
        'email': HiveUtils.getUserDetails().email ?? ""
      },
      "notes": {"package_id": packageId, "user_id": HiveUtils.getUserId()},
    };

    if (AppSettings.razorpayKey != "") {
      razorpay.open(options);
      razorpay.on(
        Razorpay.EVENT_PAYMENT_SUCCESS,
        (
          PaymentSuccessResponse response,
        ) async {
          await _purchase(context);
        },
      );
      razorpay.on(
        Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse response) {
          HelperUtils.showSnackBarMessage(
              context, "purchaseFailed".translate(context));
        },
      );
      razorpay.on(
        Razorpay.EVENT_EXTERNAL_WALLET,
        (e) {},
      );
    } else {
      HelperUtils.showSnackBarMessage(context, "setAPIkey".translate(context));
    }
  }

  static Future<void> _purchase(BuildContext context) async {
    try {
      Future.delayed(
        Duration.zero,
        () {
          HelperUtils.showSnackBarMessage(context, "success".translate(context),
              type: MessageType.success, messageDuration: 5);

          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } catch (e) {
      HelperUtils.showSnackBarMessage(
          context, "purchaseFailed".translate(context),
          type: MessageType.error);
    }
  }

  static Future<void> showKelpayPaymentDialog(
      BuildContext context, String txId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return BlocProvider(
          create: (_) => KelpayPaymentBloc()..add(StartKelpayPayment(txId)),
          child: BlocListener<KelpayPaymentBloc, KelpayPaymentState>(
            listenWhen: (prev, curr) => prev.status != curr.status,
            listener: (context, state) {
              if (state.status == "timeout") {
                // Auto close dialog at 5:05 if still pending
                Navigator.of(context).pop();
                HelperUtils.showSnackBarMessage(
                    messageDuration: 5,
                    context,
                    "paymentStillPending".translate(context),
                    type: MessageType.error);
              }
            },
            child: BlocBuilder<KelpayPaymentBloc, KelpayPaymentState>(
              builder: (context, state) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: buildStatusText(context, state, txId: txId),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${"remainingTime".translate(context)}: ${state.remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:${state.remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      )
                      // Text("Time Elapsed: ${_formatDuration(state.elapsed)}"),
                    ],
                  ),
                  actions: [
                    if (state.status == "succeed" ||
                        state.status == "failed" ||
                        state.status == "timeout")
                      TextButton(
                        onPressed: () {
                          Navigator.of(context)
                            .popUntil((route) => route.isFirst);},
                        child: const Text("Close"),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  static Widget buildStatusText(BuildContext context, KelpayPaymentState state,
      {required String txId}) {
    switch (state.status) {
      case "succeed":
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 50, color: Colors.green),
            SizedBox(height: 10),
            Text(
              "paymentSuccessfullyCompleted".translate(context),
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "thankYouForSubscription".translate(context),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        );

      case "failed":
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, size: 50, color: Colors.red),
            SizedBox(height: 10),
            Text(
              "paymentFailed".translate(context),
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "useAnotherPaymentMethod".translate(context),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        );

      case "timeout":
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_disabled, size: 50, color: Colors.orange),
            SizedBox(height: 10),
            Text(
              "paymentTimeout".translate(context),
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            Text(
              "pleaseTryAgain".translate(context),
              style: TextStyle(color: Colors.black54),
            ),
          ],
        );

      case "pending":
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_outlined,
              size: 50,
              color: Colors.blue,
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              "paymentRequestSent".translate(context),
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "paymentPending".translate(context),
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              "paymentRequestSentToYourMobile".translate(context),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            if (state.status == "pending") ...[
              UiUtils.progress(),
            ],
            Text(
              "waitingForTheConfirmation".translate(context),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            Text(
              '${"transactionId".translate(context)} ${txId}',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
          ],
        );

      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 15,
          children: [
            Icon(
              Icons.check_circle,
              size: 50,
              color: Colors.green,
            ),
            Text(
              "paymentRequestSent".translate(context),
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        );
    }
  }
}
