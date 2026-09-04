import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_typography.dart';
import 'tokens/app_color_tokens.dart';
import 'tokens/app_dimensions.dart';
import 'tokens/app_opacity.dart';
import 'tokens/app_palette.dart';
import 'tokens/app_radius.dart';

/// Builds the app's [ThemeData], including the component themes.
class AppTheme {
  AppTheme._();

  static final Map<(Brightness, DisplayDensity), ThemeData> _cache = {};

  static ThemeData light([DisplayDensity density = DisplayDensity.standard]) =>
      _cache.putIfAbsent((
        Brightness.light,
        density,
      ), () => _build(Brightness.light, density));

  static ThemeData dark([DisplayDensity density = DisplayDensity.standard]) =>
      _cache.putIfAbsent((
        Brightness.dark,
        density,
      ), () => _build(Brightness.dark, density));

  static ThemeData _build(Brightness brightness, DisplayDensity density) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final primary = isDark ? AppPalette.offWhite : AppPalette.slate;
    final background = isDark ? AppPalette.bgDark : AppPalette.bgLight;
    final container = isDark ? AppPalette.surfaceDark : AppPalette.surfaceLight;
    final dims = AppDimensions.of(density);
    final tokens = AppColorTokens.of(brightness);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.slateBlue,
      primary: primary,
      secondary: AppPalette.slateBlue,
      tertiary: AppPalette.burntOrange,
      surface: background,
      onSurface: primary,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: AppTypography.buildTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: Platform.isIOS,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: primary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: brightness, // iOS
          statusBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark, // Android
          statusBarColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: container,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorder,
          side: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? AppPalette.burntOrange : AppPalette.slate,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fabBorder),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: dims.buttonPadding,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorder,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: dims.buttonPadding,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorder,
          ),
          side: BorderSide(color: primary.withValues(alpha: AppOpacity.border)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorder,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: tokens.subtleBorder,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: container,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetBorder,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: container,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetBorder,
        ),
        headerBackgroundColor: container,
        headerForegroundColor: primary,
        dayShape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: container,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetBorder,
        ),
        hourMinuteShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
        ),
        dialBackgroundColor: AppPalette.slateBlue.withValues(
          alpha: AppOpacity.subtleFill,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTopBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: container,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlBorder,
          side: BorderSide(
            color: primary.withValues(alpha: AppOpacity.hairline),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.inputFill,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.all(dims.lg),
        hintStyle: TextStyle(
          color: AppPalette.slateBlue.withValues(alpha: 0.5),
        ),
      ),
      extensions: [dims, tokens],
    );
  }
}
