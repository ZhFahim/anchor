import 'package:flutter/material.dart';

import 'tokens/anchor_tokens.dart';

abstract final class AppTypography {
  static const String sans = 'DM Sans';
  static const String serif = 'Playfair Display';
  static const String mono = 'JetBrains Mono';

  static const String noteSerif = 'Literata';

  /// DM Sans has no Greek or Cyrillic letters, and Playfair has no Greek.
  static const List<String> sansFallback = ['Manrope'];
  static const List<String> serifFallback = [noteSerif];

  /// Cap height per em, from each bundled font's OS/2 table.
  static double capHeightOf(String? family) => switch (family) {
    serif => 0.708,
    mono => 0.73,
    _ => 0.7,
  };

  /// Playfair's default figures are old-style; `4` and `7` hang below the
  /// baseline.
  static const List<FontFeature> _liningFigures = [FontFeature.liningFigures()];

  static TextStyle _sans(TextStyle style) => style
      .copyWith(fontFamily: sans, fontFamilyFallback: sansFallback)
      .withSize(style.fontSize!);

  static final TextStyle largeTitle = AnchorTokens.typeLargeTitle.copyWith(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontFeatures: _liningFigures,
  );

  static final TextStyle sheetTitle = _sans(AnchorTokens.typeSheetTitle);

  static final TextStyle navTitle = _sans(AnchorTokens.typeNavTitle);

  static final TextStyle row = _sans(AnchorTokens.typeRow);

  static final TextStyle secondary = _sans(AnchorTokens.typeUi);

  static final TextStyle footnote = _sans(AnchorTokens.typeFootnote);

  /// Set in capitals by the caller.
  static final TextStyle label = _sans(AnchorTokens.typeLabel);

  static final TextStyle chip = _sans(AnchorTokens.typeChip);
  static final TextStyle cardTitle = _sans(AnchorTokens.typeCardTitle);
  static final TextStyle cardBody = _sans(AnchorTokens.typeCardBody);

  static final TextStyle noteTitle = _sans(AnchorTokens.typeNoteTitlePhone);

  /// Editor styles never inherit from the TextTheme.
  static final TextStyle noteBody = _sans(AnchorTokens.typeBody);

  static double get noteBodySize => AnchorTokens.typeBody.fontSize!;

  static TextStyle noteHeading(int level, {double? bodySize}) {
    final (scale, height, weight, tracking) = switch (level) {
      1 => (
        AnchorTokens.headingH1Scale,
        AnchorTokens.headingH1LineHeight,
        AnchorTokens.headingH1Weight,
        AnchorTokens.headingH1Tracking,
      ),
      2 => (
        AnchorTokens.headingH2Scale,
        AnchorTokens.headingH2LineHeight,
        AnchorTokens.headingH2Weight,
        AnchorTokens.headingH2Tracking,
      ),
      _ => (
        AnchorTokens.headingH3Scale,
        AnchorTokens.headingH3LineHeight,
        AnchorTokens.headingH3Weight,
        AnchorTokens.headingH3Tracking,
      ),
    };
    final size = (bodySize ?? noteBodySize) * scale;
    return TextStyle(
      fontFamily: sans,
      fontFamilyFallback: sansFallback,
      height: height,
      fontWeight: weight,
      letterSpacing: tracking * size,
    ).withSize(size);
  }

  static final TextStyle code = AnchorTokens.typeCode.copyWith(
    fontFamily: mono,
  );

  static final TextStyle codeSmall = code.copyWith(fontSize: footnote.fontSize);

  static TextStyle serifText({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallback,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    fontFeatures: _liningFigures,
  );

  static TextTheme textTheme(Color text, Color muted) {
    TextStyle withColor(TextStyle style, [Color? color]) =>
        style.copyWith(color: color ?? text);
    return TextTheme(
      displayLarge: withColor(largeTitle),
      displayMedium: withColor(largeTitle),
      displaySmall: withColor(largeTitle),
      headlineLarge: withColor(sheetTitle),
      headlineMedium: withColor(sheetTitle),
      headlineSmall: withColor(sheetTitle),
      titleLarge: withColor(sheetTitle),
      titleMedium: withColor(navTitle),
      titleSmall: withColor(row.copyWith(fontWeight: FontWeight.w600)),
      bodyLarge: withColor(row),
      bodyMedium: withColor(secondary),
      bodySmall: withColor(footnote, muted),
      labelLarge: withColor(secondary.copyWith(fontWeight: FontWeight.w600)),
      labelMedium: withColor(footnote),
      labelSmall: withColor(footnote, muted),
    );
  }
}

extension TextSize on TextStyle {
  /// [size], drawn at the font's matching optical size.
  TextStyle withSize(double size) => copyWith(
    fontSize: size,
    fontVariations: [FontVariation.opticalSize(size)],
  );
}

extension TabularFigures on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
