import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../core/ids.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../data/repository/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_blocks.dart';
import '../domain/note_share.dart';
import '../domain/user_summary.dart';

/// Each member is null while there is no editor.
abstract interface class NoteEditorContent {
  String? get content;

  String? get plainText;

  /// Whether the editor's text matches [content], however it was written.
  bool? matches(String? content);
}

class NoteEditorController extends ChangeNotifier {
  NoteEditorController({
    required NotesRepository notes,
    required this.sharesOf,
    required this.editor,
    required this.newNoteTagId,
    required this.onNoteDeleted,
    Note? note,
    String? noteId,
    this.newNoteType = NoteType.note,
  }) : _notes = notes,
       _openedId = noteId {
    title.addListener(_titleChanged);
    final watchedId = note?.id ?? noteId;
    if (watchedId != null) _watch(watchedId);
    if (note != null) {
      _loadNote(note);
      _isNew = false;
    } else if (noteId != null) {
      _isNew = false;
      unawaited(_load(noteId));
    } else {
      _isLoaded = true;
    }
  }

  final NotesRepository _notes;
  final NoteType newNoteType;
  NoteType get noteType => _note?.noteType ?? newNoteType;

  final Future<List<NoteShare>> Function(String noteId) sharesOf;

  final NoteEditorContent editor;

  final String? Function() newNoteTagId;

  /// Called once the note is permanently deleted elsewhere, or a share to it
  /// is taken away.
  final VoidCallback onNoteDeleted;

  final String? _openedId;

  final TextEditingController title = TextEditingController();

  final ValueNotifier<int> words = ValueNotifier(0);

  Note? _note;
  String? _initialContent;
  int _contentVersion = 0;
  String? _background;
  // The title, text and background as last loaded, saved or taken from
  // elsewhere; a save writes only the ones changed since.
  String _savedTitle = '';
  String? _savedContent;
  String? _savedBackground;
  String? _contentBeforeReload;
  List<UserSummary>? _sharedWith;
  bool _isNew = true;
  bool _isLoaded = false;
  bool _isDeleted = false;
  bool _isDisposed = false;
  bool _hasFlushed = false;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  String _lastTitleText = '';
  Timer? _autoSaveTimer;
  Timer? _wordsTimer;
  StreamSubscription<Note?>? _noteWatch;

  /// Null for a new note not saved yet.
  Note? get note => _note;

  String? get initialContent => _initialContent;

  /// Goes up each time the stored text replaces the editor's.
  int get contentVersion => _contentVersion;

  String? get background => _background;

  /// The people the note is shared with, once read from the server.
  List<UserSummary>? get sharedWith => _sharedWith;

  String? get noteId => _openedId ?? _note?.id;

  bool get isNew => _isNew;

  bool get isBlankNew =>
      _isNew &&
      storedTitleOf(title.text).isEmpty &&
      (editor.plainText ?? '').isEmpty &&
      _background == null;
  bool get isLoaded => _isLoaded;
  bool get isActive => _note?.isActive ?? true;
  bool get isTrashed => _note?.isTrashed ?? false;
  bool get isViewOnly => _note?.permission == NotePermission.viewer;
  bool get isReadOnly => !isActive || isViewOnly;

