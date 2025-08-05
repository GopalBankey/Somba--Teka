import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:SombaTeka/app/routes.dart';
import 'package:SombaTeka/data/cubits/auth/auth_cubit.dart';
import 'package:SombaTeka/data/cubits/auth/authentication_cubit.dart';
import 'package:SombaTeka/data/cubits/slider_cubit.dart';
import 'package:SombaTeka/data/cubits/system/user_details.dart';
import 'package:SombaTeka/data/model/user_model.dart';

import 'package:SombaTeka/ui/screens/widgets/custom_text_form_field.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/app_icon.dart';
import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/helper_utils.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/image_picker.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class UserProfileScreen extends StatefulWidget {
  final String from;
  final bool? navigateToHome;
  final bool? popToCurrent;

  //final AuthenticationType? type;

  const UserProfileScreen({
    super.key,
    required this.from,
    this.navigateToHome,
    this.popToCurrent,
    //required this.type,
  });

  @override
  State<UserProfileScreen> createState() => UserProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return MaterialPageRoute(
      builder: (_) => UserProfileScreen(
        from: arguments['from'] as String,
        popToCurrent: arguments['popToCurrent'] as bool?,
        //type: arguments['type'],
        navigateToHome: arguments['navigateToHome'] as bool?,
      ),
    );
  }
}

