import 'package:anchor/core/theme/anchor_density.dart';
import 'package:anchor/core/theme/context_extensions.dart';
import 'package:anchor/core/theme/display_density.dart';
import 'package:anchor/core/theme/tokens/anchor_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnchorColors', () {
    test('light and dark differ on the page colors', () {
      const light = AnchorColors.light;
      const dark = AnchorColors.dark;
      expect(light.appPage, isNot(dark.appPage));
      expect(light.appSurface, isNot(dark.appSurface));
      expect(light.appText, isNot(dark.appText));
      expect(light.appMuted, isNot(dark.appMuted));
      expect(light.appBorder, isNot(dark.appBorder));
    });

    test('every background has note colors in both themes', () {
      for (final background in [
        ...AnchorBackgrounds.colors,
        ...AnchorBackgrounds.patterns,
      ]) {
        expect(AnchorColors.light.notes, contains(background.palette));
        expect(AnchorColors.dark.notes, contains(background.palette));
      }
    });

    test('every highlight name has a color in both themes', () {
      for (final name in AnchorTokens.highlightNames) {
        expect(AnchorColors.light.highlights, contains(name));
        expect(AnchorColors.dark.highlights, contains(name));
      }
    });

    test('lerp returns the endpoints at t=0 and t=1', () {
      const light = AnchorColors.light;
      const dark = AnchorColors.dark;
      expect(light.lerp(dark, 0).appSurface, light.appSurface);
      expect(light.lerp(dark, 1).appSurface, dark.appSurface);
      expect(
        light.lerp(dark, 0).notes['yellow']!.bg,
        light.notes['yellow']!.bg,
      );
      expect(light.lerp(dark, 1).notes['yellow']!.bg, dark.notes['yellow']!.bg);
    });

    test('copyWith replaces only what it is given', () {
      final colors = AnchorColors.light.copyWith(statusDanger: Colors.pink);
      expect(colors.statusDanger, Colors.pink);
      expect(colors.appText, AnchorColors.light.appText);
      expect(colors.notes, AnchorColors.light.notes);
    });
  });

  group('AnchorBackgrounds', () {
    test('of() finds a stored background by its id', () {
      expect(AnchorBackgrounds.of('color_yellow').name, 'Yellow');
      expect(AnchorBackgrounds.of('pattern_grid').pattern, 'grid');
    });

    test('of() falls back to the default for an unknown or empty id', () {
      expect(AnchorBackgrounds.of(null), AnchorBackgrounds.colors.first);
      expect(AnchorBackgrounds.of('nope'), AnchorBackgrounds.colors.first);
      expect(AnchorBackgrounds.colors.first.palette, 'none');
    });
  });

  group('AnchorDensity', () {
    test('of() maps each density to its own values', () {
      expect(AnchorDensity.of(DisplayDensity.compact), AnchorDensity.compact);
      expect(AnchorDensity.of(DisplayDensity.standard), AnchorDensity.standard);
    });

    test('isCompact is true only for the Compact density', () {
      expect(AnchorDensity.compact.isCompact, isTrue);
      expect(AnchorDensity.standard.isCompact, isFalse);
    });

    test('Default keeps the scale and every 52', () {
      const standard = AnchorDensity.standard;
      expect(
        [
          standard.space8,
          standard.space12,
          standard.space16,
          standard.space24,
          standard.space32,
          standard.space48,
        ],
        [8, 12, 16, 24, 32, 48],
      );
      expect(standard.control, AnchorTokens.sizeControlLarge);
      expect(standard.bar, AnchorTokens.sizeControlLarge);
      expect(standard.noteLineHeight, 1.55);
      expect(
        [
          standard.previewMasonry,
          standard.previewGrid,
          standard.previewList,
          standard.previewPictures,
        ],
        [6, 4, 2, 4],
      );
    });

    test('Compact moves vertical space one step down and 52 to 44', () {
      const compact = AnchorDensity.compact;
      expect(
        [
          compact.space8,
          compact.space12,
          compact.space16,
          compact.space24,
          compact.space32,
          compact.space48,
        ],
        [4, 8, 12, 16, 24, 32],
      );
      expect(compact.control, AnchorTokens.sizeControlMedium);
      expect(compact.bar, AnchorTokens.sizeControlMedium);
      expect(compact.noteLineHeight, 1.40);
      expect(
        [
          compact.previewMasonry,
          compact.previewGrid,
          compact.previewList,
          compact.previewPictures,
        ],
        [4, 3, 1, 2],
      );
    });

    test('lerp snaps at halfway', () {
      const compact = AnchorDensity.compact;
      const standard = AnchorDensity.standard;
      expect(compact.lerp(standard, 0), same(compact));
      expect(compact.lerp(standard, 0.49), same(compact));
      expect(compact.lerp(standard, 0.5), same(standard));
      expect(compact.lerp(standard, 1), same(standard));
      expect(compact.lerp(null, 0.7), same(compact));
    });

    test('copyWith replaces only what it is given', () {
      final density = AnchorDensity.standard.copyWith(space16: 4);
      expect(density.space16, 4);
      expect(density.space12, AnchorDensity.standard.space12);
      expect(density.density, DisplayDensity.standard);
    });
  });

  group('context extensions', () {
    testWidgets('fall back to defaults under a bare MaterialApp', (
      tester,
    ) async {
      late AnchorDensity density;
      late AnchorColors colors;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              density = context.density;
              colors = context.anchor;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(density, AnchorDensity.standard);
      expect(colors, AnchorColors.light);
    });

    testWidgets('fall back to the dark colors under a dark bare theme', (
      tester,
    ) async {
      late AnchorColors colors;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              colors = context.anchor;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(colors, AnchorColors.dark);
    });

    testWidgets('read the registered extensions when they are present', (
      tester,
    ) async {
      late AnchorDensity density;
      late AnchorColors colors;

      await tester.pumpWidget(
        MaterialApp(
          // Dark colors on a light theme show the extension wins.
          theme: ThemeData(
            extensions: const [AnchorDensity.compact, AnchorColors.dark],
          ),
          home: Builder(
            builder: (context) {
              density = context.density;
              colors = context.anchor;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(density, AnchorDensity.compact);
      expect(colors, AnchorColors.dark);
    });
  });
}
