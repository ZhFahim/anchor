import 'dart:io';

import 'package:anchor/core/network/connectivity_provider.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/storage/preferences_repository.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/theme/app_typography.dart';
import 'package:anchor/core/theme/display_density.dart';
import 'package:anchor/core/theme/note_typography.dart';
import 'package:anchor/core/widgets/grouped_list.dart';
import 'package:anchor/core/widgets/segmented_control.dart';
import 'package:anchor/features/auth/domain/oidc_config.dart';
import 'package:anchor/features/auth/domain/user.dart';
import 'package:anchor/features/auth/presentation/auth_controller.dart';
import 'package:anchor/features/auth/presentation/oidc_config_provider.dart';
import 'package:anchor/features/server/data/server_info_provider.dart';
import 'package:anchor/features/settings/presentation/editor_preferences_controller.dart';
import 'package:anchor/features/settings/presentation/settings_screen.dart';
import 'package:anchor/features/sync/data/sync_compatibility.dart';
import 'package:anchor/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _SignedOut extends AuthController {
  @override
  Future<User?> build() async => null;
}

class _App extends ConsumerWidget {
  const _App({required this.isMotionReduced});

  final bool isMotionReduced;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorPreferencesControllerProvider);
    return MaterialApp(
      theme: AppTheme.light(
        DisplayDensity.standard,
        editor.noteFont,
        editor.noteTextSize,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: isMotionReduced),
        child: child!,
      ),
      home: const SettingsScreen(),
    );
  }
}

final _english = lookupAppLocalizations(const Locale('en'));

