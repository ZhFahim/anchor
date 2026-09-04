import 'package:anchor/core/notifications/notification_gateway.dart';
import 'package:anchor/core/notifications/reminder_permission_prompt.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/features/settings/data/repository/preferences_repository.dart';
import 'package:anchor/features/settings/presentation/controllers/editor_preferences_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reminder_permissions_test.dart' show FakeGateway;

/// Holds the flow's one persisted flag in memory.
class FakePreferences extends PreferencesRepository {
  FakePreferences() : super(const FlutterSecureStorage());

  bool offeredExact = false;

  @override
  Future<bool> getExactAlarmsOffered() async => offeredExact;

  @override
  Future<void> setExactAlarmsOffered(bool value) async => offeredExact = value;
}

void main() {
  late FakePreferences prefs;

  setUp(() => prefs = FakePreferences());

  Future<void> run(
    WidgetTester tester,
    FakeGateway gateway, {
    required ReminderPermissionTrigger trigger,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () =>
                      ensureReminderPermissions(context, ref, trigger: trigger),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationGatewayProvider.overrideWithValue(gateway),
          preferencesRepositoryProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
  }

  testWidgets('a reminder set here asks the system straight away', (
    tester,
  ) async {
    final gateway = FakeGateway(gatesExactAlarms: false);
    await run(tester, gateway, trigger: ReminderPermissionTrigger.userSet);

    expect(find.text('Remind you on this device?'), findsNothing);
    expect(gateway.requests, 1);
  });

  testWidgets('a synced reminder explains itself before the system dialog', (
    tester,
  ) async {
    final gateway = FakeGateway(gatesExactAlarms: false);
    await run(tester, gateway, trigger: ReminderPermissionTrigger.synced);

    expect(find.text('Remind you on this device?'), findsOneWidget);
    expect(gateway.requests, 0, reason: 'nothing asked until the user agrees');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(gateway.requests, 1);
  });

  testWidgets('declining the explanation asks the system nothing', (
    tester,
  ) async {
    final gateway = FakeGateway(gatesExactAlarms: false);
    await run(tester, gateway, trigger: ReminderPermissionTrigger.synced);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(gateway.requests, 0);
  });

  testWidgets('a refused grant says where to turn it back on', (tester) async {
    final gateway = FakeGateway(gatesExactAlarms: false)
      ..grantOnRequest = false;
    await run(tester, gateway, trigger: ReminderPermissionTrigger.userSet);

    expect(find.textContaining('system settings'), findsOneWidget);
  });

  testWidgets('exact alarms are not raised while notifications are off', (
    tester,
  ) async {
    final gateway = FakeGateway()..grantOnRequest = false;
    await run(tester, gateway, trigger: ReminderPermissionTrigger.userSet);

    expect(find.text('Remind you at the exact minute?'), findsNothing);
    expect(prefs.offeredExact, isFalse);
  });

  testWidgets('exact alarms are offered once notifications are granted', (
    tester,
  ) async {
    final gateway = FakeGateway();
    await run(tester, gateway, trigger: ReminderPermissionTrigger.userSet);

    expect(find.text('Remind you at the exact minute?'), findsOneWidget);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(gateway.exactScreensOpened, 1);
  });

  testWidgets('the exact-alarm offer is never made twice', (tester) async {
    prefs.offeredExact = true;
    final gateway = FakeGateway(notifications: true);
    await run(tester, gateway, trigger: ReminderPermissionTrigger.userSet);

    expect(find.text('Remind you at the exact minute?'), findsNothing);
  });

  testWidgets('declining exact alarms still counts as answered', (
    tester,
  ) async {
    final gateway = FakeGateway(notifications: true);
    await run(tester, gateway, trigger: ReminderPermissionTrigger.userSet);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(gateway.exactScreensOpened, 0);
    expect(prefs.offeredExact, isTrue);
  });

  testWidgets('nothing is asked when the device is already set up', (
    tester,
  ) async {
    final gateway = FakeGateway(notifications: true, exact: true);
    await run(tester, gateway, trigger: ReminderPermissionTrigger.synced);

    expect(find.byType(Dialog), findsNothing);
    expect(gateway.requests, 0);
  });
}
