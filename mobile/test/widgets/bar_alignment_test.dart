import 'dart:io';

import 'package:anchor/core/network/connectivity_provider.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/theme/app_typography.dart';
import 'package:anchor/core/theme/display_density.dart';
import 'package:anchor/core/widgets/anchor_logo.dart';
import 'package:anchor/core/widgets/anchor_sheet.dart';
import 'package:anchor/core/widgets/app_buttons.dart';
import 'package:anchor/core/widgets/app_scaffold.dart';
import 'package:anchor/core/widgets/bar_title.dart';
import 'package:anchor/core/widgets/cap_height_text.dart';
import 'package:anchor/core/widgets/form_page.dart';
import 'package:anchor/core/widgets/page_bar.dart';
import 'package:anchor/core/widgets/person_avatar.dart';
import 'package:anchor/features/auth/domain/user.dart';
import 'package:anchor/features/auth/presentation/auth_controller.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/notes/presentation/note_folder.dart';
import 'package:anchor/features/notes/presentation/notes_controller.dart';
import 'package:anchor/features/notes/presentation/notes_list_screen.dart';
import 'package:anchor/features/notes/presentation/notes_view_options.dart';
import 'package:anchor/features/notes/presentation/widgets/list_title.dart';
import 'package:anchor/features/notes/presentation/widgets/note_bar.dart';
import 'package:anchor/features/notes/presentation/widgets/note_surface.dart';
import 'package:anchor/features/reminders/data/reminder_permissions.dart';
import 'package:anchor/features/sync/data/sync_compatibility.dart';
import 'package:anchor/features/sync/data/sync_manager.dart';
import 'package:anchor/features/tags/domain/tag.dart';
import 'package:anchor/features/tags/presentation/tags_controller.dart';
import 'package:anchor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_500.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

final _english = lookupAppLocalizations(const Locale('en'));

