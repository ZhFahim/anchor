import 'package:anchor/core/text/date_formats.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/notes/domain/note_attachment.dart';
import 'package:anchor/features/notes/domain/note_dates.dart';
import 'package:anchor/features/notes/domain/note_share_permission.dart';
import 'package:anchor/features/notes/presentation/note_labels.dart';
import 'package:anchor/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

final _english = lookupAppLocalizations(const Locale('en'));

void main() {
  group('sharing', () {
    test('access reads the same in the pill, the menu and the snackbar', () {
      expect(permissionLabel(NoteSharePermission.viewer, _english), 'Can view');
      expect(permissionLabel(NoteSharePermission.editor, _english), 'Can edit');
      expect(
        permissionChangedLabel(NoteSharePermission.editor, 'Leo', _english),
        'Leo can now edit',
      );
      expect(
        permissionChangedLabel(NoteSharePermission.viewer, 'Leo', _english),
        'Leo can now view',
      );
    });

    test('without the list of people, it counts them', () {
      expect(
        sharedCountLabel(0, _english, isOnline: false),
        _english.shareOnlyYou,
      );
      expect(
        sharedCountLabel(1, _english, isOnline: true),
        'Shared with 1 person.',
      );
      expect(
        sharedCountLabel(2, _english, isOnline: false),
        'Shared with 2 people. Connect to see who has access.',
      );
    });
  });

  group('names', () {
    test('a first name is the first word, whatever the spacing', () {
      expect(firstNameOf('Ada Lovelace'), 'Ada');
      expect(firstNameOf('  Ada   Lovelace '), 'Ada');
      expect(firstNameOf('Ada'), 'Ada');
    });

    test('names run to two, then say how many more', () {
      expect(namesLabel(['Ada'], _english), 'Ada');
      expect(namesLabel(['Ada', 'Ben'], _english), 'Ada and Ben');
      expect(
        namesLabel(['Ada', 'Ben', 'Cy', 'Di'], _english),
        'Ada, Ben and 2 more',
      );
    });
  });

  group('titles', () {
    test('a blank title shows as Untitled and is kept empty', () {
      expect(displayTitleOf('', _english), 'Untitled');
      expect(displayTitleOf('   ', _english), 'Untitled');
      expect(displayTitleOf(' Groceries ', _english), ' Groceries ');
      expect(storedTitleOf('   '), '');
      expect(storedTitleOf(' Groceries '), ' Groceries ');
    });
  });

  group('days', () {
    final now = DateTime(2026, 8, 18, 15);
    String time(int hour, [int minute = 0]) =>
        clockLabel(DateTime(2026, 1, 1, hour, minute));

    test('history names today, yesterday and other days in full', () {
      expect(dayLabel(DateTime(2026, 8, 18, 9), now, _english), 'Today');
      expect(dayLabel(DateTime(2026, 8, 17, 23), now, _english), 'Yesterday');
      expect(dayLabel(DateTime(2026, 8, 2), now, _english), 'August 2, 2026');
    });

    test('cards name this year short and add the year for others', () {
      expect(
        shortDayLabel(DateTime(2026, 8, 18, 1), _english, now: now),
        'Today',
      );
      expect(
        shortDayLabel(DateTime(2026, 8, 17), _english, now: now),
        'Yesterday',
      );
      expect(shortDayLabel(DateTime(2026, 3, 4), _english, now: now), 'Mar 4');
      expect(
        shortDayLabel(DateTime(2025, 3, 4), _english, now: now),
        'Mar 4, 2025',
      );
    });

    test('a day and time reads as one phrase', () {
      expect(
        dayTimeLabel(DateTime(2026, 8, 18, 16, 5), _english, now: now),
        'Today at ${time(16, 5)}',
      );
      expect(
        dayTimeLabel(DateTime(2026, 8, 2, 9), _english, now: now),
        'August 2, 2026 at ${time(9)}',
      );
    });

    test('the time of day follows the phone\'s 12 or 24-hour clock', () {
      final at = DateTime(2026, 8, 18, 16, 5);
      expect(clockLabel(at, is24Hour: false), DateFormat.jm('en').format(at));
      expect(clockLabel(at, is24Hour: true), '16:05');
    });

    test('says when a note was edited', () {
      expect(
        editedDayLabel(DateTime(2026, 8, 18, 9), _english, now: now),
        'Edited today',
      );
      expect(
        editedDayLabel(DateTime(2026, 3, 4), _english, now: now),
        'Edited Mar 4',
      );
      expect(
        editedTimeLabel(
          now.subtract(const Duration(seconds: 20)),
          _english,
          now: now,
        ),
        'Edited just now',
      );
      expect(
        editedTimeLabel(
          now.subtract(const Duration(minutes: 5)),
          _english,
          now: now,
        ),
        'Edited 5 min ago',
      );
      expect(
        editedTimeLabel(DateTime(2026, 8, 18, 9, 30), _english, now: now),
        'Edited today at ${time(9, 30)}',
      );
      expect(
        editedTimeLabel(DateTime(2026, 8, 17, 9), _english, now: now),
        'Edited yesterday at ${time(9)}',
      );
    });
  });

  group('attachments', () {
    test('a recording made in the app is a voice note, other audio a file', () {
      AttachmentKind kindOf(String mimeType, String filename) =>
          AttachmentKind.of(mimeType: mimeType, filename: filename);

      expect(kindOf('audio/mp4', 'recording_17.m4a'), AttachmentKind.voiceNote);
      expect(kindOf('audio/mpeg', 'interview.mp3'), AttachmentKind.audioFile);
      expect(kindOf('image/jpeg', 'recording_17.jpg'), AttachmentKind.picture);
    });

    test('each kind is named in its toasts', () {
      expect(
        attachmentAddedLabel(
          AttachmentKind.audioFile,
          _english,
          isOnline: true,
        ),
        'Audio file added',
      );
      expect(
        attachmentAddedLabel(
          AttachmentKind.voiceNote,
          _english,
          isOnline: false,
        ),
        'Voice note added. It will upload when you’re back online.',
      );
      expect(
        attachmentAddFailedLabel(AttachmentKind.picture, _english),
        'Couldn’t add the picture',
      );
      expect(
        attachmentDeletedLabel(AttachmentKind.audioFile, _english),
        'Audio file deleted',
      );
    });
  });

  group('the trash', () {
    final now = DateTime(2026, 8, 18, 15);

    test('counts down the days a trashed note has left', () {
      expect(trashDaysLeftLabel(now, _english, now: now), '30 days left');
      expect(
        trashDaysLeftLabel(
          now.subtract(const Duration(days: 29)),
          _english,
          now: now,
        ),
        '1 day left',
      );
      expect(
        trashDaysLeftLabel(
          now.subtract(const Duration(days: 45)),
          _english,
          now: now,
        ),
        '0 days left',
      );
      expect(trashDaysLeftLabel(null, _english, now: now), '30 days left');
    });

    test('says when a trashed note goes for good', () {
      expect(
        trashDeletionLabel(DateTime(2026, 8, 1, 12), _english, now: now),
        'Will be deleted on August 31.',
      );
      expect(
        trashDeletionLabel(null, _english),
        'Will be deleted after 30 days.',
      );
    });

    test('the rules name the same number of days', () {
      expect(_english.trashRule(trashDays), contains('$trashDays days'));
      expect(_english.trashEmpty(trashDays), contains('$trashDays days'));
      expect(_english.historyKept(historyDays), contains('$historyDays days'));
      expect(_english.historyLimit(historyDays), contains('$historyDays days'));
    });
  });
}
