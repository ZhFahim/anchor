import 'dart:convert';

import 'package:anchor/core/theme/tokens/anchor_tokens.dart';
import 'package:anchor/features/home_widget/data/home_widget_payload.dart';
import 'package:anchor/features/notes/domain/checklist_task.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:flutter_test/flutter_test.dart';

Note _note({
  String id = 'n1',
  String title = 'Title',
  String? content,
  bool isPinned = false,
  String? background,
}) {
  return Note(
    id: id,
    title: title,
    content: content,
    isPinned: isPinned,
    background: background,
  );
}

Map<String, int> _colors(String palette) {
  final light = AnchorColors.light.notes[palette]!;
  final dark = AnchorColors.dark.notes[palette]!;
  return {
    'fill': light.bg.toARGB32(),
    'edge': light.border.toARGB32(),
    'fillDark': dark.bg.toARGB32(),
    'edgeDark': dark.border.toARGB32(),
  };
}

String _quill(String text) => jsonEncode({
  'ops': [
    {'insert': '$text\n'},
  ],
});

Map<String, dynamic> _decode(String payload) =>
    jsonDecode(payload) as Map<String, dynamic>;

void main() {
  group('buildHomeWidgetPayload', () {
    test(
      'checklist snippets hide completed tasks without changing regular notes',
      () {
        final content = writeChecklist([
          const ChecklistTask(text: 'Milk'),
          const ChecklistTask(text: 'Bread', done: true),
        ]);
        final payload = buildHomeWidgetPayload([
          Note(
            id: 'tasks',
            title: '',
            content: content,
            noteType: NoteType.checklist,
          ),
          Note(id: 'regular', title: '', content: content),
        ], loggedIn: true);
        final notes = _decode(payload)['notes'] as List;
        expect(notes[0]['snippet'], 'Milk');
        expect(notes[1]['snippet'], 'Milk\nBread');
      },
    );
    test(
      'serializes notes with id, title, snippet, pinned flag and colors',
      () {
        final payload = buildHomeWidgetPayload([
          _note(
            id: 'a',
            title: 'Groceries',
            content: _quill('Milk'),
            isPinned: true,
          ),
          _note(id: 'b', title: 'Ideas'),
        ], loggedIn: true);

        final decoded = _decode(payload);
        expect(decoded['loggedIn'], isTrue);
        final notes = decoded['notes'] as List;
        expect(notes, hasLength(2));
        expect(notes[0], {
          'id': 'a',
          'title': 'Groceries',
          'snippet': 'Milk',
          'pinned': true,
          ..._colors('none'),
        });
        expect(notes[1], {
          'id': 'b',
          'title': 'Ideas',
          'snippet': '',
          'pinned': false,
          ..._colors('none'),
        });
      },
    );

    test('colors a note by its background in both themes', () {
      final payload = buildHomeWidgetPayload([
        _note(id: 'yellow', background: 'color_yellow'),
        _note(id: 'grid', background: 'pattern_grid'),
        _note(id: 'unknown', background: 'color_nope'),
      ], loggedIn: true);

      final notes = _decode(payload)['notes'] as List;
      expect(notes[0], containsPair('fill', _colors('yellow')['fill']));
      expect(notes[0], containsPair('edgeDark', _colors('yellow')['edgeDark']));
      expect(notes[1], containsPair('fill', _colors('yellow')['fill']));
      expect(notes[2], containsPair('fill', _colors('none')['fill']));
    });

    test('preserves the given note order', () {
      final payload = buildHomeWidgetPayload([
        _note(id: 'pinned', isPinned: true),
        _note(id: 'recent'),
        _note(id: 'older'),
      ], loggedIn: true);

      final ids = (_decode(payload)['notes'] as List).map((n) => n['id']);
      expect(ids, ['pinned', 'recent', 'older']);
    });

    test('passes titles through as stored', () {
      final payload = buildHomeWidgetPayload([
        _note(title: 'Groceries '),
      ], loggedIn: true);

      expect((_decode(payload)['notes'] as List).single['title'], 'Groceries ');
    });

    test('keeps blank titles empty so the native side hides them', () {
      final payload = buildHomeWidgetPayload([
        _note(title: '   '),
      ], loggedIn: true);

      expect((_decode(payload)['notes'] as List).single['title'], '');
    });

    test('turns multi-line quill content into a newline-joined snippet', () {
      final content = jsonEncode({
        'ops': [
          {'insert': 'line one\n'},
          {'insert': 'line two\n'},
        ],
      });
      final payload = buildHomeWidgetPayload([
        _note(content: content),
      ], loggedIn: true);

      expect(
        (_decode(payload)['notes'] as List).single['snippet'],
        'line one\nline two',
      );
    });

    test('produces an empty snippet for no content', () {
      final payload = buildHomeWidgetPayload([
        _note(content: null),
      ], loggedIn: true);

      expect((_decode(payload)['notes'] as List).single['snippet'], '');
    });

    test('reads content that is not JSON as plain text', () {
      final payload = buildHomeWidgetPayload([
        _note(content: 'not json'),
      ], loggedIn: true);

      expect((_decode(payload)['notes'] as List).single['snippet'], 'not json');
    });

    test('truncates long snippets', () {
      final payload = buildHomeWidgetPayload([
        _note(content: _quill('x' * 500)),
      ], loggedIn: true);

      final snippet =
          (_decode(payload)['notes'] as List).single['snippet'] as String;
      expect(snippet.length, 160);
    });

    test('does not split a surrogate pair when truncating', () {
      final text = '${'x' * 159}😀';
      final payload = buildHomeWidgetPayload([
        _note(content: _quill(text)),
      ], loggedIn: true);

      final snippet =
          (_decode(payload)['notes'] as List).single['snippet'] as String;
      expect(snippet, 'x' * 159);
    });

    test('caps the payload at $homeWidgetMaxNotes notes', () {
      final notes = List.generate(30, (i) => _note(id: 'n$i'));
      final payload = buildHomeWidgetPayload(notes, loggedIn: true);

      expect(_decode(payload)['notes'] as List, hasLength(homeWidgetMaxNotes));
    });

    test('marks logged-out payloads', () {
      final decoded = _decode(
        buildHomeWidgetPayload(const [], loggedIn: false),
      );
      expect(decoded['loggedIn'], isFalse);
      expect(decoded['notes'], isEmpty);
    });
  });

  group('homeWidgetRouteForUri', () {
    test('maps widget URIs to router locations', () {
      expect(
        homeWidgetRouteForUri(Uri.parse('anchorwidget://note/new')),
        '/widget/note/new',
      );
      expect(
        homeWidgetRouteForUri(Uri.parse('anchorwidget://note/abc-123')),
        '/widget/note/abc-123',
      );
      expect(homeWidgetRouteForUri(Uri.parse('anchorwidget://open')), '/');
    });

    test('ignores null and foreign-scheme URIs', () {
      expect(homeWidgetRouteForUri(null), isNull);
      expect(homeWidgetRouteForUri(Uri.parse('anchor://callback')), isNull);
      expect(homeWidgetRouteForUri(Uri.parse('https://note/new')), isNull);
    });
  });
}
