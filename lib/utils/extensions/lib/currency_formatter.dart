import 'package:SombaTeka/utils/constant.dart';
import 'package:intl/intl.dart';

extension CurrencyFormatter on double {
  String get currencyFormat {
    final numberFormat = NumberFormat.decimalPattern(Constant.currentLocale);
    final formatted = numberFormat.format(this);

    return Constant.currencyPositionIsLeft
        ? '${Constant.currencySymbol} $formatted'
        : '$formatted ${Constant.currencySymbol}';
  }

}

