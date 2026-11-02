import 'dart:io';

import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/theme/app_typography.dart';
import 'package:anchor/core/theme/note_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sans styles fall back to Manrope for Greek and Cyrillic', () {
    final textTheme = AppTheme.light().textTheme;
    const note = NoteTypography(lineHeight: 1.5);
    final styles = <String, TextStyle?>{
      'bodyLarge': textTheme.bodyLarge,
      'bodyMedium': textTheme.bodyMedium,
      'bodySmall': textTheme.bodySmall,
      'titleLarge': textTheme.titleLarge,
      'titleMedium': textTheme.titleMedium,
      'labelLarge': textTheme.labelLarge,
      'noteHeading': AppTypography.noteHeading(1),
      'note title': note.title,
      'note body': note.body,
      'note heading': note.heading(2),
      'card title': note.cardTitle,
      'card body': note.cardBody,
    };

    for (final MapEntry(:key, :value) in styles.entries) {
      expect(value?.fontFamily, AppTypography.sans, reason: key);
      expect(
        value?.fontFamilyFallback,
        AppTypography.sansFallback,
        reason: key,
      );
    }
  });

  test('serif titles fall back to Literata for Greek', () {
    final textTheme = AppTheme.light().textTheme;
    for (final style in [
      AppTypography.largeTitle,
      AppTypography.serifText(fontSize: 20),
      textTheme.displayLarge,
    ]) {
      expect(style?.fontFamilyFallback, AppTypography.serifFallback);
    }
  });

  test('every fallback family is bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final family in {
      ...AppTypography.sansFallback,
      ...AppTypography.serifFallback,
    }) {
      expect(pubspec, contains('- family: $family\n'), reason: family);
    }
  });
}
