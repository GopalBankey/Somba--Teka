import 'dart:io';
import 'dart:ui' as ui;

import 'package:SombaTeka/app/app_theme.dart';
import 'package:SombaTeka/app/routes.dart';
import 'package:SombaTeka/data/cubits/auth/authentication_cubit.dart';
import 'package:SombaTeka/data/cubits/auth/delete_user_cubit.dart';
import 'package:SombaTeka/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:SombaTeka/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:SombaTeka/data/cubits/favorite/favorite_cubit.dart';
import 'package:SombaTeka/data/cubits/item/job_application/fetch_job_application_cubit.dart';
import 'package:SombaTeka/data/cubits/report/update_report_items_list_cubit.dart';
import 'package:SombaTeka/data/cubits/seller/fetch_verification_request_cubit.dart';
import 'package:SombaTeka/data/cubits/system/app_theme_cubit.dart';
import 'package:SombaTeka/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:SombaTeka/data/cubits/system/user_details.dart';
import 'package:SombaTeka/data/model/system_settings_model.dart';
import 'package:SombaTeka/settings.dart';
import 'package:SombaTeka/ui/screens/main_activity.dart';
import 'package:SombaTeka/ui/screens/subscription/payment_gatways.dart';
import 'package:SombaTeka/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/api.dart';
import 'package:SombaTeka/utils/app_icon.dart';
import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/helper_utils.dart';
import 'package:SombaTeka/utils/hive_keys.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/network/api_call_trigger.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin<ProfileScreen> {
  ValueNotifier isDarkTheme = ValueNotifier(false);
  final InAppReview _inAppReview = InAppReview.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool isExpanded = false;

  @override
  void initState() {
    var settings = context.read<FetchSystemSettingsCubit>();

    if (HiveUtils.isUserAuthenticated()) {
      context
          .read<FetchVerificationRequestsCubit>()
          .fetchVerificationRequests();
    }
    if (!bool.fromEnvironment(Constant.forceDisableDemoMode,
        defaultValue: false)) {
      Constant.isDemoModeOn =
          settings.getSetting(SystemSetting.demoMode) ?? false;
    }

    super.initState();
  }

  @override
  void didChangeDependencies() {
    isDarkTheme.value = context.read<AppThemeCubit>().isDarkMode();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    isDarkTheme.dispose();
    super.dispose();
  }

  Widget setIconButtons({
    required String assetName,
    required void Function() onTap,
    Color? color,
    double? height,
    double? width,
  }) {
    return Container(
      height: 36,
      width: 36,
      alignment: AlignmentDirectional.center,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: context.color.textDefaultColor.withValues(alpha: 0.1))),
      child: InkWell(
          onTap: onTap,
          child: SvgPicture.asset(
            assetName,
            height: 24,
            width: 24,
            colorFilter: color == null
                ? ColorFilter.mode(
                    context.color.territoryColor, BlendMode.srcIn)
                : ColorFilter.mode(color, BlendMode.srcIn),
          )),
    );
  }

  Widget getProfileImage() {
    Widget? profileImageWidget;
    if (HiveUtils.isUserAuthenticated()) {
      if ((HiveUtils.getUserDetails().profile ?? "").isEmpty) {
        profileImageWidget = UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else {
        profileImageWidget = UiUtils.getImage(
          height: 100,
          width: 100,
          HiveUtils.getUserDetails().profile!,
          fit: BoxFit.cover,
        );
      }
    } else {
      profileImageWidget = UiUtils.getSvg(
        AppIcons.defaultPersonLogo,
        color: context.color.territoryColor,
        fit: BoxFit.none,
      );
    }
    return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.color.territoryColor)),
        child: CircleAvatar(
            backgroundColor: context.color.backgroundColor,
            radius: 30,
            child: profileImageWidget));
  }

  String sellerStatus(String status) {
    if (status == Constant.statusPending) {
      return 'underReview'.translate(context);
    } else if (status == Constant.statusApproved) {
      return 'approved'.translate(context);
    } else if (status == 'rejected') {
      return 'rejected'.translate(context);
    } else if (status == Constant.statusResubmitted) {
      return 'resubmitted'.translate(context);
    } else {
      return '';
    }
  }

  @override
  bool get wantKeepAlive => true;

  Widget profileHeader() {
    bool isAuthenticUser = HiveUtils.isUserAuthenticated();
    return BlocBuilder<FetchVerificationRequestsCubit,
        FetchVerificationRequestState>(builder: (context, state) {
      return ValueListenableBuilder(
          valueListenable: Hive.box(HiveKeys.userDetailsBox).listenable(),
          builder: (context, Box box, _) {
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      getProfileImage(),
                      if (HiveUtils.isUserAuthenticated()) editProfileBtn(),
                    ],
                  ),
                  SizedBox(
                    width: context.screenWidth * 0.04,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (state is FetchVerificationRequestSuccess &&
                            isAuthenticUser &&
                            ((HiveUtils.getUserDetails().isVerified == 1) ||
                                state.data.status ==
                                    Constant.statusApproved)) ...[
                          verificationBadge(),
                        ],
                        SizedBox(
                          height: 5,
                        ),
                        userNameWidget(isAuthenticUser),
                        if (state is FetchVerificationRequestSuccess &&
                            isAuthenticUser &&
                            ((state.data.status) == Constant.statusRejected))
                          rejectedReasonWidget(state),
                        if (state is FetchVerificationRequestSuccess &&
                            isAuthenticUser &&
                            ((state.data.status) != Constant.statusApproved))
                          resubmitWidget(state),
                        if (isAuthenticUser &&
                            ((HiveUtils.getUserDetails().isVerified == 0) ||
                                (state is FetchVerificationRequestFail)))
                          (state is FetchVerificationRequestInProgress ||
                                  state is FetchVerificationRequestInitial ||
                                  state is FetchVerificationRequestSuccess)
                              ? SizedBox.shrink()
                              : applyForVerificationBadgeWidget(state),
                      ],
                    ),
                  ),
                  if (!isAuthenticUser) loginBtnWidget()
                ],
              ),
            );
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
          context: context, statusBarColor: context.color.secondaryColor),
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: appbarWidget(),
        body: SingleChildScrollView(
          controller: profileScreenController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(18.0),
          child: Column(spacing: 20, children: <Widget>[
            profileHeader(),
            profileMenuListWidget(),
          ]),
        ),
      ),
    );
  }

  Widget profileMenuWidget(
      String title, String svgImagePath, VoidCallback onTap,
      {bool isSwitch = false,
      dynamic switchValue,
      Function(dynamic)? onTapSwitch}) {
    return customTile(context,
        title: title.translate(context),
        svgImagePath: svgImagePath,
        isSwitchBox: isSwitch,
        onTap: onTap,
        onTapSwitch: onTapSwitch,
        switchValue: switchValue);
  }

  Widget updateTile(BuildContext context,
      {required String title,
      required String newVersion,
      required bool isUpdateAvailable,
      required String svgImagePath,
      Function(dynamic value)? onTapSwitch,
      dynamic switchValue,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: GestureDetector(
        onTap: () {
          if (isUpdateAvailable) {
            onTap.call();
          }
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.color.territoryColor
                    .withValues(alpha: 0.10000000149011612),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FittedBox(
                  fit: BoxFit.none,
                  child: isUpdateAvailable
                      ? UiUtils.getSvg(svgImagePath,
                          color: context.color.territoryColor)
                      : const Icon(Icons.done)),
            ),
            SizedBox(
              width: 25,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  isUpdateAvailable ? title : "uptoDate".translate(context),
                  fontWeight: FontWeight.w700,
                  color: context.color.textColorDark,
                ),
                if (isUpdateAvailable)
                  CustomText(
                    "v$newVersion",
                    fontWeight: FontWeight.w300,
                    color: context.color.textColorDark,
                    fontSize: context.font.small,
                    fontStyle: FontStyle.italic,
                  ),
              ],
            ),
            if (isUpdateAvailable) ...[
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border:
                      Border.all(color: context.color.borderColor, width: 1.5),
                  color: context.color.secondaryColor
                      .withValues(alpha: 0.10000000149011612),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  fit: BoxFit.none,
                  child: SizedBox(
                    width: 8,
                    height: 15,
                    child: UiUtils.getSvg(
                      AppIcons.arrowRight,
                      color: context.color.textColorDark,
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

//eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL3Rlc3Ricm9rZXJodWIud3J0ZWFtLmluL2FwaS91c2VyX3NpZ251cCIsImlhdCI6MTY5Njg1MDQyNCwibmJmIjoxNjk2ODUwNDI0LCJqdGkiOiJxVTNpY1FsRFN3MVJ1T3M5Iiwic3ViIjoiMzg4IiwicHJ2IjoiMWQwYTAyMGFjZjVjNGI2YzQ5Nzk4OWRmMWFiZjBmYmQ0ZThjOGQ2MyIsImN1c3RvbWVyX2lkIjozODh9.Y8sQhZtz6xGROEMvrTwA6gSSfPK-YwuhwDDc7Yahfg4
  Widget customTile(BuildContext context,
      {required String title,
      required String svgImagePath,
      bool? isSwitchBox,
      Function(dynamic value)? onTapSwitch,
      dynamic switchValue,
      required VoidCallback onTap}) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 0.5, bottom: 3),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: !(isSwitchBox ?? false),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.color.territoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FittedBox(
                      fit: BoxFit.none,
                      child: UiUtils.getSvg(svgImagePath,
                          height: 24,
                          width: 24,
                          color: context.color.territoryColor)),
                ),
                SizedBox(
                  width: 25,
                ),
                Expanded(
                  flex: 3,
                  child: CustomText(
                    title,
                    fontWeight: FontWeight.w700,
                    color: context.color.textColorDark,
                  ),
                ),
                const Spacer(),
                if (isSwitchBox != true)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.color.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      fit: BoxFit.none,
                      child: SizedBox(
                        width: 8,
                        height: 15,
                        child: Directionality(
                          textDirection: Directionality.of(context),
                          child: RotatedBox(
                            quarterTurns: Directionality.of(context) ==
                                    ui.TextDirection.rtl
                                ? 2
                                : -4,
                            child: UiUtils.getSvg(
                              AppIcons.arrowRight,
                              color: context.color.textColorDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isSwitchBox ?? false)
                  // CupertinoSwitch(value: value, onChanged: onChanged)
                  SizedBox(
                    height: 40,
                    width: 30,
                    child: CupertinoSwitch(
                      activeTrackColor: context.color.territoryColor,
                      value: switchValue ?? false,
                      onChanged: (value) {
                        onTapSwitch?.call(value);
                      },
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget bulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText("• "),
        SizedBox(width: 3),
        Expanded(
          child: CustomText(
            text,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  void deleteConfirmWidget() {
    UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        title: (_auth.currentUser != null)
            ? "deleteProfileMessageTitle".translate(context)
            : "deleteAlertTitle".translate(context),
        content: _auth.currentUser != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  bulletPoint("yourAdsAndTransactionDelete".translate(context)),
                  bulletPoint("accDetailsCanNotRecovered".translate(context)),
                  bulletPoint("subscriptionsCancelled".translate(context)),
                  bulletPoint(
                      "savedPreferencesAndMessagesLost".translate(context)),
                ],
              )
            : CustomText("deleteRelogin".translate(context),
                textAlign: TextAlign.center),
        cancelButtonName: (_auth.currentUser != null)
            ? 'no'.translate(context)
            : 'cancelLbl'.translate(context),
        acceptButtonName: (_auth.currentUser != null)
            ? "deleteBtnLbl".translate(context)
            : 'logout'.translate(context),
        cancelTextColor: context.color.textColorDark,
        svgImagePath: AppIcons.deleteIcon,
        isAcceptContainerPush: true,
        onAccept: () async {
          (_auth.currentUser != null)
              ? proceedToDeleteProfile()
              : askToLoginAgain();
        },
      ),
    );
  }

  void askToLoginAgain() {
    HelperUtils.showSnackBarMessage(context, 'loginReqMsg'.translate(context));
    for (int i = 0; i < AuthenticationType.values.length; i++) {
      if (AuthenticationType.values[i].name ==
          HiveUtils.getUserDetails().type) {
        signOut(AuthenticationType.values[i]).then((value) {
          HiveUtils.clear();
          Constant.favoriteItemList.clear();
          context.read<UserDetailsCubit>().clear();
          context.read<FavoriteCubit>().resetState();
          context.read<UpdatedReportItemCubit>().clearItem();
          context.read<GetBuyerChatListCubit>().resetState();
          context.read<FetchJobApplicationCubit>().resetState();
          context.read<BlockedUsersListCubit>().resetState();
          HiveUtils.logoutUser(
            context,
            onLogout: () {},
          );
          Navigator.of(context)
              .pushNamedAndRemoveUntil(Routes.login, (route) => false);
        });
      }
    }
  }

  Future<void> signOut(AuthenticationType? type) async {
    if (type == AuthenticationType.google) {
      context.read<AuthenticationCubit>().signOut();
      _googleSignIn.signOut();
    } else {
      _auth.signOut();
    }
  }

  void proceedToDeleteProfile() async {
    //delete user from firebase
    try {
      await _auth.currentUser!.delete().then((value) {
        //delete user prefs from App-local
        context.read<DeleteUserCubit>().deleteUser().then((value) {
          if (context.read<DeleteUserCubit>().state is DeleteUserFetchSuccess) {
            HelperUtils.showSnackBarMessage(
                context, 'userDeletedSuccessfully'.translate(context));
          } else {
            HelperUtils.showSnackBarMessage(context, (value["message"]));
          }

          for (int i = 0; i < AuthenticationType.values.length; i++) {
            if (AuthenticationType.values[i].name ==
                HiveUtils.getUserDetails().type) {
              signOut(AuthenticationType.values[i]).then((value) {
                HiveUtils.clear();
                Constant.favoriteItemList.clear();
                context.read<UserDetailsCubit>().clear();
                context.read<FavoriteCubit>().resetState();
                context.read<UpdatedReportItemCubit>().clearItem();
                context.read<GetBuyerChatListCubit>().resetState();
                context.read<FetchJobApplicationCubit>().resetState();
                context.read<BlockedUsersListCubit>().resetState();

                HiveUtils.logoutUser(
                  context,
                  onLogout: () {},
                );
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(Routes.login, (route) => false);
              });
            }
          }
        });
      });
    } on FirebaseAuthException catch (error) {
      if (error.code == "requires-recent-login") {
        askToLoginAgain();
      } else {
        HelperUtils.showSnackBarMessage(context, '${error.message}');
      }
    } catch (e) {
      debugPrint("unable to delete user - ${e.toString()}");
    }
  }

  Widget profileImgWidget() {
    return GestureDetector(
      onTap: () {
        if (HiveUtils.getUserDetails().profile != "" &&
            HiveUtils.getUserDetails().profile != null) {
          UiUtils.showFullScreenImage(
            context,
            provider: NetworkImage(
                context.read<UserDetailsCubit>().state.user?.profile ?? ""),
          );
        }
      },
      child: (context.watch<UserDetailsCubit>().state.user?.profile ?? "")
              .trim()
              .isEmpty
          ? buildDefaultPersonSVG(context)
          : Image.network(
              context.watch<UserDetailsCubit>().state.user?.profile ?? "",
              fit: BoxFit.cover,
              width: 49,
              height: 49,
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                return buildDefaultPersonSVG(context);
              },
              loadingBuilder: (BuildContext context, Widget? child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child!;
                return buildDefaultPersonSVG(context);
              },
            ),
    );
  }

  Widget buildDefaultPersonSVG(BuildContext context) {
    return Container(
      width: 49,
      height: 49,
      color: context.color.territoryColor.withValues(alpha: 0.1),
      child: FittedBox(
        fit: BoxFit.none,
        child: UiUtils.getSvg(AppIcons.defaultPersonLogo,
            color: context.color.territoryColor, width: 30, height: 30),
      ),
    );
  }

  void shareApp() {
    try {
      if (Platform.isAndroid) {
        SharePlus.instance.share(ShareParams(
            text:
                '${Constant.appName}\n${Constant.playstoreURLAndroid}\n${"shareApp".translate(context)}',
            subject: Constant.appName));
      } else {
        SharePlus.instance.share(ShareParams(
            text:
                '${Constant.appName}\n${Constant.appstoreURLios}\n${"shareApp".translate(context)}',
            subject: Constant.appName,
            sharePositionOrigin: Rect.fromLTWH(
                0,
                0,
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height / 2)));
      }
    } catch (e) {
      HelperUtils.showSnackBarMessage(context, e.toString());
    }
  }

  Future<void> rateUs() => _inAppReview.openStoreListing(
      appStoreId: Constant.iOSAppId, microsoftStoreId: 'microsoftStoreId');

  void logOutConfirmWidget() {
    UiUtils.showBlurredDialoge(context,
        dialoge: BlurredDialogBox(
            title: "confirmLogoutTitle".translate(context),
            onAccept: () async {
              Future.delayed(
                Duration.zero,
                () {
                  for (int i = 0; i < AuthenticationType.values.length; i++) {
                    if (AuthenticationType.values[i].name ==
                        HiveUtils.getUserDetails().type) {
                      signOut(AuthenticationType.values[i]).then((value) {
                        HiveUtils.clear();
                        Constant.favoriteItemList.clear();
                        context.read<UserDetailsCubit>().clear();
                        context.read<FavoriteCubit>().resetState();
                        context.read<UpdatedReportItemCubit>().clearItem();
                        context.read<GetBuyerChatListCubit>().resetState();
                        context.read<FetchJobApplicationCubit>().resetState();
                        context.read<BlockedUsersListCubit>().resetState();
                        HiveUtils.logoutUser(
                          context,
                          onLogout: () {},
                        );
                      });
                    }
                  }
                },
              );
            },
            cancelTextColor: context.color.textColorDark,
            svgImagePath: AppIcons.logoutIcon,
            content: CustomText("confirmLogOutMsg".translate(context))));
  }

  Widget editProfileBtn() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: InkWell(
        onTap: () {
          HelperUtils.goToNextPage(Routes.completeProfile, context, false,
              args: {"from": "profile"});
        },
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: context.color.territoryColor,
              shape: BoxShape.circle,
              border: Border.all(color: context.color.secondaryColor)),
          //alignment: Alignment.center,
          child: UiUtils.getSvg(AppIcons.editProfileIcon,
              width: 18, height: 18, fit: BoxFit.fill),
        ),
      ),
    );
  }

  Widget verificationBadge() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: context.color.forthColor,
      ),
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          UiUtils.getSvg(AppIcons.verifiedIcon, width: 14, height: 14),
          CustomText("verifiedLbl".translate(context),
              color: context.color.secondaryColor, fontWeight: FontWeight.w500),
        ],
      ),
    );
  }

  Widget userNameWidget(bool isAuthenticUser) {
    return Column(children: [
      if (isAuthenticUser) ...[
        SizedBox(
          width: context.screenWidth * 0.63,
          child: CustomText(
            HiveUtils.getUserDetails().name ?? '',
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            color: context.color.textColorDark,
            fontSize: context.font.large,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(
          height: 3,
        ),
        SizedBox(
          width: context.screenWidth * 0.63,
          child: CustomText(
            HiveUtils.getUserDetails().email ?? '',
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            color: context.color.textColorDark,
            fontSize: context.font.small,
          ),
        ),
      ] else ...[
        SizedBox(
          width: context.screenWidth * 0.4,
          child: CustomText(
            "anonymous".translate(context),
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            color: context.color.textColorDark,
            fontSize: context.font.large,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(
          height: 3,
        ),
        SizedBox(
          width: context.screenWidth * 0.4,
          child: CustomText(
            "loginFirst".translate(context),
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            color: context.color.textColorDark,
            fontSize: context.font.small,
          ),
        ),
      ]
    ]);
  }

  Widget rejectedReasonWidget(FetchVerificationRequestSuccess state) {
    return Container(
      margin: EdgeInsetsDirectional.only(top: 7),
      width: context.screenWidth * 0.63,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Measure the rendered text
          final span = TextSpan(
            text: "${state.data.rejectionReason!}\t",
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: context.font.small,
              color: Colors.red,
            ),
          );
          final tp = TextPainter(
            text: span,
            maxLines: 2,
            // Maximum number of lines before overflow
            textDirection: TextDirection.ltr,
          );
          tp.layout(maxWidth: constraints.maxWidth);

          final isOverflowing = tp.didExceedMaxLines;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CustomText(
                  "${state.data.rejectionReason!}\t",
                  maxLines: isExpanded ? null : 2,
                  softWrap: true,
                  overflow:
                      isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  color: Colors.red,
                  fontWeight: FontWeight.w400,
                  fontSize: context.font.small,
                ),
              ),
              if (isOverflowing) // Conditionally show the button
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 3),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isExpanded = !isExpanded; // Toggle the expanded state
                      });
                    },
                    child: CustomText(
                      isExpanded
                          ? "readLessLbl".translate(context)
                          : "readMoreLbl".translate(context),
                      color: context.color.textDefaultColor,
                      fontWeight: FontWeight.w400,
                      fontSize: context.font.small,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget resubmitWidget(FetchVerificationRequestSuccess state) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 12),
      child: Row(
        spacing: 12,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // IconButton(onPressed: () {
          //   PaymentGateways.showKelpayPaymentDialog(context, "25082512092600026761");
          //   }, icon: Icon(Icons.add)),
          Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: ((state).data.status == 'rejected')
                    ? Colors.red
                    : context.color.territoryColor,
              ),
              child: CustomText(
                sellerStatus((state).data.status!),
                color: context.color.secondaryColor,
                fontSize: context.font.small,
                fontWeight: FontWeight.w500,
              )),
          if ((state).data.status == 'rejected')
            InkWell(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: context.color.territoryColor,
                ),
                child: CustomText(
                  "resubmit".translate(context),
                  color: context.color.secondaryColor,
                  fontSize: context.font.small,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pushNamed(
                    context, Routes.sellerIntroVerificationScreen,
                    arguments: {"isResubmitted": true}).then((value) {
                  if (value == 'refresh') {
                    context
                        .read<FetchVerificationRequestsCubit>()
                        .fetchVerificationRequests();
                  }
                });
              },
            )
        ],
      ),
    );
  }

  Widget applyForVerificationBadgeWidget(FetchVerificationRequestState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: InkWell(
        child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: context.color.territoryColor,
            ),
            child: CustomText(
              "getVerificationBadge".translate(context),
              color: context.color.secondaryColor,
              fontSize: context.font.small,
              fontWeight: FontWeight.w500,
            )),
        onTap: () {
          if ((HiveUtils.getUserDetails().email == null ||
                  HiveUtils.getUserDetails().email!.isEmpty) ||
              (HiveUtils.getUserDetails().mobile == null ||
                  HiveUtils.getUserDetails().mobile!.isEmpty)) {
            HelperUtils.showSnackBarMessage(context,
                "pleaseFirstFillYourDetailsInProfile".translate(context));
          } else {
            Navigator.pushNamed(context, Routes.sellerIntroVerificationScreen,
                arguments: {"isResubmitted": false}).then((value) {
              if (value == 'refresh') {
                context
                    .read<FetchVerificationRequestsCubit>()
                    .fetchVerificationRequests();
              }
            });
          }
        },
      ),
    );
  }

  Widget loginBtnWidget() {
    return MaterialButton(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: context.color.textDefaultColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      onPressed: () {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.login, (route) => false);
      },
      child: CustomText("loginLbl".translate(context)),
    );
  }

  Widget profileMenuListWidget() {
    return Column(
      children: <Widget>[
        if (HiveUtils.isUserAuthenticated())
          profileMenuWidget("myFeaturedAds", AppIcons.promoted, () async {
            APICallTrigger.trigger();
            UiUtils.checkUser(
                onNotGuest: () {
                  Navigator.pushNamed(context, Routes.myAdvertisment,
                      arguments: {});
                },
                context: context);
          }),
        profileMenuWidget("subscription", AppIcons.subscription, () async {
          UiUtils.checkUser(
              onNotGuest: () {
                Navigator.pushNamed(
                    context, Routes.subscriptionPackageListRoute);
              },
              context: context);
        }),
        if (HiveUtils.isUserAuthenticated())
          profileMenuWidget("transactionHistory", AppIcons.transaction, () {
            UiUtils.checkUser(
                onNotGuest: () {
                  Navigator.pushNamed(context, Routes.transactionHistory);
                },
                context: context);
          }),
        if (HiveUtils.isUserAuthenticated())
          profileMenuWidget("myReview", AppIcons.myReviewIcon, () {
            UiUtils.checkUser(
                onNotGuest: () {
                  Navigator.pushNamed(context, Routes.myReviewsScreen);
                },
                context: context);
          }),
        if (HiveUtils.isUserAuthenticated())
          profileMenuWidget("myJobApplications", AppIcons.myJobApplicationIcon,
              () {
            UiUtils.checkUser(
                onNotGuest: () {
                  Navigator.pushNamed(context, Routes.jobApplicationList,
                      arguments: {
                        'itemId': 0,
                        'isMyJobApplications': true,
                      });
                },
                context: context);
          }),
        profileMenuWidget("language", AppIcons.language, () {
          Navigator.pushNamed(context, Routes.languageListScreenRoute);
        }),
        ValueListenableBuilder(
            valueListenable: isDarkTheme,
            builder: (context, v, c) {
              return profileMenuWidget("darkTheme", AppIcons.darkTheme, () {},
                  isSwitch: true, switchValue: v, onTapSwitch: (value) {
                context.read<AppThemeCubit>().changeTheme(
                    value == true ? AppTheme.dark : AppTheme.light);
                setState(() {
                  isDarkTheme.value = value;
                });
              });
            }),
        profileMenuWidget("notifications", AppIcons.notification, () {
          UiUtils.checkUser(
              onNotGuest: () {
                Navigator.pushNamed(context, Routes.notificationPage);
              },
              context: context);
        }),
        profileMenuWidget("blogs", AppIcons.articles, () {
          UiUtils.checkUser(
              onNotGuest: () {
                Navigator.pushNamed(
                  context,
                  Routes.blogsScreenRoute,
                );
              },
              context: context);
        }),
        if (HiveUtils.isUserAuthenticated())
          profileMenuWidget("favorites", AppIcons.favorites, () {
            UiUtils.checkUser(
                onNotGuest: () {
                  Navigator.pushNamed(context, Routes.favoritesScreen);
                },
                context: context);
          }),
        profileMenuWidget("faqsLbl", AppIcons.faqsIcon, () {
          UiUtils.checkUser(
              onNotGuest: () {
                Navigator.pushNamed(
                  context,
                  Routes.faqsScreen,
                );
              },
              context: context);
        }),
        profileMenuWidget("shareApp", AppIcons.shareApp, shareApp),
        profileMenuWidget("rateUs", AppIcons.rateUs, rateUs),
        profileMenuWidget("contactUs", AppIcons.contactUs, () {
          Navigator.pushNamed(
            context,
            Routes.contactUs,
          );
          // Navigator.pushNamed(context, Routes.ab);
        }),
        profileMenuWidget("aboutUs", AppIcons.aboutUs, () {
          Navigator.pushNamed(context, Routes.profileSettings, arguments: {
            'title': "aboutUs".translate(context),
            'param': Api.aboutUs
          });
          // Navigator.pushNamed(context, Routes.ab);
        }),
        profileMenuWidget("termsConditions", AppIcons.terms, () {
          Navigator.pushNamed(context, Routes.profileSettings, arguments: {
            'title': "termsConditions".translate(context),
            'param': Api.termsAndConditions
          });
        }),
        profileMenuWidget("privacyPolicy", AppIcons.privacy, () {
          Navigator.pushNamed(
            context,
            Routes.profileSettings,
            arguments: {
              'title': "privacyPolicy".translate(context),
              'param': Api.privacyPolicy
            },
          );
        }),
        if (Constant.isUpdateAvailable) ...[
          updateTile(
            context,
            isUpdateAvailable: Constant.isUpdateAvailable,
            title: "update".translate(context),
            newVersion: Constant.newVersionNumber,
            svgImagePath: AppIcons.update,
            onTap: () async {
              if (Platform.isIOS) {
                await launchUrl(Uri.parse(Constant.appstoreURLios));
              } else if (Platform.isAndroid) {
                await launchUrl(Uri.parse(Constant.playstoreURLAndroid));
              }
            },
          ),
        ],
        if (HiveUtils.isUserAuthenticated()) ...[
          profileMenuWidget("deleteAccount", AppIcons.delete, () {
            if (Constant.isDemoModeOn &&
                HiveUtils.getUserDetails().mobile != null) {
              String formattedMobile = HiveUtils.getUserDetails()
                  .mobile!
                  .replaceFirst("+${HiveUtils.getCountryCode()}", "");
              if (Constant.demoMobileNumber == formattedMobile) {
                HelperUtils.showSnackBarMessage(
                    context, "thisActionNotValidDemo".translate(context));
                return;
              }
            }
            deleteConfirmWidget();
          }),
        ],
        const SizedBox(
          height: 20,
        )
      ],
    );
  }

  PreferredSize appbarWidget() {
    return UiUtils.buildAppBar(context,
        showBackButton: false,
        bottomHeight: 10,
        title: "myProfile".translate(context),
        actions: [
          if (HiveUtils.isUserAuthenticated())
            setIconButtons(
              assetName: AppIcons.logout,
              onTap: () {
                logOutConfirmWidget();
              },
              color: context.color.textDefaultColor,
            ),
        ]);
  }
}
