import 'package:anchor/app/app_bootstrap.dart';
import 'package:anchor/core/storage/preferences_repository.dart';
import 'package:anchor/core/widgets/segmented_control.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/features/settings/presentation/app_lock_controller.dart';
import 'package:anchor/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferences extends Mock implements PreferencesRepository {}

void main() {
  late _MockPreferences preferences;

  setUp(() {
    preferences = _MockPreferences();
    when(() => preferences.setMotionSpeedName(any())).thenAnswer((_) async {});
    when(() => preferences.setThemeMode(any())).thenAnswer((_) async {});
    when(() => preferences.setDisplayDensity(any())).thenAnswer((_) async {});
    when(() => preferences.setSortChecklistItems(any()))
        .thenAnswer((_) async {});
    when(() => preferences.setNoteFont(any())).thenAnswer((_) async {});
    when(() => preferences.setNoteTextSize(any())).thenAnswer((_) async {});
    when(() => preferences.setAppLockEnabled(any()))
        .thenAnswer((_) async {});
    when(() => preferences.setLockGraceMinutes(any()))
        .thenAnswer((_) async {});
    when(preferences.getBackupFolder).thenAnswer((_) async => null);
    when(preferences.getBackupAutomatic).thenAnswer((_) async => true);
    when(preferences.getBackupPeriodDays).thenAnswer((_) async => 7);
    when(preferences.getBackupKeepFiles).thenAnswer((_) async => 3);
    when(preferences.getBackupPassword).thenAnswer((_) async => null);
    when(preferences.getBackupLastAt).thenAnswer((_) async => null);
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    bool isLocked = true,
  }) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        appBootstrapProvider.overrideWithValue(
          AppBootstrap(appLockEnabled: isLocked, lockGraceMinutes: 5),
        ),
        preferencesRepositoryProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('the grace row offers Off, 1, 5 and 15', (tester) async {
    await pump(tester);

    expect(find.text('Re-lock after'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SegmentedControl<int>),
        matching: find.text('Off'),
      ),
      findsOneWidget,
    );
    expect(find.text('1 min'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
  });

  testWidgets('picking 1 stores it', (tester) async {
    final container = await pump(tester);
    expect(container.read(appLockEnabledProvider), isTrue);

    await tester.tap(find.text('1 min'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(container.read(appLockGraceMinutesProvider), 1);
    verify(() => preferences.setLockGraceMinutes(1)).called(1);
  });

  testWidgets('the grace row is inert while the lock is off', (tester) async {
    await pump(tester, isLocked: false);

    await tester.tap(find.text('1 min'));
    await tester.pumpAndSettle();

    expect(containerFor(tester).read(appLockGraceMinutesProvider), 5);
    verifyNever(() => preferences.setLockGraceMinutes(any()));
  });
}

ProviderContainer containerFor(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));