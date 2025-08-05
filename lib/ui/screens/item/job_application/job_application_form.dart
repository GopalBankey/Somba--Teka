import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:SombaTeka/data/cubits/item/job_application/apply_job_application_cubit.dart';
import 'package:SombaTeka/data/cubits/item/job_application/fetch_job_application_cubit.dart';
import 'package:SombaTeka/data/model/item/item_model.dart';
import 'package:SombaTeka/data/model/item/job_application.dart';
import 'package:SombaTeka/ui/screens/widgets/custom_text_form_field.dart';
import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/helper_utils.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/image_picker.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

class JobApplicationForm extends StatefulWidget {
  final ItemModel item;
  const JobApplicationForm({Key? key, required this.item}) : super(key: key);

  @override
  _JobApplicationFormState createState() => _JobApplicationFormState();
  static Route route(RouteSettings routeSettings) {
    return MaterialPageRoute(
        builder: (_) => JobApplicationForm(
              item: routeSettings.arguments as ItemModel,
            ));
  }
}

class _JobApplicationFormState extends State<JobApplicationForm> {
  //Text Controllers
  final TextEditingController nameController = TextEditingController(text: '');
  final TextEditingController emailController = TextEditingController(text: '');
  final TextEditingController phoneController = TextEditingController(text: '');
  final PickImage attachmentPicker = PickImage();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? pickedFile;
  String? countryCode, countryName, flagEmoji;
  CountryService countryCodeService = CountryService();
  bool isBack = false;
  @override
  void initState() {
    super.initState();
     if (HiveUtils.isUserAuthenticated()) {
      final userDetails = HiveUtils.getUserDetails();
      nameController.text = userDetails.name ?? '';
      emailController.text = userDetails.email ?? '';
      phoneController.text = userDetails.mobile ?? '';
      countryCode = userDetails.mobile?.split(' ').first;
    }
    UiUtils.getSimCountry().then((value) {
      countryCode = value.phoneCode;

      flagEmoji = value.flagEmoji;
      setState(() {});
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ApplyJobApplicationCubit(),
      child: BlocConsumer<ApplyJobApplicationCubit, ApplyJobApplicationState>(
        listener: (context, state) {
          if (state is ApplyJobApplicationSuccess) {
            dynamic data = state.data;
            context.read<FetchJobApplicationCubit>().addJobApplication(
                JobApplication(
                    itemId: data['item_id'] is String
                        ? int.parse(data['item_id'])
                        : data['item_id'],
                    userId: data['user_id'],
                    recruiterId: data['recruiter_id'],
                    fullName: data['full_name'],
                    email: data['email'],
                    mobile: data['mobile'],
                    resume: data['resume'],
                    createdAt: data['created_at'],
                    id: data['id']));
            HelperUtils.showSnackBarMessage(context, state.successMessage);
            Navigator.of(context).pop();
          }
          if (state is ApplyJobApplicationFail) {
            HelperUtils.showSnackBarMessage(context, state.error);
          }
        },
        builder: (context, state) {
          return PopScope(
            canPop: isBack,
            onPopInvokedWithResult: (didPop, result) {
              setState(() {
                isBack = state is! ApplyJobApplicationInProgress;
              });
            },
            child: Scaffold(
              appBar: UiUtils.buildAppBar(context,
                  showBackButton: true,
                  title: "jobApplicationForm".translate(context)),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(18.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      buildTextField(
                        context,
                        title: "fullName",
                        hintText: "provideFullNameHere".translate(context),
                        controller: nameController,
                        validator: CustomTextFieldValidator.nullCheck,
                      ),
                      buildMobileField(),
                      buildTextField(
                        context,
                        title: "emailAddress",
                        hintText: "emailAddressHere".translate(context),
                        controller: emailController,
                        validator: CustomTextFieldValidator.email,
                      ),
                      attachmentWidget(),
                      SizedBox(
                        height: 25,
                      ),
                      state is ApplyJobApplicationInProgress
                          ? Center(
                              child: CircularProgressIndicator(
                                color: context.color.territoryColor,
                                strokeWidth: 2,
                              ),
                            )
                          : UiUtils.buildButton(context, onPressed: () {
                              if (state is ApplyJobApplicationInProgress)
                                return;
                              if (_formKey.currentState!.validate()) {
                                Map<String, dynamic> data = {};
                                data['item_id'] = widget.item.id;
                                data['full_name'] = nameController.text;
                                data['email'] = emailController.text;
                                data['mobile'] = phoneController.text;

                                context
                                    .read<ApplyJobApplicationCubit>()
                                    .applyJobApplication(data, pickedFile);
                              }
                            },
                              buttonTitle: "enquireNow".translate(context),
                              radius: 8,
                              fontSize: 12,
                              width: context.screenWidth,
                              textColor: context.color.buttonColor,
                              buttonColor: context.color.territoryColor,
                              height: 40)
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
        flagEmoji = value.flagEmoji;
        countryCode = value.phoneCode;
        setState(() {});
      },
    );
  }

  Widget attachmentWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
        ),
        CustomText(
          "attachResumeIfAny".translate(context),
          color: context.color.textDefaultColor,
        ),
        SizedBox(
          height: 10,
        ),
        DottedBorder(
          color: context.color.textLightColor,
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          child: GestureDetector(
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                allowMultiple: false,
                type: FileType.custom,
                allowedExtensions: ['pdf', 'doc', 'docx'],
              );

              if (result != null && result.files.isNotEmpty) {
                pickedFile = File(result.files.single.path!);
                // You can use pickedFile to upload
                debugPrint('Picked file: ${pickedFile!.path}');
                setState(() {});
              } else {
                debugPrint("File picking cancelled");
              }
            },
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: AlignmentDirectional.center,
              height: 48,
              child: CustomText(
                "uploadFile"
                    .translate(context), // Update key in your translation
                color: context.color.textDefaultColor,
                fontSize: context.font.large,
              ),
            ),
          ),
        ),
        if (pickedFile != null)
          TextButton(
              style: ButtonStyle(
                  overlayColor: WidgetStateProperty.all(
                      context.color.territoryColor.withValues(alpha: 0.2))),
              onPressed: () => OpenFilex.open(pickedFile!.path),
              child: Text(pickedFile!.path.split('/').last.toCapitalized()))
      ],
    );
  }

  Widget buildTextField(BuildContext context,
      {required String title,
      required TextEditingController controller,
      CustomTextFieldValidator? validator,
      bool? readOnly,
      required String hintText}) {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
        ),
        CustomText(
          title.translate(context),
          color: context.color.textDefaultColor,
        ),
        CustomTextFormField(
          controller: controller,
          isReadOnly: readOnly,
          validator: validator,
          hintText: hintText,
          fillColor: context.color.secondaryColor,
        ),
      ],
    );
  }

  String formatPhoneNumber(String fullNumber, String countryCode) {
    // Normalize the country code (remove '+' if present)
    countryCode = countryCode.replaceAll('+', '');

    // Remove '+' from fullNumber if present
    fullNumber = fullNumber.replaceAll('+', '');

    // Check if the fullNumber already starts with the country code
    if (!fullNumber.startsWith(countryCode)) {
      // If not, prepend the country code
      fullNumber = countryCode + fullNumber;
    }

    // Add '+' to the beginning of the full number
    fullNumber = '+' + fullNumber;

    return fullNumber;
  }

  Widget buildMobileField() {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 10,
        ),
        CustomText(
          "mobileNumberLbl".translate(context),
          color: context.color.textDefaultColor,
        ),
        CustomTextFormField(
            controller: phoneController,
            fillColor: context.color.secondaryColor,
            keyboard: TextInputType.phone,
            validator: CustomTextFieldValidator.phoneNumber,
            fixedPrefix: SizedBox(
              width: 55,
              child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GestureDetector(
                    onTap: () {
                      showCountryCode();
                    },
                    child: Container(
                      // color: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8),
                      child: Center(
                          child: CustomText(
                        "+$countryCode",
                        fontSize: context.font.large,
                        textAlign: TextAlign.center,
                      )),
                    ),
                  )),
            ),
            hintText: "mobileNumberLbl".translate(context)),
      ],
    );
  }
}
