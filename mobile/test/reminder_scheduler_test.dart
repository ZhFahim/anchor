import 'dart:async';

import 'package:anchor/app/app_bootstrap.dart';
import 'package:anchor/core/session/active_user_id_provider.dart';
import 'package:anchor/features/auth/domain/user.dart';
import 'package:anchor/features/auth/presentation/auth_controller.dart';
import 'package:anchor/features/notes/data/repository/notes_repository.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/reminders/data/missed_reminders.dart';
import 'package:anchor/features/reminders/data/notification_gateway.dart';
import 'package:anchor/features/reminders/data/reminder_scheduler.dart';
import 'package:anchor/features/reminders/domain/reminder_schedule.dart';
import 'package:anchor/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingGateway implements NotificationGateway {
  RecordingGateway({
    this.failsOnId,
    this.failsOnce = false,
    this.pending = const [],
    this.hold,
    this.throwsOnCancelAll = false,
  });

  final int? failsOnId;

  final bool failsOnce;
  final List<int> pending;

  /// Holds the first pass inside [pendingIds] until it is completed.
  final Completer<void>? hold;

  final bool throwsOnCancelAll;

  final scheduled = <int>[];
  final cancelled = <int>[];
  final shown = <int>[];
  int cancelAllCalls = 0;

  int passes = 0;
  int _refusals = 0;

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    if (notification.id == failsOnId && (!failsOnce || _refusals == 0)) {
      _refusals++;
      throw Exception('the OS refused notification ${notification.id}');
    }
    scheduled.add(notification.id);
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<void> show(ScheduledNotification notification) async =>
      shown.add(notification.id);

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    if (throwsOnCancelAll) throw Exception('the OS refused to clear');
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<List<int>> pendingIds() async {
    passes++;
    final waiting = hold;
    if (waiting != null && !waiting.isCompleted) await waiting.future;
    return pending;
  }

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  bool get requiresExactAlarmPermission => false;

  @override
  Future<bool> canScheduleExact() async => true;

  @override
  Future<void> requestExactPermission() async {}
}

class MemoryRungReminders implements RungReminders {
  MemoryRungReminders([this.keys]);

  Set<String>? keys;

  @override
  Future<Set<String>?> read() async => keys == null ? null : {...keys!};

  @override
  Future<void> write(Set<String> keys) async => this.keys = {...keys};
}

class StubAuthController extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: 'user-1', email: 'me@example.com', name: 'Me');
}

class StubNotesRepository implements NotesRepository {
  StubNotesRepository(this._notes);

  final Stream<List<Note>> _notes;

