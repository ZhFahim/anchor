import 'dart:convert';

import '../../features/notes/domain/note.dart';
import '../router/app_routes.dart';
import '../widgets/quill_preview.dart';

/// SharedPreferences key the Android widget reads its data from.
/// Must match `WIDGET_NOTES_KEY` in `NotesWidgetService.kt`.
const homeWidgetNotesKey = 'widget_notes';

const _widgetUriScheme = 'anchorwidget';

/// Maps a widget launch URI to a router location, or null to ignore it.
///
/// Note URIs map to the top-level widget routes, where the editor is the only
/// page on the stack: back leaves the app instead of revealing the notes list.
String? homeWidgetRouteForUri(Uri? uri) {
  if (uri == null || uri.scheme != _widgetUriScheme) return null;
  if (uri.host == 'note' && uri.pathSegments.isNotEmpty) {
    final target = uri.pathSegments.first;
    return target == 'new' ? AppRoutes.widgetNoteNew : '/widget/note/$target';
  }
  return AppRoutes.home;
}

const homeWidgetMaxNotes = 20;

const _maxSnippetChars = 160;

/// Serializes notes into the JSON payload rendered by the home-screen widget.
///
/// Notes are expected in display order (pinned first, then most recent).
/// Titles are passed through as stored; the native side applies the
/// 'Untitled' display fallback.
String buildHomeWidgetPayload(List<Note> notes, {required bool loggedIn}) {
  final items = notes.take(homeWidgetMaxNotes).map((note) {
    return {
      'id': note.id,
      'title': note.title.trim(),
      'snippet': _truncate(extractPlainTextFromQuillContent(note.content)),
      'pinned': note.isPinned,
    };
  }).toList();

  return jsonEncode({'loggedIn': loggedIn, 'notes': items});
}

String _truncate(String text) {
  if (text.length <= _maxSnippetChars) return text;
  var end = _maxSnippetChars;
  // Don't split a surrogate pair.
  if ((text.codeUnitAt(end - 1) & 0xFC00) == 0xD800) end--;
  return text.substring(0, end);
}
