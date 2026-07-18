import 'dart:convert';

import 'package:anchor/core/home_widget/home_widget_payload.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:flutter_test/flutter_test.dart';

Note _note({
  String id = 'n1',
  String title = 'Title',
  String? content,
  bool isPinned = false,
}) {
  return Note(id: id, title: title, content: content, isPinned: isPinned);
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
    test('serializes notes with id, title, snippet and pinned flag', () {
      final payload = buildHomeWidgetPayload([
        _note(id: 'a', title: 'Groceries', content: _quill('Milk'), isPinned: true),
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
      });
      expect(notes[1], {'id': 'b', 'title': 'Ideas', 'snippet': '', 'pinned': false});
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

    test('keeps blank titles empty so the native side applies the fallback', () {
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

    test('produces an empty snippet for null or invalid content', () {
      final payload = buildHomeWidgetPayload([
        _note(id: 'a', content: null),
        _note(id: 'b', content: 'not json'),
      ], loggedIn: true);

      final notes = _decode(payload)['notes'] as List;
      expect(notes[0]['snippet'], '');
      expect(notes[1]['snippet'], '');
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
      final decoded = _decode(buildHomeWidgetPayload(const [], loggedIn: false));
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