void main() {
  setUpAll(() async {
    Future<ByteData> bytes(String file) async =>
        ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync());
    await (FontLoader(
      AppTypography.sans,
    )..addFont(bytes('DMSans-Variable.ttf'))).load();
    for (final (family, prefix) in [
      (AppTypography.noteSerif, 'Literata'),
      (AppTypography.mono, 'JetBrainsMono'),
    ]) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        loader.addFont(bytes('$prefix-$weight.ttf'));
      }
      await loader.load();
    }
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Anchor',
      packageName: 'anchor',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<ProviderContainer> pumpSettings(
    WidgetTester tester, {
    bool isMotionReduced = false,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        isOnlineProvider.overrideWithValue(true),
        serverUrlProvider.overrideWithValue('https://example.test'),
        authControllerProvider.overrideWith(_SignedOut.new),
        oidcConfigProvider.overrideWith((ref) async => const OidcConfig()),
        serverInfoProvider.overrideWith((ref) async => null),
        syncCompatibilityProvider.overrideWith(
          (ref) async => SyncCompatibility.ok,
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _App(isMotionReduced: isMotionReduced),
      ),
    );
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('Weekend in Lisbon')),
      alignment: 0.2,
    );
    await tester.pumpAndSettle();
    return container;
  }

  Finder segment(String picker, String label) => find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is SegmentedControl && w.semanticLabel == picker,
    ),
    matching: find.text(label),
  );

  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!;

  const preview =
      'Pack light. The hills are steep, and the trams fill up by '
      'nine.';

  testWidgets('Editor shows a preview, Font, Text size, then the switch', (
    tester,
  ) async {
    await pumpSettings(tester);

    final tops = [
      for (final text in [
        'Weekend in Lisbon',
        preview,
        'Font',
        'Text size',
        'Move checked items to the bottom',
      ])
        tester.getTopLeft(find.text(text)).dy,
    ];
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]));
    }
    expect(styleOf(tester, 'Weekend in Lisbon').fontFamily, AppTypography.sans);
    expect(styleOf(tester, 'Weekend in Lisbon').fontSize, 20);
    expect(styleOf(tester, preview).fontSize, 16.5);
  });

  testWidgets('each font is named in its own face', (tester) async {
    await pumpSettings(tester);

    for (final font in NoteFont.values) {
      final label = tester.widget<Text>(
        segment('Font', font.labelIn(_english)),
      );
      final style = DefaultTextStyle.of(
        tester.element(segment('Font', font.labelIn(_english))),
      ).style.merge(label.style);
      expect(style.fontFamily, font.family);
    }
  });

  testWidgets('the rows sit as in the guide: 12 around the label and the '
      'picker, no line under the preview', (tester) async {
    await pumpSettings(tester);

    final group = tester.getRect(
      find.ancestor(of: find.text('Font'), matching: find.byType(GroupedList)),
    );
    final font = tester.getRect(find.text('Font'));
    final fontPicker = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is SegmentedControl && w.semanticLabel == 'Font',
      ),
    );
    final textSize = tester.getRect(find.text('Text size'));
    expect(
      tester.getTopLeft(find.text('Weekend in Lisbon')).dy - group.top,
      16,
    );
    expect(font.left - group.left, 16);
    expect(font.top - group.top, closeTo(105.1 + 12, 0.5));
    expect(fontPicker.top - font.bottom, 12);
    expect(fontPicker.height, 44);
    expect(textSize.top - fontPicker.bottom, 12 + 12);
    Finder dividersIn(String row) => find.descendant(
      of: find.ancestor(of: find.text(row), matching: find.byType(GroupedList)),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxHeight == 1,
      ),
    );
    expect(dividersIn('Font'), findsNWidgets(2));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(dividersIn('Density'), findsNothing);
  });

  testWidgets('picking a font and a size saves them on this phone and '
      'changes the notes', (tester) async {
    final container = await pumpSettings(tester);

    await tester.tap(segment('Font', 'Serif'));
    await tester.pumpAndSettle();
    await tester.tap(segment('Text size', 'Large'));
    await tester.pumpAndSettle();

    final editor = container.read(editorPreferencesControllerProvider);
    expect(editor.noteFont, NoteFont.serif);
    expect(editor.noteTextSize, NoteTextSize.large);
    final repository = container.read(preferencesRepositoryProvider);
    expect(await repository.getNoteFont(), 'serif');
    expect(await repository.getNoteTextSize(), 'large');
    final typography = Theme.of(
      tester.element(find.text('Font')),
    ).extension<NoteTypography>()!;
    expect(typography.font, NoteFont.serif);
    expect(typography.textSize, NoteTextSize.large);
    expect(
      styleOf(tester, 'Weekend in Lisbon').fontFamily,
      AppTypography.noteSerif,
    );
    expect(styleOf(tester, preview).fontSize, closeTo(16.5 * 1.12, 0.001));
  });

  testWidgets('the preview grows over the fade and the face changes at once', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(segment('Text size', 'Large'));
    await tester.pump();
    expect(styleOf(tester, preview).fontSize, 16.5);
    await tester.pump(const Duration(milliseconds: 100));
    final halfway = styleOf(tester, preview).fontSize!;
    expect(halfway, greaterThan(16.5));
    expect(halfway, lessThan(16.5 * 1.12));
    await tester.pumpAndSettle();
    expect(styleOf(tester, preview).fontSize, closeTo(16.5 * 1.12, 0.001));

    await tester.tap(segment('Font', 'Mono'));
    await tester.pump();
    expect(styleOf(tester, preview).fontFamily, AppTypography.mono);
    expect(styleOf(tester, preview).fontSize, closeTo(16.5 * 1.12, 0.001));
    await tester.pumpAndSettle();
    expect(
      styleOf(tester, preview).fontSize,
      closeTo(16.5 * 1.12 * 0.9, 0.001),
    );
  });

  testWidgets('with reduced motion the preview changes size at once', (
    tester,
  ) async {
    await pumpSettings(tester, isMotionReduced: true);

    await tester.tap(segment('Text size', 'Small'));
    await tester.pump();
    await tester.pump();
    expect(styleOf(tester, preview).fontSize, closeTo(16.5 * 0.88, 0.001));
  });

  testWidgets('Account has Delete account, under Sign out', (tester) async {
    await pumpSettings(tester);

    final signOut = find.text('Sign out');
    final delete = find.text('Delete account');
    await tester.scrollUntilVisible(delete, 200);

    expect(
      tester.getTopLeft(signOut).dy,
      lessThan(tester.getTopLeft(delete).dy),
    );
  });

  testWidgets('the coffee link shows on Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await pumpSettings(tester);

    expect(find.text('Support Anchor', skipOffstage: false), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the coffee link doesn’t show on iPhone', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await pumpSettings(tester);

    expect(find.text('Support Anchor', skipOffstage: false), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
