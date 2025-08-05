import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/app_icon.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class NoDataFound extends StatelessWidget {
  final double? height;
  final String? mainMessage;
  final String? subMessage;
  final VoidCallback? onTap;
  final double? mainMsgStyle;
  final double? subMsgStyle;
  final bool? showImage;

  const NoDataFound(
      {super.key,
      this.onTap,
      this.height,
      this.mainMessage,
      this.subMessage,
      this.mainMsgStyle,
      this.subMsgStyle, this.showImage});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? null,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if(showImage!=false)
              UiUtils.getSvg(AppIcons.no_data_found, height: height ?? null),
              const SizedBox(
                height: 20,
              ),
              CustomText(
                mainMessage ?? "nodatafound".translate(context),
                fontSize: mainMsgStyle ?? context.font.extraLarge,
                color: context.color.territoryColor,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(
                height: 14,
              ),
              CustomText(
                subMessage ?? "sorryLookingFor".translate(context),
                fontSize: subMsgStyle ?? context.font.larger,
                textAlign: TextAlign.center,
              ),
              // CustomText(UiUtils.getTranslatedLabel(context, "nodatafound")),
              // TextButton(
              //     onPressed: onTap,
              //     style: ButtonStyle(
              //         overlayColor: MaterialStateItem.all(
              //             context.color.teritoryColor.withValues(alpha: 0.2))),
              //     child: const CustomText("Retry").color(context.color.teritoryColor))
            ],
          ),
        ),
      ),
    );
  }
}
