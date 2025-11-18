import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
/// The [AppTheme] defines light and dark themes for the app.
///
/// Theme setup for FlexColorScheme package v8.
/// Use same major flex_color_scheme package version. If you use a
/// lower minor version, some properties may not be supported.
/// In that case, remove them after copying this theme to your
/// app or upgrade the package to version 8.3.1.
///
/// Use it in a [MaterialApp] like this:
///
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
/// );
abstract final class AppTheme {
  // The FlexColorScheme defined light mode ThemeData.
  static ThemeData light = FlexThemeData.light(
    // User defined custom colors made with FlexSchemeColor() API.
    colors: const FlexSchemeColor(
      primary: Color(0xFF7A72D1),
      primaryContainer: Color(0xFFAFAAE3),
      secondary: Color(0xFFFA7268),
      secondaryContainer: Color(0xFFFCAAA4),
      tertiary: Color(0xFF66D2F3),
      tertiaryContainer: Color(0xFFA3E4F8),
      appBarColor: Color(0xFFFCAAA4),
      error: Color(0xFFAE3436),
      errorContainer: Color(0xFFCF8587),
    ),
    // Component theme configurations for light mode.
    subThemesData: const FlexSubThemesData(
      inputDecoratorIsFilled: true,
      inputDecoratorBackgroundAlpha: 0,
      alignedDropdown: true,
      tooltipRadius: 4,
      tooltipSchemeColor: SchemeColor.inverseSurface,
      tooltipOpacity: 0.9,
      snackBarElevation: 6,
      snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
      navigationRailUseIndicator: true,
    ),
    // ColorScheme seed generation configuration for light mode.
    keyColors: const FlexKeyColors(
      useSecondary: true,
      keepPrimary: true,
      keepSecondary: true,
      keepTertiary: true,
      keepError: true,
      keepPrimaryContainer: true,
      keepSecondaryContainer: true,
      keepTertiaryContainer: true,
      keepErrorContainer: true,
    ),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );

  // The FlexColorScheme defined dark mode ThemeData.
  static ThemeData dark = FlexThemeData.dark(
    // User defined custom colors made with FlexSchemeColor() API.
    colors: const FlexSchemeColor(
      primary: Color(0xFF7A72D1),
      primaryContainer: Color(0xFFAFAAE3),
      primaryLightRef: Color(0xFF7A72D1), // The color of light mode primary
      secondary: Color(0xFFFA7268),
      secondaryContainer: Color(0xFFFCAAA4),
      secondaryLightRef: Color(0xFFFA7268), // The color of light mode secondary
      tertiary: Color(0xFF66D2F3),
      tertiaryContainer: Color(0xFFA3E4F8),
      tertiaryLightRef: Color(0xFF66D2F3), // The color of light mode tertiary
      appBarColor: Color(0xFFFCAAA4),
      error: Color(0xFFAE3436),
      errorContainer: Color(0xFFCF8587),
    ),
    // Component theme configurations for dark mode.
    subThemesData: const FlexSubThemesData(
      blendOnColors: true,
      inputDecoratorIsFilled: true,
      alignedDropdown: true,
      tooltipRadius: 4,
      tooltipSchemeColor: SchemeColor.inverseSurface,
      tooltipOpacity: 0.9,
      snackBarElevation: 6,
      snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
      navigationRailUseIndicator: true,
    ),
    // ColorScheme seed configuration setup for dark mode.
    keyColors: const FlexKeyColors(
      useSecondary: true,
      keepPrimary: true,
      keepSecondary: true,
      keepTertiary: true,
      keepError: true,
      keepPrimaryContainer: true,
      keepSecondaryContainer: true,
      keepTertiaryContainer: true,
      keepErrorContainer: true,
    ),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
