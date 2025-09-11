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
  // Original colors
  final Color bg;
  final Color appBar;
  final Color textColor;
  final Color yellow;
  final Color blue;
  final Color red;
  final Color green;
  final Color grey;
  final Color white;

  // New colors
  final Color primary;
  final Color foreground;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color accent;
  final Color accentForeground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color input;
  final Color ring;
  final Color destructive;
  final Color destructiveForeground;
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;
  final Color sidebarBackground;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarPrimaryForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;
  final Color sidebarBorder;
  final Color sidebarRing;

  static const lightMode = CustomThemeExtension(
    // Original light colors
    bg: AppColors.bgLight,
    appBar: AppColors.appBarLight,
    textColor: AppColors.textColorLight,
    yellow: AppColors.yellowLight,
    blue: AppColors.blueLight,
    red: AppColors.redLight,
    green: AppColors.greenLight,
    grey: AppColors.greyLight,
    white: AppColors.whiteColorLight,

    // New light colors
    primary: AppColors.primaryLight,
    foreground: AppColors.foregroundLight,
    primaryForeground: AppColors.primaryForegroundLight,
    secondary: AppColors.secondaryLight,
    secondaryForeground: AppColors.secondaryForegroundLight,
    accent: AppColors.accentLight,
    accentForeground: AppColors.accentForegroundLight,
    card: AppColors.cardLight,
    cardForeground: AppColors.cardForegroundLight,
    popover: AppColors.popoverLight,
    popoverForeground: AppColors.popoverForegroundLight,
    muted: AppColors.mutedLight,
    mutedForeground: AppColors.mutedForegroundLight,
    border: AppColors.borderLight,
    input: AppColors.inputLight,
    ring: AppColors.ringLight,
    destructive: AppColors.destructiveLight,
    destructiveForeground: AppColors.destructiveForegroundLight,
    chart1: AppColors.chart1Light,
    chart2: AppColors.chart2Light,
    chart3: AppColors.chart3Light,
    chart4: AppColors.chart4Light,
    chart5: AppColors.chart5Light,
    sidebarBackground: AppColors.sidebarBackgroundLight,
    sidebarForeground: AppColors.sidebarForegroundLight,
    sidebarPrimary: AppColors.sidebarPrimaryLight,
    sidebarPrimaryForeground: AppColors.sidebarPrimaryForegroundLight,
    sidebarAccent: AppColors.sidebarAccentLight,
    sidebarAccentForeground: AppColors.sidebarAccentForegroundLight,
    sidebarBorder: AppColors.sidebarBorderLight,
    sidebarRing: AppColors.sidebarRingLight,
  );

  static const darkMode = CustomThemeExtension(
    // Original dark colors
    bg: AppColors.bgDark,
    appBar: AppColors.appBarDark,
    textColor: AppColors.textColorDark,
    yellow: AppColors.yellowDark,
    blue: AppColors.blueDark,
    red: AppColors.redDark,
    green: AppColors.greenDark,
    grey: AppColors.greyDark,
    white: AppColors.whiteColorDark,

    // New dark colors
    primary: AppColors.primaryDark,
    foreground: AppColors.foregroundDark,
    primaryForeground: AppColors.primaryForegroundDark,
    secondary: AppColors.secondaryDark,
    secondaryForeground: AppColors.secondaryForegroundDark,
    accent: AppColors.accentDark,
    accentForeground: AppColors.accentForegroundDark,
    card: AppColors.cardDark,
    cardForeground: AppColors.cardForegroundDark,
    popover: AppColors.popoverDark,
    popoverForeground: AppColors.popoverForegroundDark,
    muted: AppColors.mutedDark,
    mutedForeground: AppColors.mutedForegroundDark,
    border: AppColors.borderDark,
    input: AppColors.inputDark,
    ring: AppColors.ringDark,
    destructive: AppColors.destructiveDark,
    destructiveForeground: AppColors.destructiveForegroundDark,
    chart1: AppColors.chart1Dark,
    chart2: AppColors.chart2Dark,
    chart3: AppColors.chart3Dark,
    chart4: AppColors.chart4Dark,
    chart5: AppColors.chart5Dark,
    sidebarBackground: AppColors.sidebarBackgroundDark,
    sidebarForeground: AppColors.sidebarForegroundDark,
    sidebarPrimary: AppColors.sidebarPrimaryDark,
    sidebarPrimaryForeground: AppColors.sidebarPrimaryForegroundDark,
    sidebarAccent: AppColors.sidebarAccentDark,
    sidebarAccentForeground: AppColors.sidebarAccentForegroundDark,
    sidebarBorder: AppColors.sidebarBorderDark,
    sidebarRing: AppColors.sidebarRingDark,
  );

  const CustomThemeExtension({
    // Original parameters
    required this.bg,
    required this.appBar,
    required this.textColor,
    required this.yellow,
    required this.blue,
    required this.red,
    required this.green,
    required this.grey,
    required this.white,

    // New parameters
    required this.primary,
    required this.foreground,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.accent,
    required this.accentForeground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.destructive,
    required this.destructiveForeground,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
    required this.sidebarBackground,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarPrimaryForeground,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
    required this.sidebarBorder,
    required this.sidebarRing,
  });

  @override
  ThemeExtension<CustomThemeExtension> copyWith({
    Color? bg,
    Color? appBar,
    Color? textColor,
    Color? yellow,
    Color? blue,
    Color? red,
    Color? green,
    Color? grey,
    Color? white,
    Color? primary,
    Color? foreground,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? accent,
    Color? accentForeground,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? popoverForeground,
    Color? muted,
    Color? mutedForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? destructive,
    Color? destructiveForeground,
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
    Color? sidebarBackground,
    Color? sidebarForeground,
    Color? sidebarPrimary,
    Color? sidebarPrimaryForeground,
    Color? sidebarAccent,
    Color? sidebarAccentForeground,
    Color? sidebarBorder,
    Color? sidebarRing,
  }) {
    return CustomThemeExtension(
      bg: bg ?? this.bg,
      appBar: appBar ?? this.appBar,
      textColor: textColor ?? this.textColor,
      yellow: yellow ?? this.yellow,
      blue: blue ?? this.blue,
      red: red ?? this.red,
      green: green ?? this.green,
      grey: grey ?? this.grey,
      white: white ?? this.white,
      primary: primary ?? this.primary,
      foreground: foreground ?? this.foreground,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      popover: popover ?? this.popover,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      destructive: destructive ?? this.destructive,
      destructiveForeground: destructiveForeground ?? this.destructiveForeground,
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      sidebarPrimary: sidebarPrimary ?? this.sidebarPrimary,
      sidebarPrimaryForeground: sidebarPrimaryForeground ?? this.sidebarPrimaryForeground,
      sidebarAccent: sidebarAccent ?? this.sidebarAccent,
      sidebarAccentForeground: sidebarAccentForeground ?? this.sidebarAccentForeground,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      sidebarRing: sidebarRing ?? this.sidebarRing,
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
      bg: Color.lerp(bg, other.bg, t)!,
      appBar: Color.lerp(appBar, other.appBar, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      red: Color.lerp(red, other.red, t)!,
      green: Color.lerp(green, other.green, t)!,
      grey: Color.lerp(grey, other.grey, t)!,
      white: Color.lerp(white, other.white, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryForeground: Color.lerp(secondaryForeground, other.secondaryForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(accentForeground, other.accentForeground, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      popoverForeground: Color.lerp(popoverForeground, other.popoverForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground: Color.lerp(destructiveForeground, other.destructiveForeground, t)!,
      chart1: Color.lerp(chart1, other.chart1, t)!,
      chart2: Color.lerp(chart2, other.chart2, t)!,
      chart3: Color.lerp(chart3, other.chart3, t)!,
      chart4: Color.lerp(chart4, other.chart4, t)!,
      chart5: Color.lerp(chart5, other.chart5, t)!,
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      sidebarForeground: Color.lerp(sidebarForeground, other.sidebarForeground, t)!,
      sidebarPrimary: Color.lerp(sidebarPrimary, other.sidebarPrimary, t)!,
      sidebarPrimaryForeground: Color.lerp(sidebarPrimaryForeground, other.sidebarPrimaryForeground, t)!,
      sidebarAccent: Color.lerp(sidebarAccent, other.sidebarAccent, t)!,
      sidebarAccentForeground: Color.lerp(sidebarAccentForeground, other.sidebarAccentForeground, t)!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      sidebarRing: Color.lerp(sidebarRing, other.sidebarRing, t)!,
    );
  }
}