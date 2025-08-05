import 'dart:io';

import 'package:SombaTeka/data/cubits/subscription/bank_transfer_update_cubit.dart';
import 'package:SombaTeka/data/cubits/utility/fetch_transactions_cubit.dart';
import 'package:SombaTeka/data/helper/widgets.dart';
import 'package:SombaTeka/data/model/transaction_model.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/no_data_found.dart';
import 'package:SombaTeka/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:SombaTeka/ui/screens/widgets/intertitial_ads_screen.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/helper_utils.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) {
        return const TransactionHistory();
      },
    );
  }

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  late final ScrollController _controller = ScrollController()
    ..addListener(() {
      if (_controller.offset >= _controller.position.maxScrollExtent) {
        if (context.read<FetchTransactionsCubit>().hasMoreData()) {
          setState(() {});
          context.read<FetchTransactionsCubit>().fetchTransactionsMore();
        }
      }
    });

  //late final ScrollController _pageScrollController = ScrollController();
  File? receiptImage;
  bool isUploading = false;

  @override
  void initState() {
    AdHelper.loadInterstitialAd();
    getTransaction();
    super.initState();
  }

  void getTransaction() async {
    context.read<FetchTransactionsCubit>().fetchTransactions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void showPicker(String transactionId) {
    UiUtils.imagePickerBottomSheet(
      context,
      callback: (bool isRemoved, ImageSource? source) async {
        if (source != null) {
          _imgFromGallery(source, transactionId);
        }
      },
    );
  }

  void _imgFromGallery(ImageSource imageSource, String transactionId) async {
    if (isUploading) return; // Prevent multiple selections while uploading

    final pickedFile = await ImagePicker().pickImage(
      source: imageSource,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      receiptImage = File(pickedFile.path);

      isUploading = true; // Set flag to true before API call
      setState(() {}); // Update UI

      context.read<BankTransferUpdateCubit>().bankTransferUpdate(
            paymentTransactionId: transactionId,
            paymentReceipt: receiptImage!,
          );
    } else {
      receiptImage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    AdHelper.showInterstitialAd();
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: UiUtils.buildAppBar(
        context,
        showBackButton: true,
        title: "transactionHistory".translate(context),
      ),
      body: RefreshIndicator(
        color: context.color.territoryColor,
        onRefresh: () async {
          getTransaction();
        },
        child: BlocListener<BankTransferUpdateCubit, BankTransferUpdateState>(
          listener: (context, state) {
            if (state is BankTransferUpdateInProgress) {
              Widgets.showLoader(context);
            } else {
              isUploading = false; // Reset flag after upload completes
              setState(() {});
              Widgets.hideLoder(context);
            }

            if (state is BankTransferUpdateInSuccess) {
              context.read<FetchTransactionsCubit>().updateTransactionStatus(
                    state.transactionId,
                  );

              HelperUtils.showSnackBarMessage(context, state.responseMessage);
            } else if (state is BankTransferUpdateFailure) {
              HelperUtils.showSnackBarMessage(context, state.error.toString());
            }
          },
          child: BlocBuilder<FetchTransactionsCubit, FetchTransactionsState>(
            builder: (context, state) {
              if (state is FetchTransactionsInProgress) {
                return Center(child: UiUtils.progress());
              }
              if (state is FetchTransactionsFailure) {
                return const SomethingWentWrong();
              }
              if (state is FetchTransactionsSuccess) {
                if (state.transactionModel.isEmpty) {
                  return NoDataFound(
                    onTap: () {
                      getTransaction();
                    },
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        controller: _controller,
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: state.transactionModel.length,
                        padding: const EdgeInsets.symmetric(
                          vertical: 7.0,
                          horizontal: 16,
                        ),
                        separatorBuilder: (context, index) {
                          return SizedBox(height: 7);
                        },
                        itemBuilder: (context, index) {
                          TransactionModel transaction =
                              state.transactionModel[index];

                          return Container(
                            // height: 100,
                            //margin: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 16),
                            decoration: BoxDecoration(
                              color: context.color.secondaryColor,
                              border: Border.all(
                                color: context.color.borderColor,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              0,
                              12,
                              16,
                              12,
                            ),
                            child: customTransactionItem(context, transaction),
                          );
                        },
                      ),
                    ),
                    if (state.isLoadingMore)
                      UiUtils.progress(
                        normalProgressColor: context.color.territoryColor,
                      ),
                  ],
                );
              }

              return Container();
            },
          ),
        ),
      ),
    );
  }

  Widget customTransactionItem(
    BuildContext context,
    TransactionModel transaction,
  ) {
    return Builder(
      builder: (context) {
        return Row(
          spacing: 15,
          children: [
            Container(
              width: 4,
              height: 41,
              decoration: BoxDecoration(
                color: context.color.territoryColor,
                borderRadius: const BorderRadiusDirectional.only(
                  topEnd: Radius.circular(4),
                  bottomEnd: Radius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: context.color.territoryColor.withValues(
                        alpha: 0.1,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 7),
                    child: CustomText(
                      transaction.paymentGateway!,
                      fontSize: context.font.small,
                      color: context.color.territoryColor,
                    ),
                  ),
                  Row(
                    spacing: 7,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        flex: 2,
                        child: CustomText(
                          transaction.orderId != null
                              ? transaction.orderId.toString()
                              : "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await HapticFeedback.vibrate();
                          var clipboardData = ClipboardData(
                            text: transaction.orderId ?? "",
                          );
                          Clipboard.setData(clipboardData).then((_) {
                            HelperUtils.showSnackBarMessage(
                              context,
                              'copied'.translate(context),
                            );
                          });
                        },
                        child: Container(
                          height: 30,
                          width: 30,
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            color: context.color.secondaryColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.color.borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(Icons.copy, size: context.font.larger),
                        ),
                      ),
                    ],
                  ),
                  CustomText(
                    transaction.createdAt.toString().formatDate(),
                    fontSize: context.font.small,
                  ),
                ],
              ),
            ),
            Column(
              spacing: 6,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  "${Constant.currencySymbol}\t${transaction.amount}",
                  fontWeight: FontWeight.w700,
                  color: context.color.territoryColor,
                ),
                statusAndAttachment(transaction),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget statusAndAttachment(TransactionModel transaction) {
    if (transaction.paymentGateway == "BankTransfer" &&
        transaction.paymentStatus == 'pending')
      return UiUtils.buildButton(
        context,
        onPressed: () {
          if (isUploading) {
            return;
          } else {
            showPicker(transaction.id.toString());
          }
        },
        buttonTitle: "uploadReceipt".translate(context),
        width: 30,
        height: 35,
        fontSize: 12,
        radius: 5,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      );
    else
      return CustomText(transaction.paymentStatus!.toString().firstUpperCase());
  }
}
