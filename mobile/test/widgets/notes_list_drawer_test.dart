import 'package:anchor/core/network/connectivity_provider.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/storage/preferences_repository.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/core/widgets/anchor_sheet.dart';
import 'package:anchor/features/auth/domain/user.dart';
import 'package:anchor/features/auth/presentation/auth_controller.dart';
import 'package:anchor/features/notes/data/repository/notes_repository.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:anchor/features/notes/presentation/notes_controller.dart';
import 'package:anchor/features/notes/presentation/notes_list_screen.dart';
import 'package:anchor/features/notes/presentation/notes_view_options.dart';
import 'package:anchor/features/notes/presentation/widgets/app_drawer.dart';
import 'package:anchor/features/reminders/data/reminder_permissions.dart';
import 'package:anchor/features/sync/data/sync_compatibility.dart';
import 'package:anchor/features/sync/data/sync_manager.dart';
import 'package:anchor/features/tags/domain/tag.dart';
import 'package:anchor/features/tags/presentation/tags_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotes extends Mock implements NotesRepository {}

class _MockPreferences extends Mock implements PreferencesRepository {}

void main() {
  final trip = Note(
    id: 'n1',
    title: 'Lisbon trip',
    content: '{"ops":[{"insert":"Tram 28\\n"}]}',
    updatedAt: DateTime.utc(2026, 10, 2),
  );

  late GoRouter router;
  late _MockPreferences preferences;

  setUp(() {
    preferences = _MockPreferences();
    when(preferences.getCustomHeaders).thenAnswer((_) async => const []);
  });

  Future<void> pumpList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const NotesListScreen(),
          routes: [
            GoRoute(
              path: 'settings',
              builder: (_, _) => const Scaffold(body: Text('Settings page')),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverUrlProvider.overrideWithValue('https://example.test'),
          authControllerProvider.overrideWith(_SignedIn.new),
          notesRepositoryProvider.overrideWithValue(_MockNotes()),
          preferencesRepositoryProvider.overrideWithValue(preferences),
          notesProvider.overrideWith((ref) => Stream.value([trip])),
          archivedNotesProvider.overrideWith((ref) => Stream.value([])),
          trashedNotesProvider.overrideWith((ref) => Stream.value([])),
          allActiveNotesProvider.overrideWith((ref) => Stream.value([trip])),
          tagsControllerProvider.overrideWith(_Tags.new),
          notesViewOptionsProvider.overrideWith(_ViewOptions.new),
          reminderPermissionsControllerProvider.overrideWith(_Permissions.new),
          syncManagerProvider.overrideWith(_Sync.new),
          syncCompatibilityProvider.overrideWith(
            (ref) async => SyncCompatibility.ok,
          ),
          isOnlineProvider.overrideWith((ref) => true),
          firstDownloadProvider.overrideWithValue(FirstDownload.done),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> openDrawer(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(RegExp(r', open menu$')));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(AppDrawer)).dx, 0);
  }

  testWidgets('picking a folder closes the drawer at once', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpList(tester);
    await openDrawer(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(AppDrawer),
        matching: find.text('Archive'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));

    expect(tester.getTopLeft(find.byType(AppDrawer)).dx, lessThan(-8));
    await tester.pumpAndSettle();
    expect(find.byType(AppDrawer), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'Settings opens at once over the still drawer, which is shut on return',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpList(tester);
      await openDrawer(tester);

      await tester.tap(find.bySemanticsLabel(RegExp(r', Settings$')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));

      expect(find.text('Settings page'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(AppDrawer)).dx,
        tester.getTopLeft(find.byType(NotesListScreen)).dx,
      );
      expect(
        tester
            .widget<SnapshotWidget>(
              find
                  .ancestor(
                    of: find.byType(AppDrawer),
                    matching: find.byType(SnapshotWidget),
                  )
                  .first,
            )
            .controller
            .allowSnapshotting,
        isTrue,
      );

      await tester.pumpAndSettle();
      router.pop();
      await tester.pump();

      expect(find.byType(AppDrawer), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Lisbon trip'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('a sheet opened from the drawer leaves the drawer open', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpList(tester);
    await openDrawer(tester);

    final context = tester.element(find.byType(AppDrawer));
    showAnchorSheet<void>(
      context,
      builder: (_) => const SizedBox(height: 200, child: Text('A sheet')),
    );
    await tester.pumpAndSettle();
    Navigator.of(context, rootNavigator: true).pop();
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byType(AppDrawer)).dx, 0);
    semantics.dispose();
  });
}

class _SignedIn extends AuthController {
  @override
  Future<User?> build() async =>
      const User(id: 'u1', email: 'oliver@example.com', name: 'Oliver Grant');
}

class _Tags extends TagsController {
  @override
  Stream<List<Tag>> build() => Stream.value(const []);
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