  @override
  Stream<List<Note>> watchNotes({String? tagId}) => _notes;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final _english = lookupAppLocalizations(const Locale('en'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 4, 12);

  Note note({
    required String id,
    required int slot,
    String? remindAt,
    ReminderRecurrence recurrence = ReminderRecurrence.none,
    NoteState state = NoteState.active,
    bool isArchived = false,
    String title = 'Groceries',
    String? content,
  }) => Note(
    id: id,
    title: title,
    content: content,
    state: state,
    isArchived: isArchived,
    reminderSlot: slot,
    reminder: remindAt == null
        ? null
        : NoteReminder(remindAt: remindAt, recurrence: recurrence),
  );

  test('schedules a future reminder against its slot', () {
    final desired = desiredReminders(
      [note(id: 'n1', slot: 7, remindAt: '2026-09-04T18:00')],
      now: now,
      l10n: _english,
    );

    expect(desired, hasLength(1));
    expect(desired.single.id, 7);
    expect(desired.single.at, DateTime(2026, 9, 4, 18));
    expect(desired.single.noteId, 'n1');
    expect(desired.single.title, 'Groceries');
  });

  test('heads a note with no title with its first line of text', () {
    final desired = desiredReminders(
      [
        note(
          id: 'n1',
          slot: 1,
          remindAt: '2026-09-04T18:00',
          title: '  ',
          content: '{"ops":[{"insert":"\\nBuy milk\\nand eggs\\n"}]}',
        ),
      ],
      now: now,
      l10n: _english,
    );

    expect(desired.single.title, 'Buy milk');
    expect(desired.single.body, 'and eggs');
  });

  test("puts a titled note's first line of text under the title", () {
    final desired = desiredReminders(
      [
        note(
          id: 'n1',
          slot: 1,
          remindAt: '2026-09-04T18:00',
          content: '{"ops":[{"insert":"\\nBuy milk\\nand eggs\\n"}]}',
        ),
      ],
      now: now,
      l10n: _english,
    );

    expect(desired.single.title, 'Groceries');
    expect(desired.single.body, 'Buy milk');
  });

  test('leaves the body empty when the heading is the only line', () {
    final desired = desiredReminders(
      [
        note(
          id: 'n1',
          slot: 1,
          remindAt: '2026-09-04T18:00',
          title: '',
          content: '{"ops":[{"insert":"Buy milk\\n"}]}',
        ),
      ],
      now: now,
      l10n: _english,
    );

    expect(desired.single.title, 'Buy milk');
    expect(desired.single.body, isEmpty);
  });

  test('heads a note with no title or text with just "Reminder"', () {
    final desired = desiredReminders(
      [note(id: 'n1', slot: 1, remindAt: '2026-09-04T18:00', title: '')],
      now: now,
      l10n: _english,
    );

    expect(desired.single.title, 'Reminder');
    expect(desired.single.body, isEmpty);
  });

  test('drops a note with no reminder', () {
    expect(
      desiredReminders(
        [note(id: 'n1', slot: 1)],
        now: now,
        l10n: _english,
      ),
      isEmpty,
    );
  });

  test('drops a one-off whose time has passed', () {
    final desired = desiredReminders(
      [note(id: 'n1', slot: 1, remindAt: '2026-09-04T09:00')],
      now: now,
      l10n: _english,
    );
    expect(desired, isEmpty);
  });

  test('keeps a repeating reminder anchored in the past', () {
    final desired = desiredReminders(
      [
        note(
          id: 'n1',
          slot: 1,
          remindAt: '2026-09-01T09:00',
          recurrence: ReminderRecurrence.daily,
        ),
      ],
      now: now,
      l10n: _english,
    );
    expect(desired.single.at, DateTime(2026, 9, 5, 9));
    expect(desired.single.repeat, DateTimeComponents.time);
  });

  test('drops trashed and archived notes', () {
    final desired = desiredReminders(
      [
        note(
          id: 'n1',
          slot: 1,
          remindAt: '2026-09-04T18:00',
          state: NoteState.trashed,
        ),
        note(id: 'n2', slot: 2, remindAt: '2026-09-04T18:00', isArchived: true),
      ],
      now: now,
      l10n: _english,
    );
    expect(desired, isEmpty);
  });

  test('skips a reminder that has no slot yet', () {
    final orphan = Note(
      id: 'n1',
      title: 'no slot',
      reminder: const NoteReminder(remindAt: '2026-09-04T18:00'),
    );
    expect(desiredReminders([orphan], now: now, l10n: _english), isEmpty);
  });

  test('orders soonest first', () {
    final desired = desiredReminders(
      [
        note(id: 'late', slot: 1, remindAt: '2026-09-06T09:00'),
        note(id: 'soon', slot: 2, remindAt: '2026-09-04T18:00'),
        note(id: 'mid', slot: 3, remindAt: '2026-09-05T09:00'),
      ],
      now: now,
      l10n: _english,
    );

    expect(desired.map((item) => item.noteId), ['soon', 'mid', 'late']);
  });

  test('caps at the soonest maxScheduledReminders', () {
    final notes = [
      for (var i = 0; i < maxScheduledReminders + 20; i++)
        note(id: 'n$i', slot: i + 1, remindAt: '2026-09-04T18:00'),
    ];

    expect(
      desiredReminders(notes, now: now, l10n: _english),
      hasLength(maxScheduledReminders),
    );
  });

  test('maps every recurrence onto an OS repeat', () {
    expect(matchComponentsFor(ReminderRecurrence.none), isNull);
    expect(
      matchComponentsFor(ReminderRecurrence.daily),
      DateTimeComponents.time,
    );
    expect(
      matchComponentsFor(ReminderRecurrence.weekly),
      DateTimeComponents.dayOfWeekAndTime,
    );
    expect(
      matchComponentsFor(ReminderRecurrence.monthly),
      DateTimeComponents.dayOfMonthAndTime,
    );
    expect(
      matchComponentsFor(ReminderRecurrence.yearly),
      DateTimeComponents.dateAndTime,
    );
  });

  group('repeating reminders that start later', () {
    DesiredReminder only(
      String remindAt,
      ReminderRecurrence recurrence, {
      required DateTime now,
    }) => desiredReminders(
      [note(id: 'n1', slot: 1, remindAt: remindAt, recurrence: recurrence)],
      now: now,
      l10n: _english,
    ).single;

    test('the OS alone would ring a monthly start in March today', () {
      expect(
        osFiring(
          DateTime(2027, 3, 1, 9),
          DateTimeComponents.dayOfMonthAndTime,
          from: DateTime(2026, 11, 1, 7),
        ),
        DateTime(2026, 11, 1, 9),
      );
    });

    test('rings a monthly reminder once on its start date', () {
      final desired = only(
        '2027-03-01T09:00',
        ReminderRecurrence.monthly,
        now: DateTime(2026, 11, 1, 7),
      );

      expect(desired.at, DateTime(2027, 3, 1, 9));
      expect(desired.repeat, isNull);
    });

    test('hands the series to the OS once the start is a cycle away', () {
      final desired = only(
        '2027-03-01T09:00',
        ReminderRecurrence.monthly,
        now: DateTime(2027, 2, 15, 7),
      );

      expect(desired.at, DateTime(2027, 3, 1, 9));
      expect(desired.repeat, DateTimeComponents.dayOfMonthAndTime);
    });

    test('rings once whenever the start is more than a cycle away', () {
      final now = DateTime(2026, 11, 1, 7);
      for (final (remindAt, recurrence) in [
        ('2026-11-03T09:00', ReminderRecurrence.daily),
        ('2026-11-15T09:00', ReminderRecurrence.weekly),
        ('2028-11-01T09:00', ReminderRecurrence.yearly),
      ]) {
        final desired = only(remindAt, recurrence, now: now);
        expect(desired.at, parseWallClock(remindAt), reason: '$recurrence');
        expect(desired.repeat, isNull, reason: '$recurrence');
      }
    });

    test('rings once on a short month the OS would keep repeating', () {
      // Anchored on the 31st: September rings on the 30th, October on the
      // 31st again, where the OS would repeat the 30th.
      final desired = only(
        '2026-08-31T09:00',
        ReminderRecurrence.monthly,
        now: now,
      );

      expect(desired.at, DateTime(2026, 9, 30, 9));
      expect(desired.repeat, isNull);
    });
  });

  group('applyReminders', () {
    final soon = DateTime(2026, 9, 4, 18);

    DesiredReminder desired(int id) => DesiredReminder(
      id: id,
      at: soon,
      title: 'Groceries',
      repeat: null,
      noteId: 'n$id',
    );

    test('schedules every reminder and cancels the orphans', () async {
      final gateway = RecordingGateway();

      final report = await applyReminders(
        gateway,
        [desired(1), desired(2)],
        pending: {2, 9},
      );

      expect(gateway.scheduled, [1, 2]);
      expect(gateway.cancelled, [9]);
      expect(report.cancelled, 1);
      expect(report.failed, 0);
    });

    test('one reminder the OS refuses does not stop the rest', () async {
      final gateway = RecordingGateway(failsOnId: 2);

      final report = await applyReminders(gateway, [
        desired(1),
        desired(2),
        desired(3),
      ], pending: const {});

      expect(gateway.scheduled, [1, 3]);
      expect(report.failed, 1);
    });
  });

  group('ReminderScheduler', () {
    /// Long enough for the notes watch to settle and one pass to run.
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 1500));

    Future<ProviderContainer> start(
      RecordingGateway gateway,
      Stream<List<Note>> notes, {
      String? userId = 'user-1',
      RungReminders? rung,
    }) async {
      final container = ProviderContainer(
        overrides: [
          appBootstrapProvider.overrideWithValue(AppBootstrap(userId: userId)),
          notificationGatewayProvider.overrideWithValue(gateway),
          rungRemindersProvider.overrideWithValue(
            rung ?? MemoryRungReminders(),
          ),
          notesRepositoryProvider.overrideWithValue(StubNotesRepository(notes)),
          authControllerProvider.overrideWith(StubAuthController.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);
      // Riverpod pauses a provider nobody listens to.
      container.listen(reminderSchedulerProvider, (_, _) {});
      return container;
    }

    Note pending(String id, int slot) =>
        note(id: id, slot: slot, remindAt: '2026-12-01T09:00');

    test('a launch leaves the notifications on screen alone', () async {
      final gateway = RecordingGateway();

      await start(gateway, Stream.value([pending('n1', 1)]));
      await settle();

      expect(gateway.cancelAllCalls, 0);
      expect(gateway.scheduled, [1]);
    });

    test('rings a reminder that came in after its time, once', () async {
      final gateway = RecordingGateway();
      final rung = MemoryRungReminders({});
      final late = note(
        id: 'n1',
        slot: 3,
        remindAt: toWallClock(
          DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      final notes = StreamController<List<Note>>();
      addTearDown(notes.close);

      await start(gateway, notes.stream, rung: rung);
      notes.add([late]);
      await settle();
      notes.add([late, pending('n2', 4)]);
      await settle();

      expect(gateway.shown, [3]);
      expect(rung.keys, contains(rungKey('n1', late.reminder!.remindAt)));
    });

    test('the first pass on a phone rings nothing it finds late', () async {
      final gateway = RecordingGateway();
      final rung = MemoryRungReminders();
      final late = note(
        id: 'n1',
        slot: 3,
        remindAt: toWallClock(
          DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

      await start(gateway, Stream.value([late]), rung: rung);
      await settle();

      expect(gateway.shown, isEmpty);
      expect(rung.keys, {rungKey('n1', late.reminder!.remindAt)});
    });

    test('signing out clears everything the OS holds', () async {
      final gateway = RecordingGateway();

      await start(gateway, const Stream.empty(), userId: null);
      await settle();

      expect(gateway.cancelAllCalls, 1);
    });

    test('a launch with no reminders still cancels the leftovers', () async {
      final gateway = RecordingGateway(pending: const [5]);

      await start(gateway, Stream.value(const []));
      await settle();

      expect(gateway.cancelled, [5]);
      expect(gateway.cancelAllCalls, 0);
    });

    test('a second trigger waits for the pass already running', () async {
      final gateway = RecordingGateway(hold: Completer<void>());
      final notes = StreamController<List<Note>>();
      addTearDown(notes.close);

      await start(gateway, notes.stream);

      notes.add([pending('n1', 1)]);
      await settle();
      expect(gateway.passes, 1, reason: 'the first pass is still held');

      notes.add([pending('n1', 1), pending('n2', 2)]);
      await settle();
      expect(gateway.passes, 1, reason: 'the held pass must finish first');

      gateway.hold!.complete();
      await settle();

      expect(gateway.passes, 2);
      expect(gateway.scheduled, containsAll([1, 2]));
    });

    test('a pass the OS refused is tried again on its own', () async {
      final gateway = RecordingGateway(failsOnId: 1, failsOnce: true);

      await start(gateway, Stream.value([pending('n1', 1)]));
      await settle();
      expect(gateway.scheduled, isEmpty);

      await Future<void>.delayed(reminderRetryDelay(1) * 2);

      expect(gateway.scheduled, [1]);
    });

    test('a sign-out that failed does not cost the next user', () async {
      final gateway = RecordingGateway(throwsOnCancelAll: true);
      final notes = StreamController<List<Note>>();
      addTearDown(notes.close);

      final container = await start(gateway, notes.stream, userId: null);
      await settle();
      expect(gateway.cancelAllCalls, 1);

      container.read(activeUserIdProvider.notifier).set('user-1');
      container.read(reminderSchedulerProvider);
      notes.add([pending('n1', 1)]);
      await settle();

      expect(gateway.scheduled, [1]);
    });

    test('the wait before another try grows and then levels off', () {
      expect(reminderRetryDelay(1), const Duration(seconds: 2));
      expect(reminderRetryDelay(2) > reminderRetryDelay(1), isTrue);
      expect(reminderRetryDelay(20), reminderRetryDelay(_retryDelayCount));
    });
  });

  test('a locked note without a title rings without its text', () {
    const note = Note(
      id: 'n1',
      title: '',
      content: '{"ops":[{"insert":"my secret\\n"}]}',
    );
    expect(reminderHeading(note), 'my secret');
    expect(reminderHeading(note.copyWith(lock: NoteLock.pin)), isNull);
    expect(
      reminderHeading(note.copyWith(title: 'Diary', lock: NoteLock.pin)),
      'Diary',
    );
  });
}

const int _retryDelayCount = 5;
