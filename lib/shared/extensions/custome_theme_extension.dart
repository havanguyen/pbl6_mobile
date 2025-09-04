import 'package:flutter/material.dart';

import '../themes/app_color.dart';

ThemeData darkTheme = ThemeData(
  extensions: const <ThemeExtension<dynamic>>[CustomThemeExtension.darkMode],
);

ThemeData lightTheme = ThemeData(
  extensions: const <ThemeExtension<dynamic>>[CustomThemeExtension.lightMode],
);

extension ExtendedTheme on BuildContext {
  CustomThemeExtension get theme =>
      Theme.of(this).extension<CustomThemeExtension>()!;
}

class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final Color bg;
  final Color appBar;
  final Color textColor;
  final Color yellow;
  final Color blue;
  final Color red;
  final Color green;
  final Color grey;
  final Color white;

  static const lightMode = CustomThemeExtension(
    bg: AppColors.bgLight,
    appBar: AppColors.appBarLight,
    textColor: AppColors.textColorLight,
    yellow: AppColors.yellowLight,
    blue: AppColors.blueLight,
    red: AppColors.redLight,
    green: AppColors.greenLight,
    grey: AppColors.greyLight,
    white: AppColors.whiteColorLight,
  );

  static const darkMode = CustomThemeExtension(
    bg: AppColors.bgDark,
    appBar: AppColors.appBarDark,
    textColor: AppColors.textColorDark,
    yellow: AppColors.yellowDark,
    blue: AppColors.blueDark,
    red: AppColors.redDark,
    green: AppColors.greenDark,
    grey: AppColors.greyDark,
    white: AppColors.whiteColorDark,
  );

  const CustomThemeExtension({
    required this.bg,
    required this.appBar,
    required this.textColor,
    required this.yellow,
    required this.blue,
    required this.red,
    required this.green,
    required this.grey,
    required this.white,
  });

  @override
  ThemeExtension<CustomThemeExtension> copyWith({
    Color? circleImageColor,
    Color? primary1,
    Color? primary2,
    Color? primary3,
    Color? primary4,
    Color? primary5,
    Color? primary6,
  }) {
    return CustomThemeExtension(
      bg: bg,
      appBar: appBar,
      textColor: textColor,
      yellow: yellow,
      blue: blue,
      red: red,
      green: green,
      grey: grey,
      white: white,
    );
  }

  @override
  ThemeExtension<CustomThemeExtension> lerp(
      covariant ThemeExtension<CustomThemeExtension>? other,
      double t,
      ) {
    if (other is! CustomThemeExtension) {
      return this;
    }
    return CustomThemeExtension(
      bg: bg,
      appBar: appBar,
      textColor: textColor,
      yellow: yellow,
      blue: blue,
      red: red,
      green: green,
      grey: grey,
      white: white,
    );
  }
}