void main() {
  setUpAll(() async {
    Future<ByteData> bytes(String file) async =>
        ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync());
    await (FontLoader(
      AppTypography.sans,
    )..addFont(bytes('DMSans-Variable.ttf'))).load();
    final serif = FontLoader(AppTypography.serif)
      ..addFont(bytes('PlayfairDisplay-SemiBold.ttf'))
      ..addFont(bytes('PlayfairDisplay-Bold.ttf'));
    await serif.load();
  });

  test('the cap heights are the bundled fonts\' own', () {
    double capHeightOf(String file) {
      final data = File('assets/fonts/$file').readAsBytesSync();
      final view = ByteData.sublistView(data);
      final offsets = <String, int>{};
      for (var i = 0; i < view.getUint16(4); i++) {
        final record = 12 + 16 * i;
        offsets[String.fromCharCodes(data.sublist(record, record + 4))] = view
            .getUint32(record + 8);
      }
      final unitsPerEm = view.getUint16(offsets['head']! + 18);
      return view.getInt16(offsets['OS/2']! + 88) / unitsPerEm;
    }

    expect(
      AppTypography.capHeightOf(AppTypography.sans),
      capHeightOf('DMSans-Variable.ttf'),
    );
    expect(
      AppTypography.capHeightOf(AppTypography.serif),
      capHeightOf('PlayfairDisplay-Bold.ttf'),
    );
    expect(
      AppTypography.capHeightOf(AppTypography.mono),
      capHeightOf('JetBrainsMono-Regular.ttf'),
    );
  });

  for (final density in DisplayDensity.values) {
    group(density.labelIn(_english), () {
      testWidgets('the notes list in every state', (tester) async {
        final probe = _Probe(tester, density);
        await probe.pumpList();
        probe.listBar('notes');
        expect(find.byType(BarTitleLine), findsNothing);
        expect(find.byType(PersonAvatar), findsNothing);

        probe.scrollTo(150);
        await tester.pumpAndSettle();
        expect(probe.offset, 150);
        probe.listBar('notes, scrolled');

        probe.scrollTo(0);
        probe.container
            .read(selectedTagFilterProvider.notifier)
            .select('travel');
        await tester.pumpAndSettle();
        probe.listBar('a tag');
        expect(find.byType(BarTitleLine), findsNothing);
        expect(find.byIcon(LucideIcons.x), findsNothing);
        probe.scrollTo(150);
        await tester.pumpAndSettle();
        expect(probe.offset, 150);
        probe.listBar('a tag, scrolled');

        probe.scrollTo(0);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(probe.container.read(selectedTagFilterProvider), isNull);
        probe.container
            .read(noteFolderProvider.notifier)
            .go(NoteFolder.archive);
        await tester.pumpAndSettle();
        probe.listBar('archive');
        expect(find.text('Hidden from Notes'), findsOneWidget);

        probe.container.read(noteFolderProvider.notifier).go(NoteFolder.trash);
        await tester.pumpAndSettle();
        probe.listBar('trash');
        expect(find.text('Deleted after 30 days'), findsOneWidget);

        probe.container.read(noteFolderProvider.notifier).go(NoteFolder.notes);
        probe.container.read(selectionModeProvider.notifier).setEnabled(true);
        probe.container.read(selectedNoteIdsProvider.notifier).add('n1');
        await tester.pumpAndSettle();
        probe.listBar('picking');
        expect(find.text('1 selected'), findsOneWidget);

        probe.container.read(selectionModeProvider.notifier).setEnabled(false);
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Notes, open menu').first);
        await tester.pumpAndSettle();
        probe.drawer();

        probe.expectAligned();
      }, variant: _platforms);

      testWidgets('the notes list offline', (tester) async {
        final probe = _Probe(tester, density);
        await probe.pumpList(isOnline: false);
        probe.listBar('offline');
        expect(
          find.text('Offline · changes are saved on this phone'),
          findsOne,
        );
        probe.expectAligned();
      }, variant: _platforms);

      testWidgets('pages after Back', (tester) async {
        final probe = _Probe(tester, density);
        await probe.pumpPage(
          (_) => const AppScaffold(
            title: 'Settings',
            background: PageBackground.gradient,
            slivers: [],
          ),
        );
        probe.pageBar('settings', 'Settings');

        await probe.pumpPage(
          (_) => const FormPage(title: 'Profile', children: []),
        );
        probe.pageBar('profile', 'Profile');

        await probe.pumpPage(
          (_) => AppScaffold(
            title: 'Logs',
            slivers: const [],
            actions: [
              BarButton(
                icon: LucideIcons.ellipsis,
                label: 'More',
                onPressed: () {},
              ),
            ],
          ),
        );
        probe.pageBar('logs', 'Logs');

        await probe.pumpPage(
          (_) => AppScaffold(
            title: 'Version history',
            background: PageBackground.gradient,
            slivers: const [],
            titleLine: BarTitleLine(
              'Lisbon trip',
              leading: Container(
                key: const Key('swatch'),
                width: 12,
                height: 12,
                color: Colors.teal,
              ),
            ),
          ),
        );
        probe.pageBar(
          'version history',
          'Version history',
          line: 'Lisbon trip',
        );

        await probe.pumpPage(
          (context) => Stack(
            children: [
              PageBar(
                leading: const PageBackButton(),
                title: BarTitle(
                  'Yesterday at 9:41 PM',
                  style: AppTypography.navTitle.tabular,
                  line: const BarTitleLine('You · Before a restore'),
                ),
              ),
            ],
          ),
        );
        probe.pageBar(
          'a version',
          'Yesterday at 9:41 PM',
          line: 'You · Before a restore',
        );

        await probe.pumpPage(
          (context) => Stack(
            children: [
              NoteBar(
                appearance: NoteAppearance.of(context, null),
                scrollOffset: ScrollOffset(ScrollController()),
                reminder: null,
                isUnsynced: true,
                isTrashed: false,
                isReadOnly: false,
                onBack: () {},
                onHistory: () {},
                onBackground: () {},
                onReminder: () {},
                onMore: () {},
              ),
            ],
          ),
        );
        probe.pageBar('editor', null, words: 'On this phone');

        await probe.pumpPage(
          (context) => Stack(
            children: [
              PageBar(
                isTitleCentered: true,
                leading: BarButton(
                  icon: LucideIcons.x,
                  label: 'Close',
                  onPressed: () {},
                ),
                title: CapHeightText(
                  '2 of 5',
                  style: AppTypography.secondary.tabular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
        probe.pageBar('picture viewer', '2 of 5');

        probe.expectAligned();
      }, variant: _platforms);

      testWidgets('a sheet head and its Done', (tester) async {
        final probe = _Probe(tester, density);
        await probe.pumpPage(
          (_) => const Material(
            child: Align(
              alignment: Alignment.topCenter,
              child: SheetHeader(title: 'Reminder', showDone: true),
            ),
          ),
        );
        final title = probe.caps(find.text('Reminder'));
        probe.near('sheet Done', probe.caps(find.text('Done')).mid, title.mid);
        probe.expectAligned();
        expect(
          tester.getSize(find.byType(AppButton)).height,
          greaterThanOrEqualTo(44),
        );
      }, variant: _platforms);
    });
  }
}

final _platforms = TargetPlatformVariant(const {
  TargetPlatform.iOS,
  TargetPlatform.android,
});

const _top = 59.0;

class _Probe {
  _Probe(this.tester, this.density);

  final WidgetTester tester;
  final DisplayDensity density;
  final List<String> misses = [];

  bool _isTall = false;

  double get _bar =>
      (density == DisplayDensity.compact ? 44 : 52) + (_isTall ? 8 : 0);
  double get middle => _top + _bar / 2;

  void _setView() {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: _top * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
  }

  Future<void> pumpList({bool isOnline = true}) async {
    _setView();
    const tags = [
      Tag(id: 'travel', name: 'travel', color: 'blue'),
      Tag(id: 'work', name: 'work', color: 'red'),
    ];
    final notes = [
      for (var i = 1; i <= 12; i++)
        Note(
          id: 'n$i',
          title: 'Note $i',
          content:
              '{"ops":[{"insert":"${List.filled(12, 'Some words in a line').join('\\n')}\\n"}]}',
          tagIds: i % 4 == 0 ? const ['work'] : const ['travel'],
        ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverUrlProvider.overrideWithValue('https://example.test'),
          authControllerProvider.overrideWith(_SignedIn.new),
          notesProvider.overrideWith((ref) {
            final tag = ref.watch(selectedTagFilterProvider);
            return Stream.value([
              for (final note in notes)
                if (tag == null || note.tagIds.contains(tag)) note,
            ]);
          }),
          archivedNotesProvider.overrideWith((ref) => Stream.value([])),
          trashedNotesProvider.overrideWith((ref) => Stream.value([])),
          allActiveNotesProvider.overrideWith((ref) => Stream.value(notes)),
          tagsControllerProvider.overrideWith(() => _Tags(tags)),
          notesViewOptionsProvider.overrideWith(_ViewOptions.new),
          reminderPermissionsControllerProvider.overrideWith(_Permissions.new),
          syncManagerProvider.overrideWith(_Sync.new),
          syncCompatibilityProvider.overrideWith(
            (ref) async => SyncCompatibility.ok,
          ),
          isOnlineProvider.overrideWith((ref) => isOnline),
        ],
        child: MaterialApp(
          theme: AppTheme.light(density),
          home: const NotesListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpPage(WidgetBuilder page) async {
    _setView();
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          serverUrlProvider.overrideWithValue('https://example.test'),
          isOnlineProvider.overrideWith((ref) => true),
        ],
        child: MaterialApp(
          theme: AppTheme.light(density),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: page)),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  ProviderContainer get container =>
      ProviderScope.containerOf(tester.element(find.byType(NotesListScreen)));

  double get offset => tester
      .widget<CustomScrollView>(find.byType(CustomScrollView).first)
      .controller!
      .offset;

  void scrollTo(double offset) {
    tester
        .widget<CustomScrollView>(find.byType(CustomScrollView).first)
        .controller!
        .jumpTo(offset);
  }

  ({double top, double base, double mid}) caps(Finder text) {
    final paragraph = tester.renderObject<RenderParagraph>(text);
    final style = paragraph.text.style!;
    final cap =
        AppTypography.capHeightOf(style.fontFamily) *
        paragraph.textScaler.scale(style.fontSize!);
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      strutStyle: paragraph.strutStyle,
      textHeightBehavior: paragraph.textHeightBehavior,
      maxLines: paragraph.maxLines,
    )..layout(maxWidth: paragraph.size.width);
    final base = paragraph
        .localToGlobal(
          Offset(
            0,
            painter.computeDistanceToActualBaseline(TextBaseline.alphabetic),
          ),
        )
        .dy;
    painter.dispose();
    return (top: base - cap, base: base, mid: base - cap / 2);
  }

  double mid(Finder finder) => tester.getCenter(finder).dy;

  void near(String what, double actual, double expected) {
    if ((actual - expected).abs() > 0.5) {
      misses.add('$what: ${(actual - expected).toStringAsFixed(2)}');
    }
  }

  Finder _in(Type type, Finder matching) =>
      find.descendant(of: find.byType(type), matching: matching);

  void listBar(String where) {
    final hasLarge = find.byType(ListLargeTitle).evaluate().isNotEmpty;
    final isScrolled = offset > PageBar.titleTransitionDistance;
    _isTall = !isScrolled;
    if (hasLarge && !isScrolled) {
      final name = caps(_in(ListLargeTitle, find.byType(Text)).first);
      final lineText = _in(BarTitleLine, find.byType(Text));
      final line = lineText.evaluate().isEmpty ? null : caps(lineText);
      near('$where: chevron', mid(find.byType(BarTitleChevron)), name.mid);
      final hash = _in(ListLargeTitle, find.byIcon(LucideIcons600.hash));
      if (hash.evaluate().isNotEmpty) {
        near('$where: #', mid(hash), name.mid);
      }
      final offline = _in(BarTitleLine, find.byIcon(LucideIcons.cloudOff));
      if (line != null && offline.evaluate().isNotEmpty) {
        near('$where: line icon', mid(offline), line.mid);
      }
      if (line == null) {
        near('$where: title', name.mid, middle);
      } else {
        near('$where: block', (name.top + line.base) / 2, middle);
      }
      near(
        '$where: title capitals from the top',
        name.top - _top,
        (_bar - 0.708 * 28 - (line == null ? 0 : 8 + 0.7 * 12)) / 2,
      );
    } else {
      final small = find
          .descendant(of: find.byType(PageBar), matching: find.byType(BarTitle))
          .first;
      final title = caps(
        find.descendant(of: small, matching: find.byType(Text)).first,
      );
      for (final icon in [LucideIcons600.hash, LucideIcons500.chevronDown]) {
        final found = find.descendant(of: small, matching: find.byIcon(icon));
        if (found.evaluate().isEmpty) continue;
        near('$where: bar title $icon', mid(found), title.mid);
      }
      near('$where: bar title', title.mid, middle);
    }
    _barButtons(where);
    _isTall = false;
  }

  void _barButtons(String where) {
    Finder inBar(Finder finder) =>
        find.descendant(of: find.byType(PageBar), matching: finder);
    for (final icon in [
      LucideIcons.x,
      LucideIcons.layoutGrid,
      LucideIcons.ellipsis,
      LucideIcons.chevronLeft,
      LucideIcons.arrowLeft,
      LucideIcons.palette,
      LucideIcons.bell,
    ]) {
      final found = inBar(find.byIcon(icon));
      for (final element in found.evaluate()) {
        near(
          '$where: $icon',
          tester.getCenter(find.byElementPredicate((e) => e == element)).dy,
          middle,
        );
      }
    }
    for (final words in ['Select all', 'Deselect all']) {
      final found = inBar(find.text(words));
      if (found.evaluate().isNotEmpty) {
        near('$where: $words', caps(found).mid, middle);
      }
    }
  }

  void pageBar(String where, String? title, {String? line, String? words}) {
    if (title != null) {
      final titleCaps = caps(
        find.descendant(of: find.byType(PageBar), matching: find.text(title)),
      );
      if (line == null) {
        near('$where: title', titleCaps.mid, middle);
      } else {
        final lineCaps = caps(find.text(line));
        near('$where: block', (titleCaps.top + lineCaps.base) / 2, middle);
        final swatch = find.byKey(const Key('swatch'));
        if (swatch.evaluate().isNotEmpty) {
          near('$where: swatch', mid(swatch), lineCaps.mid);
        }
      }
    }
    if (words != null) {
      near('$where: $words', caps(find.text(words)).mid, middle);
    }
    _barButtons(where);
  }

  void drawer() {
    near(
      'drawer brand',
      mid(find.byType(AnchorLogo)),
      caps(find.text('Anchor')).mid,
    );
    final plus = find.widgetWithIcon(BarButton, LucideIcons.plus);
    near(
      'drawer tags +',
      mid(find.byIcon(LucideIcons.plus)),
      caps(find.text('TAGS')).mid,
    );
    expect(tester.getSize(plus), const Size.square(44));
  }

  void expectAligned() => expect(misses, isEmpty, reason: misses.join('\n'));
}

class _SignedIn extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: 'u1', email: 'oliver@example.com', name: 'Oliver Grant');
}

class _Tags extends TagsController {
  _Tags(this.tags);

  final List<Tag> tags;

  @override
  Stream<List<Tag>> build() => Stream.value(tags);
}

class _ViewOptions extends NotesViewOptionsNotifier {
  @override
  Future<NotesViewOptions> build() async => const NotesViewOptions();
}

class _Permissions extends ReminderPermissionsController {
  @override
  Future<ReminderPermissions> build() async => const ReminderPermissions(
    canNotify: true,
    canBeExact: true,
    needsExactAlarmPermission: false,
  );
}

class _Sync extends SyncManager {
  @override
  bool build() => false;
}