  @override
  void dispose() {
    _isDisposed = true;
    _autoSaveTimer?.cancel();
    _wordsTimer?.cancel();
    unawaited(_noteWatch?.cancel());
    title.removeListener(_titleChanged);
    title.dispose();
    words.dispose();
    super.dispose();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  void _loadNote(Note note) {
    _note = note;
    _lastTitleText = note.title;
    title.text = note.title;
    _initialContent = note.content;
    _background = note.background;
    _savedTitle = note.title;
    _savedContent = note.content;
    _savedBackground = note.background;
    _isLoaded = true;
    words.value = wordCount(note.content);
    unawaited(_loadSharedWith(note));
  }

  Future<void> _load(String id) async {
    final note = await _notes.getNote(id);
    if (note == null || _isDisposed) return;
    _loadNote(note);
    _notify();
  }

  Future<void> _loadSharedWith(Note note) async {
    if (!note.isOwner || !note.hasShares) {
      _sharedWith = null;
      return;
    }
    try {
      final shares = await sharesOf(note.id);
      _sharedWith = [for (final s in shares) s.sharedWithUser];
      _notify();
    } catch (_) {
      // Offline: the meta line shows a count.
    }
  }

  void _watch(String id) {
    unawaited(_noteWatch?.cancel());
    _noteWatch = _notes.watchNote(id).listen(_storedNoteChanged);
  }

  /// Never replaces what the draft changed and hasn't saved yet.
  void _storedNoteChanged(Note? note) {
    if (_isDisposed) return;
    if (note == null) return _handleNoteDeleted();
    final shouldReplaceDraft =
        !_hasUnsavedChanges && !_isSaving && !_draftMatches(note);
    final isShareChanged = !setEquals(
      {...?note.shareIds},
      {...?_note?.shareIds},
    );
    _note = note;
    _isLoaded = true;
    if (isShareChanged) unawaited(_loadSharedWith(note));
    if (shouldReplaceDraft) {
      _showTitle(note.title);
      _initialContent = note.content;
      _contentVersion++;
      _background = note.background;
      words.value = wordCount(note.content);
    } else {
      // Takes what changed elsewhere, where the draft hasn't changed it.
      if (storedTitleOf(title.text) == storedTitleOf(_savedTitle)) {
        _showTitle(note.title);
      }
      if (_editorMatches(_savedContent) && !_editorMatches(note.content)) {
        _contentBeforeReload = _savedContent;
        _initialContent = note.content;
        _contentVersion++;
        words.value = wordCount(note.content);
      }
      if (_background == _savedBackground) _background = note.background;
    }
    _savedTitle = note.title;
    _savedContent = note.content;
    _savedBackground = note.background;
    _notify();
  }

  void _showTitle(String text) {
    if (title.text == text) return;
    _lastTitleText = text;
    title.text = text;
  }

  bool _draftMatches(Note note) =>
      storedTitleOf(note.title) == storedTitleOf(title.text) &&
      _editorMatches(note.content) &&
      note.background == _background;

  bool _editorMatches(String? content) =>
      editor.matches(content) ?? (content ?? '') == (_initialContent ?? '');

  void _handleNoteDeleted() {
    if (_isNew || _isDeleted) return;
    _isDeleted = true;
    _autoSaveTimer?.cancel();
    onNoteDeleted();
  }

  /// Stops saving; call once the note is trashed or deleted here.
  void markDeleted() {
    _isDeleted = true;
    _autoSaveTimer?.cancel();
  }

  void _titleChanged() {
    if (title.text == _lastTitleText) return;
    _lastTitleText = title.text;
    contentChanged();
  }

  void contentChanged() {
    _hasUnsavedChanges = true;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
    _wordsTimer?.cancel();
    _wordsTimer = Timer(const Duration(milliseconds: 300), () {
      words.value = countWords(editor.plainText ?? '');
    });
  }

  void setBackground(String? id) {
    _background = id;
    _notify();
    contentChanged();
  }

  Future<void> _autoSave() async {
    if (!_hasUnsavedChanges) return;
    await _savePendingChanges();
  }

  Future<void> saveNow() {
    _autoSaveTimer?.cancel();
    return _savePendingChanges();
  }

  void saveIfChanged() {
    if (_hasUnsavedChanges) unawaited(_autoSave());
  }

  Future<void> _savePendingChanges() async {
    // Cleared before the await: edits made during it stay flagged.
    _hasUnsavedChanges = false;
    _isSaving = true;
    try {
      await _save();
    } finally {
      _isSaving = false;
    }
  }

  /// Must run while the editor is still mounted.
  void flushOnLeave() {
    if (_hasFlushed) return;
    _hasFlushed = true;
    _autoSaveTimer?.cancel();
    if (_isDeleted || !_hasUnsavedChanges && !_isNew) return;
    unawaited(_savePendingChanges());
  }

  void reopen() => _hasFlushed = false;

  Future<void> discardIfBlank() async {
    final note = _note;
    if (_isNew || note == null || _hasUnsavedChanges) return;
    final stored = await _notes.getNote(note.id);
    final isBlank =
        stored != null &&
        stored.tagIds.isEmpty &&
        storedTitleOf(title.text).isEmpty &&
        (editor.plainText ?? '').isEmpty &&
        _background == null;
    if (!isBlank || _isDisposed) return;
    await _noteWatch?.cancel();
    _noteWatch = null;
    await _notes.deleteForever([note.id]);
    _note = null;
    _isNew = true;
    _notify();
  }

  Future<String> createNote() async {
    final note = Note(
      id: newId(),
      title: storedTitleOf(title.text),
      noteType: noteType,
      content: editor.content ?? '',
      tagIds: [?newNoteTagId()],
      background: _background,
      isSynced: false,
    );
    AppLogger.instance.info(
      LogTags.noteEdit,
      'createNote: id=${note.id} title.len=${note.title.length}',
    );
    _savedTitle = note.title;
    _savedContent = note.content;
    _savedBackground = note.background;
    await _notes.createNote(note);
    if (!_isDisposed) {
      _isNew = false;
      _note = note;
      _watch(note.id);
      _notify();
    }
    return note.id;
  }

  Future<void> _save() async {
    if (!isActive || !(_note?.canEdit ?? true)) return;
    if (_isNew) {
      if (!isBlankNew) await createNote();
      return;
    }
    final storedTitle = storedTitleOf(title.text);
    final content = editor.content ?? _initialContent ?? '';
    final existing = _note;
    if (existing == null) return;
    final isTitleChanged =
        storedTitle != storedTitleOf(_savedTitle) &&
        storedTitle != storedTitleOf(existing.title);
    final isContentChanged =
        !(editor.matches(_savedContent) ?? true) &&
        !(editor.matches(existing.content) ?? true) &&
        (_contentBeforeReload == null ||
            !(editor.matches(_contentBeforeReload) ?? false));
    final isBackgroundChanged =
        _background != _savedBackground && _background != existing.background;
    if (!isTitleChanged && !isContentChanged && !isBackgroundChanged) return;
    final updated = existing.copyWith(
      title: isTitleChanged ? storedTitle : existing.title,
      content: isContentChanged ? content : existing.content,
      background: isBackgroundChanged ? _background : existing.background,
      isSynced: false,
    );
    _savedTitle = updated.title;
    _savedContent = updated.content;
    _savedBackground = updated.background;
    _contentBeforeReload = null;
    await _notes.updateNote(updated);
    if (!_isDisposed) {
      _note = updated;
      _notify();
    }
  }
}