class UserProfileScreenState extends State<UserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController phoneController = TextEditingController();
  late final TextEditingController nameController = TextEditingController();
  late final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  dynamic size;
  dynamic city, _state, country;
  double? latitude, longitude;
  String? name, email, address;
  File? fileUserimg;
  bool isNotificationsEnabled = true;
  bool isPersonalDetailShow = true;
  bool? isLoading;
  String? countryCode = "+${Constant.defaultCountryCode}";
  final ImagePicker picker = ImagePicker();
  PickImage profileImagePicker = PickImage();
  bool isFromLogin = false;

  @override
  void initState() {
    super.initState();
    isFromLogin = widget.from == 'login';
    city = HiveUtils.getCityName();
    _state = HiveUtils.getStateName();
    country = HiveUtils.getCountryName();
    latitude = HiveUtils.getLatitude();
    longitude = HiveUtils.getLongitude();

    nameController.text = (HiveUtils.getUserDetails().name) ?? "";
    emailController.text = HiveUtils.getUserDetails().email ?? "";
    addressController.text = HiveUtils.getUserDetails().address ?? "";

    if (isFromLogin) {
      isNotificationsEnabled = true;
      isPersonalDetailShow = true;
    } else {
      isNotificationsEnabled =
          HiveUtils.getUserDetails().notification == 1 ? true : false;
      isPersonalDetailShow =
          HiveUtils.getUserDetails().isPersonalDetailShow == 1 ? true : false;
    }

    if (HiveUtils.getCountryCode() != null) {
      countryCode = HiveUtils.getCountryCode() ?? '';
      phoneController.text = HiveUtils.getUserDetails().mobile != null
          ? HiveUtils.getUserDetails().mobile!.replaceFirst("+$countryCode", "")
          : "";
    } else {
      phoneController.text = HiveUtils.getUserDetails().mobile != null
          ? HiveUtils.getUserDetails().mobile!
          : "";
    }

    profileImagePicker.listener((files) {
      if (files != null && files.isNotEmpty) {
        setState(() {
          fileUserimg = files.first; // Assign picked image to fileUserimg
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    profileImagePicker.dispose();
    phoneController.dispose();
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: safeAreaCondition(
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
          appBar: isFromLogin
              ? null
              : UiUtils.buildAppBar(context, showBackButton: true),
          body: Stack(
            children: [
              ScrollConfiguration(
                behavior: RemoveGlow(),
                child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                        key: _formKey,
                        child: Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Align(
                                alignment: AlignmentDirectional.center,
                                child: buildProfilePicture(),
                              ),
                              buildTextField(
                                context,
                                title: "fullName",
                                controller: nameController,
                                validator: CustomTextFieldValidator.nullCheck,
                              ),
                              buildTextField(
                                context,
                                readOnly: [
                                  AuthenticationType.email.name,
                                  AuthenticationType.google.name,
                                  AuthenticationType.apple.name
                                ].contains(HiveUtils.getUserDetails().type),
                                title: "emailAddress",
                                controller: emailController,
                                validator: CustomTextFieldValidator.email,
                              ),
                              phoneWidget(),
                              buildTextField(context,
                                  title: "addressLbl",
                                  controller: addressController,
                                  maxline: 5,
                                  textInputAction: TextInputAction.newline),
                              CustomText(
                                "notification".translate(context),
                              ),
                              buildEnableDisableSwitch(isNotificationsEnabled,
                                  (cgvalue) {
                                isNotificationsEnabled = cgvalue;
                                setState(() {});
                              }),
                              CustomText(
                                "showContactInfo".translate(context),
                              ),
                              buildEnableDisableSwitch(isPersonalDetailShow,
                                  (cgvalue) {
                                isPersonalDetailShow = cgvalue;
                                setState(() {});
                              }),
                              updateProfileBtnWidget(),
                            ]))),
              ),
              if (isLoading != null && isLoading!)
                Center(
                  child: UiUtils.progress(
                    normalProgressColor: context.color.territoryColor,
                  ),
                ),
              if (isFromLogin)
                Positioned(
                  left: 10,
                  top: 10,
                  child: BackButton(),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget phoneWidget() {
    return Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "phoneNumber".translate(context),
            color: context.color.textDefaultColor,
          ),
          CustomTextFormField(
            controller: phoneController,
            validator: CustomTextFieldValidator.phoneNumber,
            keyboard: TextInputType.phone,
            isReadOnly:
                HiveUtils.getUserDetails().type == AuthenticationType.phone.name
                    ? true
                    : false,
            fillColor: context.color.secondaryColor,
            // borderColor: context.color.borderColor.darken(10),
            onChange: (value) {
              setState(() {});
            },
            isMobileRequired: false,
            fixedPrefix: GestureDetector(
              onTap: () {
                if (HiveUtils.getUserDetails().type !=
                    AuthenticationType.phone.name) {
                  showCountryCode();
                }
              },
              child: Container(
                  width: 55,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                  alignment: Alignment.center,
                  child: CustomText(
                    formatCountryCode(countryCode!),
                    fontSize: context.font.large,
                    textAlign: TextAlign.center,
                  )),
            ),
            hintText: "phoneNumber".translate(context),
          )
        ]);
  }

  String formatCountryCode(String countryCode) {
    if (countryCode.startsWith('+')) {
      return countryCode;
    } else {
      return '+$countryCode';
    }
  }

  Widget safeAreaCondition({required Widget child}) {
    if (isFromLogin) {
      return SafeArea(child: child);
    }
    return child;
  }

  Widget buildEnableDisableSwitch(bool value, Function(bool) onChangeFunction) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
            color: context.color.textLightColor.withValues(alpha: 0.23),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
          color: context.color.secondaryColor),
      height: 60,
      width: double.infinity,
      padding: const EdgeInsetsDirectional.only(start: 16.0),
      child: Row(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            (value ? "enabled" : "disabled").translate(context),
            fontSize: context.font.large,
            color: context.color.textDefaultColor,
          ),
          CupertinoSwitch(
            activeTrackColor: context.color.territoryColor,
            value: value,
            onChanged: onChangeFunction,
          )
        ],
      ),
    );
  }

  Widget buildTextField(BuildContext context,
      {required String title,
      required TextEditingController controller,
      CustomTextFieldValidator? validator,
      bool? readOnly,
      int? maxline,
      TextInputAction? textInputAction}) {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title.translate(context),
          color: context.color.textDefaultColor,
        ),
        CustomTextFormField(
          controller: controller,
          isReadOnly: readOnly,
          validator: validator,
          // formaters: [FilteringTextInputFormatter.deny(RegExp(","))],
          fillColor: context.color.secondaryColor,
          action: textInputAction,
          maxLine: maxline,
        ),
      ],
    );
  }

  Widget getProfileImage() {
    if (fileUserimg != null) {
      return Image.file(
        fileUserimg!,
        fit: BoxFit.cover,
      );
    } else {
      if (isFromLogin) {
        if (HiveUtils.getUserDetails().profile != null &&
            HiveUtils.getUserDetails().profile!.trim().isNotEmpty) {
          return UiUtils.getImage(
            HiveUtils.getUserDetails().profile!,
            fit: BoxFit.cover,
          );
        }

        return UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else if ((HiveUtils.getUserDetails().profile ?? "").trim().isEmpty) {
        return UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else {
        return UiUtils.getImage(
          HiveUtils.getUserDetails().profile!,
          fit: BoxFit.cover,
        );
      }
    }
  }

  Widget buildProfilePicture() {
    return Stack(
      children: [
        Container(
          height: 124,
          width: 124,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: context.color.territoryColor, width: 2)),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.color.territoryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            width: 106,
            height: 106,
            child: getProfileImage(),
          ),
        ),
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: InkWell(
            onTap: showPicker,
            child: Container(
                height: 37,
                width: 37,
                alignment: AlignmentDirectional.center,
                decoration: BoxDecoration(
                    border: Border.all(
                        color: context.color.buttonColor, width: 1.5),
                    shape: BoxShape.circle,
                    color: context.color.territoryColor),
                child: SizedBox(
                    width: 15,
                    height: 15,
                    child: UiUtils.getSvg(AppIcons.edit))),
          ),
        )
      ],
    );
  }

  Future<void> validateData() async {
    if (_formKey.currentState!.validate()) {
      if (isFromLogin) {
        HiveUtils.setUserIsAuthenticated(true);
      }
      profileUpdateProcess();
    }
  }

  void profileUpdateProcess() async {
    setState(() {
      isLoading = true;
    });
    try {
      var response = await context.read<AuthCubit>().updateuserdata(context,
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          fileUserimg: fileUserimg,
          address: addressController.text,
          mobile: phoneController.text,
          notification: isNotificationsEnabled == true ? "1" : "0",
          countryCode: countryCode,
          personalDetail: isPersonalDetailShow == true ? 1 : 0);

      Future.delayed(
        Duration.zero,
        () {
          context
              .read<UserDetailsCubit>()
              .copy(UserModel.fromJson(response['data']));

          setState(() {
            isLoading = false;
          });
          HelperUtils.showSnackBarMessage(
            context,
            response['message'],
          );
          if (!isFromLogin) {
            Navigator.pop(context);
          }
        },
      );

      if (isFromLogin) {
        Future.delayed(
          Duration.zero,
          () {
            if (widget.popToCurrent ?? false) {
              Navigator.of(context)
                ..pop()
                ..pop();
            } else if (HiveUtils.getCityName() != null &&
                HiveUtils.getCityName().toString().trim().isNotEmpty) {
              HelperUtils.killPreviousPages(
                  context, Routes.main, {"from": widget.from});
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.locationPermissionScreen, (route) => false);
            }
          },
        );
      }
    } catch (e) {
      Future.delayed(Duration.zero, () {
        setState(() {
          isLoading = false;
        });
        HelperUtils.showSnackBarMessage(context, e.toString());
      });
    }
  }

  void showPicker() {
    UiUtils.imagePickerBottomSheet(
      context,
      isRemovalWidget: fileUserimg != null && isFromLogin,
      callback: (bool isRemoved, ImageSource? source) async {
        if (isRemoved) {
          setState(() {
            fileUserimg = null;
          });
        } else if (source != null) {
          await profileImagePicker.pick(
              context: context, source: source, pickMultiple: false);
        }
      },
    );
  }

  void showCountryCode() {
    showCountryPicker(
      context: context,
      showWorldWide: false,
      showPhoneCode: true,
      countryListTheme:
          CountryListThemeData(borderRadius: BorderRadius.circular(11)),
      onSelect: (Country value) {
        countryCode = value.phoneCode;
        setState(() {});
      },
    );
  }

  Widget updateProfileBtnWidget() {
    return UiUtils.buildButton(
      context,
      outerPadding: EdgeInsetsDirectional.only(top: 15),
      onPressed: () {
        if (!isFromLogin && city != null && city != "") {
          HiveUtils.setCurrentLocation(
              city: city,
              state: _state,
              country: country,
              latitude: latitude,
              longitude: longitude);

          context.read<SliderCubit>().fetchSlider(context);
        } else if (!isFromLogin) {
          HiveUtils.clearLocation();
          context.read<SliderCubit>().fetchSlider(context);
        }

        validateData();
      },
      height: 48,
      buttonTitle: "updateProfile".translate(context),
    );
  }
}
