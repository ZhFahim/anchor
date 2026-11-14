import 'dart:async';

import 'package:anchor/app/app_bootstrap.dart';
import 'package:anchor/core/storage/preferences_repository.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/widgets/app_buttons.dart';
import 'package:anchor/features/settings/presentation/app_lock_controller.dart';
import 'package:anchor/features/settings/presentation/app_lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAuthenticator implements DeviceAuthenticator {
  _FakeAuthenticator({this.succeeds = true, this.failure, this.holds = false});

  final bool succeeds;

  /// Thrown instead of returning, to stand in for a device that cannot prompt.
  final Object? failure;

  /// While true the prompt stays up, so a test can look at the cover first.
  final bool holds;

  final _answers = <Completer<bool>>[];

  int calls = 0;

  /// Lets the newest held prompt finish.
  void answer(bool didAuthenticate) {
    _answers.last.complete(didAuthenticate);
  }

  @override
  Future<bool> authenticate() {
    calls++;
    if (holds) {
      final answer = Completer<bool>();
      _answers.add(answer);
      return answer.future;
    }
    if (failure != null) return Future.error(failure!);
    return Future.value(succeeds);
  }
}

AppBootstrap _bootstrap({required bool isLocked}) =>
    AppBootstrap(appLockEnabled: isLocked, userId: 'user-1');

class _MockPreferences extends Mock implements PreferencesRepository {}

ProviderContainer _container({
  required bool isLocked,
  required DeviceAuthenticator authenticator,
}) {
  final preferences = _MockPreferences();
  when(() => preferences.setAppLockEnabled(any())).thenAnswer((_) async {});
  final container = ProviderContainer(
    overrides: [
      appBootstrapProvider.overrideWithValue(_bootstrap(isLocked: isLocked)),
      deviceAuthenticatorProvider.overrideWithValue(authenticator),
      preferencesRepositoryProvider.overrideWithValue(preferences),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<_FakeAuthenticator> _pump(
  WidgetTester tester, {
  required bool isLocked,
  _FakeAuthenticator? authenticator,
}) async {
  final auth = authenticator ?? _FakeAuthenticator();
  final container = _container(isLocked: isLocked, authenticator: auth);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const AppLockGate(
          child: Scaffold(body: Text('a note about the harbour')),
        ),
      ),
    ),
  );
  // A held prompt never settles, so pump once rather than waiting it out.
  if (auth.holds) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
  return auth;
}

void main() {
  testWidgets('shows the notes when the lock is off', (tester) async {
    final auth = await _pump(tester, isLocked: false);

    expect(find.text('a note about the harbour'), findsOneWidget);
    expect(find.byType(AppLockScreen), findsNothing);
    expect(auth.calls, 0);
  });

  testWidgets('covers the notes and asks the device on a locked start', (
    tester,
  ) async {
    final auth = await _pump(
      tester,
      isLocked: true,
      authenticator: _FakeAuthenticator(holds: true),
    );

    expect(find.byType(AppLockScreen), findsOneWidget);
    expect(find.text('Anchor is locked'), findsOneWidget);
    expect(auth.calls, 1);
  });

  testWidgets('uncovers the notes once the device lets the person in', (
    tester,
  ) async {
    final auth = await _pump(
      tester,
      isLocked: true,
      authenticator: _FakeAuthenticator(holds: true),
    );
    expect(find.byType(AppLockScreen), findsOneWidget);

    auth.answer(true);
    await tester.pumpAndSettle();

    expect(find.byType(AppLockScreen), findsNothing);
    expect(find.text('a note about the harbour'), findsOneWidget);
  });

  testWidgets('keeps the cover and says so when the person cancels', (
    tester,
  ) async {
    await _pump(
      tester,
      isLocked: true,
      authenticator: _FakeAuthenticator(succeeds: false),
    );

    expect(find.byType(AppLockScreen), findsOneWidget);
    expect(find.text('The device did not unlock. Try again.'), findsOneWidget);
  });

  testWidgets('keeps the cover when the device has no screen lock', (
    tester,
  ) async {
    await _pump(
      tester,
      isLocked: true,
      authenticator: _FakeAuthenticator(
        failure: LocalAuthException(
          code: LocalAuthExceptionCode.noCredentialsSet,
        ),
      ),
    );

    expect(find.byType(AppLockScreen), findsOneWidget);
    expect(find.text('Set a screen lock on this device first.'), findsOneWidget);
  });

  testWidgets('covers the notes again when the app goes to the background', (
    tester,
  ) async {
    final auth = await _pump(
      tester,
      isLocked: true,
      authenticator: _FakeAuthenticator(holds: true),
    );
    auth.answer(true);
    await tester.pumpAndSettle();
    expect(find.byType(AppLockScreen), findsNothing);

    // The default grace is five minutes, so push the unlock out of it.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(AppLockGate)));
    container
        .read(appLockControllerProvider.notifier)
        .debugMarkUnlocked(DateTime.now().subtract(const Duration(minutes: 10)));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    // A paused app draws no frame, so the cover shows on the way back.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.byType(AppLockScreen), findsOneWidget);
    expect(auth.calls, 2);
  });

  testWidgets('a return inside the grace window does not ask again', (
    tester,
  ) async {
    final auth = await _pump(tester, isLocked: true);
    await tester.pumpAndSettle();
    expect(auth.calls, 1);

    // The person unlocked, then left and came back inside the window.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(AppLockGate)));
    container
        .read(appLockControllerProvider.notifier)
        .debugMarkUnlocked(DateTime.now());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.byType(AppLockScreen), findsNothing);
    expect(auth.calls, 1, reason: 'the second entry must not prompt');
  });

  testWidgets('the cover waits without a spinner on its button', (
    tester,
  ) async {
    await _pump(
      tester,
      isLocked: true,
      authenticator: _FakeAuthenticator(holds: true),
    );

    expect(find.text('Waiting for the device…'), findsOneWidget);
    expect(find.byType(Spinner), findsNothing);
  });

  test('turning the lock off stores the choice and takes the cover away', () async {
    final container = _container(
      isLocked: true,
      authenticator: _FakeAuthenticator(),
    );
    expect(container.read(appLockControllerProvider), isTrue);

    final problem = await container
        .read(appLockControllerProvider.notifier)
        .setEnabled(false);

    expect(problem, isNull);
    expect(container.read(appLockEnabledProvider), isFalse);
    expect(container.read(appLockControllerProvider), isFalse);
  });

  test('a lock that is off does not cover the notes', () async {
    final container = _container(
      isLocked: false,
      authenticator: _FakeAuthenticator(),
    );

    container.read(appLockControllerProvider.notifier).lock();

    expect(container.read(appLockControllerProvider), isFalse);
  });
}
