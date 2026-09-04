import 'package:anchor/core/notifications/notification_gateway.dart';
import 'package:anchor/core/notifications/reminder_permissions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeGateway implements NotificationGateway {
  FakeGateway({
    this.notifications = false,
    this.exact = false,
    this.gatesExactAlarms = true,
  });

  bool notifications;
  bool exact;

  @override
  final bool gatesExactAlarms;

  int requests = 0;
  int exactScreensOpened = 0;

  bool grantOnRequest = true;

  @override
  Future<bool> hasPermission() async => notifications;

  @override
  Future<bool> requestPermission() async {
    requests++;
    if (grantOnRequest) notifications = true;
    return notifications;
  }

  @override
  Future<bool> canScheduleExact() async => exact;

  @override
  Future<void> requestExactPermission() async => exactScreensOpened++;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<int>> pendingIds() async => const [];

  @override
  Future<void> schedule(ScheduledNotification notification) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerFor(FakeGateway gateway) {
    final container = ProviderContainer(
      overrides: [notificationGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<ReminderPermissions> read(FakeGateway gateway) =>
      containerFor(gateway).read(reminderPermissionsControllerProvider.future);

  group('ringsOnTime', () {
    test('needs notifications before anything else', () async {
      final permissions = await read(
        FakeGateway(notifications: false, exact: true),
      );
      expect(permissions.ringsOnTime, isFalse);
    });

    test('is false while Android still gates exact alarms', () async {
      final permissions = await read(
        FakeGateway(notifications: true, exact: false),
      );
      expect(permissions.canNotify, isTrue);
      expect(permissions.ringsOnTime, isFalse);
    });

    test('is true once both grants are in place', () async {
      final permissions = await read(
        FakeGateway(notifications: true, exact: true),
      );
      expect(permissions.ringsOnTime, isTrue);
    });

    test(
      'ignores exact alarms on a platform that does not gate them',
      () async {
        final permissions = await read(
          FakeGateway(
            notifications: true,
            exact: false,
            gatesExactAlarms: false,
          ),
        );
        expect(permissions.exactMatters, isFalse);
        expect(permissions.ringsOnTime, isTrue);
      },
    );
  });

  test(
    'requesting notifications reflects the new grant in the state',
    () async {
      final gateway = FakeGateway();
      final container = containerFor(gateway);
      await container.read(reminderPermissionsControllerProvider.future);

      final notifier = container.read(
        reminderPermissionsControllerProvider.notifier,
      );
      expect(await notifier.requestNotifications(), isTrue);

      expect(gateway.requests, 1);
      expect(
        container.read(reminderPermissionsControllerProvider).value?.canNotify,
        isTrue,
      );
    },
  );

  test('a refused request leaves the state denied', () async {
    final gateway = FakeGateway()..grantOnRequest = false;
    final container = containerFor(gateway);
    await container.read(reminderPermissionsControllerProvider.future);

    final notifier = container.read(
      reminderPermissionsControllerProvider.notifier,
    );
    expect(await notifier.requestNotifications(), isFalse);
    expect(
      container.read(reminderPermissionsControllerProvider).value?.canNotify,
      isFalse,
    );
  });

  test(
    'opening the exact-alarm screen does not itself grant anything',
    () async {
      final gateway = FakeGateway(notifications: true);
      final container = containerFor(gateway);
      await container.read(reminderPermissionsControllerProvider.future);

      final notifier = container.read(
        reminderPermissionsControllerProvider.notifier,
      );
      await notifier.openExactSettings();

      expect(gateway.exactScreensOpened, 1);
      expect(
        container.read(reminderPermissionsControllerProvider).value?.canBeExact,
        isFalse,
      );

      gateway.exact = true;
      expect((await notifier.refresh()).canBeExact, isTrue);
    },
  );
}
