import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../motion/page_transitions.dart';
import 'anchor_density.dart';
import 'app_typography.dart';
import 'display_density.dart';
import 'note_typography.dart';
import 'tokens/anchor_tokens.dart';

abstract final class AppTheme {
  static final Map<
    (Brightness, DisplayDensity, NoteFont, NoteTextSize),
    ThemeData
  >
  _cache = {};

  static ThemeData light([
    DisplayDensity density = DisplayDensity.standard,
    NoteFont font = NoteFont.sans,
    NoteTextSize textSize = NoteTextSize.standard,
  ]) => _cache.putIfAbsent((
    Brightness.light,
    density,
    font,
    textSize,
  ), () => _build(Brightness.light, density, font, textSize));

  static ThemeData dark([
    DisplayDensity density = DisplayDensity.standard,
    NoteFont font = NoteFont.sans,
    NoteTextSize textSize = NoteTextSize.standard,
  ]) => _cache.putIfAbsent((
    Brightness.dark,
    density,
    font,
    textSize,
  ), () => _build(Brightness.dark, density, font, textSize));

  static ThemeData _build(
    Brightness brightness,
    DisplayDensity density,
    NoteFont font,
    NoteTextSize textSize,
  ) {
    final spacing = AnchorDensity.of(density);
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AnchorColors.dark : AnchorColors.light;
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.appText,
      onPrimary: colors.appSurface,
      primaryContainer: colors.appSubtle,
      onPrimaryContainer: colors.appText,
      secondary: colors.appMuted,
      onSecondary: colors.appSurface,
      secondaryContainer: colors.appSubtle,
      onSecondaryContainer: colors.appText,
      tertiary: colors.accentStrong,
      onTertiary: AnchorTokens.colorBrandWhite,
      tertiaryContainer: mix(
        colors.appSurface,
        AnchorTokens.colorAccentFill,
        0.16,
      ),
      onTertiaryContainer: colors.accentInk,
      error: colors.statusDanger,
      onError: colors.statusOnDanger,
      errorContainer: mix(colors.appSurface, colors.statusDanger, 0.12),
      onErrorContainer: colors.statusDanger,
      surface: colors.appPage,
      onSurface: colors.appText,
      onSurfaceVariant: colors.appMuted,
      surfaceDim: mix(colors.appPage, colors.appBorder, 0.5),
      surfaceBright: colors.appSurface,
      surfaceContainerLowest: colors.appSurface,
      surfaceContainerLow: mix(colors.appSurface, colors.appSubtle, 0.5),
      surfaceContainer: colors.appSubtle,
      surfaceContainerHigh: mix(colors.appSubtle, colors.appBorder, 0.5),
      surfaceContainerHighest: colors.appBorder,
      outline: colors.appFieldLine,
      outlineVariant: colors.appBorder,
      shadow: const Color(0xFF000000),
      scrim: colors.appOverlay,
      inverseSurface: colors.appInverse,
      onInverseSurface: colors.appOnInverse,
      inversePrimary: colors.appInverseLink,
      surfaceTint: const Color(0x00000000),
    );

    final textTheme = AppTypography.textTheme(colors.appText, colors.appMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.sans,
      fontFamilyFallback: AppTypography.sansFallback,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.appPage,
      canvasColor: colors.appPage,
      splashFactory: NoSplash.splashFactory,
      splashColor: const Color(0x00000000),
      highlightColor: const Color(0x00000000),
      hoverColor: const Color(0x00000000),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: AnchorPageTransitionsBuilder(),
          TargetPlatform.android: AnchorPageTransitionsBuilder(),
          TargetPlatform.macOS: AnchorPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: colors.accentStrong,
        scaffoldBackgroundColor: colors.appPage,
        barBackgroundColor: colors.appPage,
      ),
      iconTheme: IconThemeData(
        color: colors.appText,
        size: AnchorTokens.sizeIconLarge,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accentStrong,
        selectionColor: AnchorTokens.colorAccentFill.withValues(alpha: 0.3),
        selectionHandleColor: colors.accentStrong,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AnchorTokens.colorControlKnob
              : colors.appMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? colors.accentStrong
              : mix(colors.appSurface, colors.appMuted, 0.18),
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0x00000000)
              : colors.appMuted,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        isCollapsed: true,
        border: InputBorder.none,
        hintStyle: AppTypography.row.copyWith(color: colors.appMuted),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(AnchorTokens.radiusPill),
        thumbColor: WidgetStatePropertyAll(
          colors.appMuted.withValues(alpha: 0.45),
        ),
      ),
      extensions: [
        spacing,
        NoteTypography(
          font: font,
          textSize: textSize,
          lineHeight: spacing.noteLineHeight,
        ),
        colors,
      ],
    );
  }
}
