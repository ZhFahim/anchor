import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/springs.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/note_blocks.dart';
import 'block_spacing.dart';
import 'checklist_drag_controller.dart';
import 'checklist_drag_overlay.dart';
import 'checklist_fold.dart';
import 'checklist_lines.dart';
import 'checklist_sorter.dart';
import 'document_lines.dart';
import 'editor_format.dart';
import 'editor_link.dart';
import 'editor_palette.dart';
import 'editor_styles.dart';
import 'highlight_underlay.dart';
import 'line_kind.dart';
import 'list_markers.dart';
import 'markdown_shortcuts.dart';
import 'note_search.dart';
import 'plain_insert_rule.dart';
import 'slash_hint.dart';

/// Doesn't scroll by itself; the note page scrolls it.
class RichTextEditor extends StatefulWidget {
  const RichTextEditor({
    super.key,
    this.initialContent,
    this.contentVersion = 0,
    this.onChanged,
    this.onEditingChanged,
    this.canEdit = true,
    required this.focusNode,
    this.sortChecklistItems = true,
    required this.scrollController,
    required this.palette,
    this.onLinkTap,
    this.bottomInset = 80, // off-scale: room under the text when not given
    this.onReadOnlyTap,
    this.onSelectionChanged,
    this.hasSlashHint = false,
    this.onBlankChanged,
    this.onBackspaceAtStart,
    this.isCheckedFolded = false,
    this.onCheckedFoldChanged,
    this.visibleArea,
    this.search = const NoteSearch.empty(),
  });

  final String? initialContent;

  /// A new value loads [initialContent] again, even when its text is unchanged.
  final int contentVersion;

  /// Fires when the document changes, not when only the selection moves.
  final VoidCallback? onChanged;
  final ValueChanged<bool>? onEditingChanged;
  final bool canEdit;
  final FocusNode focusNode;
  final bool sortChecklistItems;
  final ScrollController scrollController;
  final EditorPalette palette;

  /// A tap or long-press on a link.
  final ValueChanged<EditorLink>? onLinkTap;

  final double bottomInset;

  /// What the note screen is searching for. Painted, never written.
  final NoteSearch search;

  final VoidCallback? onReadOnlyTap;

  final ValueChanged<TextSelection>? onSelectionChanged;

  final bool hasSlashHint;

  final ValueChanged<bool>? onBlankChanged;

  /// Gets the first line's words, already taken out of the note.
  final ValueChanged<String>? onBackspaceAtStart;

  final bool isCheckedFolded;

  final ValueChanged<bool>? onCheckedFoldChanged;

  /// In global coordinates; null falls back to the scroll view's edges.
  final Rect? Function()? visibleArea;

  @override
  State<RichTextEditor> createState() => RichTextEditorState();
}

class RichTextEditorState extends State<RichTextEditor>
    with TickerProviderStateMixin {
  late QuillController _controller;
  late final ChecklistSorter _sorter;
  late final ChecklistDragController _drag;
  StreamSubscription<DocChange>? _onChangedSub;
  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();
  final GlobalKey _stackKey = GlobalKey();
  final ValueNotifier<int> _paintTick = ValueNotifier(0);
  final ValueNotifier<String?> _slashQuery = ValueNotifier(null);

  int? _typedSlashOffset;
  late TextSelection _selection;
  bool _isEditing = false;
  bool _consumeEditorTapUp = false;
  bool _isApplying = false;
  late bool _isBlank;
  SlashHint? _slashHint;

  final Map<Line, Timer> _justCheckedTimers = {};
  final OverlayPortalController _ghost = OverlayPortalController();
  final ListMarkerCache _markers = ListMarkerCache();
  ListLines _lists = ListLines.empty;
  late bool _isFolded = widget.isCheckedFolded;
  UndoableEdit? _undoable;

  /// Quill keeps this much under the caret on its own.
  static const double _caretMargin = AnchorTokens.space8;

  late final AnimationController _caretScroll = AnimationController.unbounded(
    vsync: this,
  )..addListener(_followCaretScroll);
  double _caretScrollTarget = 0;

  QuillController get controller => _controller;

  /// Where [range]'s line should sit so the person can see it.
  ///
  /// Returns null when the line is already inside the viewport. [top] and
  /// [bottom] are relative to the viewport's top edge.
  @visibleForTesting
  static double? scrollTargetFor({
    required double top,
    required double bottom,
    required double viewport,
    required double current,
    required double maxScrollExtent,
  }) {
    if (top < viewport && bottom > 0) return null;
    const headroom = 120.0;
    final target = bottom <= 0
        ? current + bottom - headroom
        : current + top - viewport;
    return target.clamp(0.0, maxScrollExtent);
  }

  /// Scrolls so [range] is on screen, without touching the selection.
  void revealRange(TextRange range) {
    final render = _renderEditor;
    if (render == null || !render.attached) return;
    final scrollable = Scrollable.maybeOf(context);
    final viewportBox = scrollable?.context.findRenderObject();
    if (viewportBox is! RenderBox) return;
    final rect = render.getLocalRectForCaret(TextPosition(offset: range.start));
    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final top = render.localToGlobal(rect.topLeft).dy - viewportTop;
    final bottom = render.localToGlobal(rect.bottomRight).dy - viewportTop;
    final position = widget.scrollController.hasClients
        ? widget.scrollController.position
        : null;
    if (position == null) return;
    final target = scrollTargetFor(
      top: top,
      bottom: bottom,
      viewport: position.viewportDimension,
      current: position.pixels,
      maxScrollExtent: position.maxScrollExtent,
    );
    if (target == null) return;
    widget.scrollController.animateTo(
      target,
      duration: context.motion(Spring.snappy.duration),
      curve: Spring.snappy.curve,
    );
  }

  @visibleForTesting
  ChecklistDragController get checklistDrag => _drag;

  RenderEditor? get _renderEditor => _editorKey.currentState?.renderEditor;

  RenderBox? get _overlayBox =>
      _stackKey.currentContext?.findRenderObject() as RenderBox?;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.initialContent);
    _controller.readOnly = !widget.canEdit;
    _selection = _controller.selection;
    _isBlank = _isBlankNote(_controller.document);
    _sorter = ChecklistSorter(
      _controller,
      isEnabled: () => widget.sortChecklistItems,
      delay: () => context.motion(AnchorTokens.motionDurationSinkDelay),
      compose: _composeMove,
    );
    _drag = ChecklistDragController(
      controller: _controller,
      editor: () => _renderEditor,
      overlay: () => _overlayBox,
      scrollController: () => widget.scrollController,
      vsync: this,
      onDrop: _composeWithoutFocus,
      visibleArea: () => widget.visibleArea?.call(),
      isFolded: (offset) => _lists.isFolded(offset),
      listEndGap: () => context.noteTypography.listEndGap,
    )..dragged.addListener(_dragChanged);
    _refreshLists();
    _listen();
    widget.focusNode.addListener(_onFocusChanged);
    _repaintMarks();
  }

  /// `changes` belongs to the document: listen again after `document =`.
  void _listen() {
    _onChangedSub = _controller.changes.listen((change) {
      _followUndoable(change);
      _refreshLists();
      widget.onChanged?.call();
      _repaintMarks();
      _sorter.handleChange(change);
      _checkBlank();
    });
    _controller
      ..addListener(_checkSlash)
      ..addListener(_checkSelection);
  }

  void _unlisten() {
    _onChangedSub?.cancel();
    _controller
      ..removeListener(_checkSlash)
      ..removeListener(_checkSelection);
  }

  void _checkSelection() {
    final selection = _controller.selection;
    if (selection == _selection) return;
    _selection = selection;
    if (_overlapsFoldedLines(selection)) _unfoldSoon();
    widget.onSelectionChanged?.call(selection);
  }

  bool _overlapsFoldedLines(TextSelection selection) {
    if (!selection.isValid || _lists.folded.isEmpty) return false;
    var line = _controller.document.queryChild(selection.start).node;
    while (line is Line) {
      if (isFoldedLine(line)) return true;
      if (line.documentOffset + line.length > selection.end) return false;
      line = line.nextLine;
    }
    return false;
  }

  void _unfoldSoon() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase != SchedulerPhase.persistentCallbacks) return _setFolded(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setFolded(false);
    });
  }

  /// Must run before Quill builds the lines, whose leadings read it.
  void _refreshLists() {
    _lists = ListLines.of(
      _controller.document,
      canFold: widget.sortChecklistItems,
      isFolded: _isFolded,
    );
  }

  void _toggleFold() {
    _consumeNextEditorTap();
    _setFolded(!_isFolded);
  }

  void _setFolded(bool isFolded) {
    if (_isFolded == isFolded) return;
    _isFolded = isFolded;
    _refreshLists();
    _repaintMarks();
    setState(() {});
    widget.onCheckedFoldChanged?.call(isFolded);
  }

  void _dragChanged() {
    final isDragged = _drag.dragged.value != null;
    if (isDragged) {
      _sorter.cancelAll();
      _ghost.show();
    } else {
      _ghost.hide();
    }
    _repaintMarks();
    setState(() {});
  }

  void _composeWithoutFocus(Delta move) => _editWithoutFocus(
    () => _controller.compose(move, _controller.selection, ChangeSource.local),
  );

  void _composeMove(Delta move, TextSelection selection) => _editWithoutFocus(
    () => _controller
      ..compose(move, _controller.selection, ChangeSource.local)
      ..updateSelection(selection, ChangeSource.local),
  );

  void _checkBlank() {
    final isBlank = _isBlankNote(_controller.document);
    if (isBlank == _isBlank) return;
    setState(() => _isBlank = isBlank);
    widget.onBlankChanged?.call(isBlank);
  }

  /// Paint runs after layout in the same frame: the marks read the new lines.
  void _repaintMarks() => _paintTick.value++;

  @override
  void didUpdateWidget(covariant RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
    if (oldWidget.canEdit != widget.canEdit) {
      _controller.readOnly = !widget.canEdit;
    }
    if (widget.isCheckedFolded != oldWidget.isCheckedFolded) {
      _isFolded = widget.isCheckedFolded;
      _refreshLists();
    } else if (widget.sortChecklistItems != oldWidget.sortChecklistItems) {
      _refreshLists();
    }
    if (widget.initialContent != oldWidget.initialContent ||
        widget.contentVersion != oldWidget.contentVersion) {
      // The new text notifies the toolbar, which can't rebuild mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncExternalContent();
      });
    }
  }

  /// Doesn't fire [RichTextEditor.onChanged] or touch focus.
  void _syncExternalContent() {
    final incoming = _parseDocument(widget.initialContent);
    if (incoming.toDelta() == _controller.document.toDelta()) return;
    final previousOffset = _controller.selection.extentOffset;
    _drag.cancel();
    _sorter.cancelAll();
    _undoable = null;
    _unlisten();
    _editWithoutFocus(() {
      _controller.document = incoming;
      _refreshLists();
      _controller.updateSelection(
        TextSelection.collapsed(
          offset: previousOffset.clamp(0, _controller.document.length - 1),
        ),
        ChangeSource.silent,
      );
      _listen();
    });
    _checkBlank();
  }

  /// Edits without moving focus or raising the keyboard. Quill reads both
  /// guards during the next build.
  void _editWithoutFocus(VoidCallback edit) {
    _controller
      ..ignoreFocusOnTextChange = true
      ..skipRequestKeyboard = true;
    edit();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller
        ..ignoreFocusOnTextChange = false
        ..skipRequestKeyboard = false;
    });
  }

  @override
  void dispose() {
    _caretScroll.dispose();
    for (final timer in _justCheckedTimers.values) {
      timer.cancel();
    }
    _drag
      ..dragged.removeListener(_dragChanged)
      ..dispose();
    _sorter.dispose();
    _unlisten();
    _undoable?._closedAs = _controller.document.toDelta();
    widget.focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _slashHint?.dispose();
    _paintTick.dispose();
    _slashQuery.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final wasEditing = _isEditing;
    if (!widget.canEdit && widget.focusNode.hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      setState(() => _isEditing = false);
    } else {
      setState(() => _isEditing = widget.focusNode.hasFocus);
    }
    if (wasEditing != _isEditing && widget.canEdit) {
      widget.onEditingChanged?.call(_isEditing);
    }
    _checkSlash();
  }

  QuillController _createController(String? content) {
    // ignore: experimental_member_use
    final config = QuillControllerConfig(
      // ignore: experimental_member_use
      clipboardConfig: QuillClipboardConfig(
        // ignore: experimental_member_use
        onClipboardPaste: () => _controller.pasteAddressAsLink(),
      ),
    );
    return QuillController(
      document: _parseDocument(content)
        ..setCustomRules(const [PlainInsertRule()]),
      selection: const TextSelection.collapsed(offset: 0),
      config: config,
      onReplaceText: _noteTyping,
    );
  }

  /// Quill sends typing here one character at a time, a paste all at once,
  /// and a word the keyboard corrects as the part that changed.
  bool _noteTyping(int index, int length, Object? data) {
    if (_isApplying || data is! String || data.isEmpty) return true;
    if (data == '/') _typedSlashOffset = index;
    if (_typedBreak.hasMatch(data)) {
      final caret = index + data.length;
      final isTyped = data.length == 1 || length > 0;
      scheduleMicrotask(() => _afterTyping(caret, isTyped: isTyped));
    }
    return true;
  }

  /// Runs once Quill has moved the caret past what was typed.
  void _afterTyping(int caret, {required bool isTyped}) {
    if (!mounted) return;
    final selection = _controller.selection;
    if (!selection.isCollapsed || selection.baseOffset != caret) return;
    if (_ownUndoStep(_controller.applyMarkdownShortcut)) {
      Haptics.selection();
    } else if (isTyped) {
      _ownUndoStep(() => _controller.linkTypedAddress(caret - 1));
    }
  }

  /// Quill merges edits made close together into one Undo step.
  bool _ownUndoStep(bool Function() edit) {
    final history = _controller.document.history;
    final lastRecorded = history.lastRecorded;
    history.lastRecorded = 0;
    final didEdit = edit();
    history.lastRecorded = didEdit ? 0 : lastRecorded;
    return didEdit;
  }

  void _apply(VoidCallback edit) {
    _isApplying = true;
    try {
      edit();
    } finally {
      _isApplying = false;
    }
  }

  Document _parseDocument(String? content) {
    final ops = decodeNoteOps(content);
    if (ops.isEmpty) return Document();
    try {
      return Document.fromJson(ops);
    } catch (_) {
      return Document();
    }
  }

  String getContent() =>
      jsonEncode({'ops': _controller.document.toDelta().toJson()});

  bool matchesContent(String? content) =>
      _parseDocument(content).toDelta() == _controller.document.toDelta();

  String getPlainText() => _controller.document.toPlainText().trim();

  bool get isEmpty => _controller.document.toPlainText().trim().isEmpty;

  bool get isBlank => _isBlank;

  bool get hasFocus => widget.focusNode.hasFocus;

  /// The text after a typed "/"; null when there is no slash to answer.
  ValueListenable<String?> get slashQuery => _slashQuery;

  TextSelection get selection => _controller.selection;

  bool get hasSelection => !_controller.selection.isCollapsed;

  String textIn(TextRange range) => range.isCollapsed
      ? ''
      : _controller.document.toPlainText().substring(range.start, range.end);

  /// Stops before checked items folded at the end.
  void focusEnd() {
    widget.focusNode.requestFocus();
    var offset = _controller.document.length - 1;
    for (final range in _lists.folded.reversed) {
      if (range.start > 0 && offset >= range.start && offset <= range.end) {
        offset = range.start - 1;
      }
    }
    _controller.updateSelection(
      TextSelection.collapsed(offset: offset),
      ChangeSource.local,
    );
  }

  /// In global coordinates; null until the caret's line is laid out.
  Rect? caretRect() {
    final editor = _renderEditor;
    if (editor == null || !editor.attached) return null;
    final caret = _controller.selection.extent;
    final line = editor.childAtPosition(caret).container;
    if (!line.containsOffset(caret.offset)) return null;
    final local = editor.getLocalRectForCaret(caret);
    return editor.localToGlobal(local.topLeft) & local.size;
  }

  double get scrollSpace {
    final scroll = widget.scrollController;
    if (!scroll.hasClients || !scroll.position.hasContentDimensions) return 0;
    return math.max(0, scroll.position.maxScrollExtent - scroll.offset);
  }

  /// Scrolls the caret's line above [y] on the screen. Runs frame by frame:
  /// Quill's own scroll to the caret cuts an animateTo short.
  void keepCaretAbove(double y) {
    final caret = caretRect();
    final scroll = widget.scrollController;
    if (caret == null || !scroll.hasClients) return;
    final position = scroll.position;
    final overlap = caret.bottom - y;
    if (overlap < 0.5) return;
    final target = math.min(
      position.pixels + overlap,
      position.maxScrollExtent,
    );
    final isRunning = _caretScroll.isAnimating;
    if (isRunning && (target - _caretScrollTarget).abs() < 0.5) return;
    final velocity = isRunning ? _caretScroll.velocity : 0.0;
    _caretScrollTarget = target;
    _caretScroll.value = position.pixels;
    _caretScroll.springTo(target, spring: Spring.keyboard, velocity: velocity);
  }

  void _followCaretScroll() {
    final scroll = widget.scrollController;
    if (!scroll.hasClients ||
        scroll.position.userScrollDirection != ScrollDirection.idle) {
      _caretScroll.stop();
      return;
    }
    scroll.position.jumpTo(_caretScroll.value);
  }

  /// Without focus, adds a new line of [kind] at the end.
  void applyLineKind(LineKind kind) {
    if (hasFocus) {
      _controller.setLineKind(kind);
    } else {
      widget.focusNode.requestFocus();
      _apply(() => _controller.appendLine(kind));
    }
  }

  void applyLineStyle(LineKind kind) => _controller.setLineKind(kind);

  void startLineAtTop(LineKind kind) {
    widget.focusNode.requestFocus();
    _controller.startLineAtTop(kind);
  }

  void addFirstLine(String text) {
    widget.focusNode.requestFocus();
    _ownUndoStep(() {
      _controller.addFirstLine(text);
      return true;
    });
  }

  void paintHighlight(String name) {
    if (hasSelection) _controller.setHighlight(name);
  }

  void clearHighlight() {
    if (hasSelection) _controller.setHighlight(null);
  }

  void setLink(TextRange range, String text, String url) => _apply(() {
    if (range.isCollapsed) {
      _controller.insertLink(range.start, text, url);
    } else {
      _controller.replaceWithLink(
        range.start,
        range.end - range.start,
        text,
        url,
      );
    }
  });

  void removeLink(EditorLink link) =>
      _controller.removeLinkAt(link.start, link.length);

  ({int items, int checked}) get checklistCount {
    final lines = parseDocumentLines(_controller.document);
    return (
      items: lines.where((line) => line.isChecklist).length,
      checked: lines.where((line) => line.isChecked).length,
    );
  }

  UndoableEdit? uncheckAll() => _editChecked(buildUncheckAllDelta);

  UndoableEdit? deleteChecked() => _editChecked(buildDeleteCheckedDelta);

  UndoableEdit? _editChecked(Delta? Function(List<ParsedLine> lines) build) {
    final lines = parseDocumentLines(_controller.document);
    final change = build(lines);
    if (change == null) return null;
    _sorter.cancelAll();
    final edit = UndoableEdit._(
      this,
      lines.where((line) => line.isChecked).length,
      change,
      _controller.document.toDelta(),
    );
    _ownUndoStep(() {
      _composeWithoutFocus(change);
      return true;
    });
    edit._steps = _controller.document.history.stack.undo.length;
    return _undoable = edit;
  }

  void _followUndoable(DocChange change) {
    final edit = _undoable;
    if (edit == null) return;
    if (!edit._hasSeenOwnChange) {
      edit._hasSeenOwnChange = change.change == edit._change;
    } else if (_controller.document.history.stack.undo.length < edit._steps) {
      _undoable = null;
    } else {
      edit._since = edit._since.compose(change.change);
    }
  }

  bool _undo(UndoableEdit edit) {
    if (!mounted || _undoable != edit) return false;
    _undoable = null;
    final history = _controller.document.history;
    final inverse = edit._inverse;
    if (edit._since.isNotEmpty || history.stack.undo.length != edit._steps) {
      _ownUndoStep(() {
        _composeWithoutFocus(inverse);
        return true;
      });
      return true;
    }
    history.ignoreChange = true;
    _composeWithoutFocus(inverse);
    history
      ..ignoreChange = false
      ..lastRecorded = 0;
    history.stack.undo.removeLast();
    history.stack.redo.add(edit._change);
    return true;
  }

  void clearSlash() {
    final slash = _slashQuery.value;
    if (slash == null) return;
    final end = _controller.selection.baseOffset;
    final start = end - slash.length - 1;
    if (start < 0) return;
    _controller.replaceText(
      start,
      slash.length + 1,
      '',
      TextSelection.collapsed(offset: start),
    );
    _slashQuery.value = null;
  }

  void _checkSlash() {
    final slashOffset = _typedSlashOffset;
    final query = slashOffset != null && widget.focusNode.hasFocus
        ? slashQueryAt(
            _controller,
            slashOffset: slashOffset,
            l10n: context.l10n,
          )
        : null;
    if (query == null) _typedSlashOffset = null;
    _slashQuery.value = query;
  }

  KeyEventResult? _onKeyPressed(KeyEvent event, Node? node) {
    final onBackspaceAtStart = widget.onBackspaceAtStart;
    if (onBackspaceAtStart == null ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace ||
        _controller.selection != const TextSelection.collapsed(offset: 0)) {
      return null;
    }
    String? text;
    _editWithoutFocus(() => text = _controller.removeFirstLine());
    if (text == null) return null;
    onBackspaceAtStart(text!);
    return KeyEventResult.handled;
  }

  SlashHint _slashHintOf(TextStyle style) {
    final textScaler = MediaQuery.textScalerOf(context);
    final current = _slashHint;
    if (current != null &&
        current.focusNode == widget.focusNode &&
        current.style == style &&
        current.textScaler == textScaler &&
        current.hint == context.l10n.editorSlashHint) {
      return current;
    }
    if (current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => current.dispose());
    }
    return _slashHint = SlashHint(
      controller: _controller,
      focusNode: widget.focusNode,
      editor: () => _renderEditor,
      stack: () => _overlayBox,
      style: style,
      textScaler: textScaler,
      hint: context.l10n.editorSlashHint,
    );
  }

  Widget? _buildLeading(Node node, LeadingConfig config) {
    if (node is! Line) return null;
    return buildListMarker(
      context,
      node,
      config,
      cache: _markers,
      role: _lists[node],
      palette: widget.palette,
      canEdit: widget.canEdit,
      drag: _drag,
      onToggle: _toggleCheckbox,
      wasJustChecked: _justCheckedTimers.containsKey,
      isFolded: _isFolded,
      onFold: _toggleFold,
      isDragged: _isDragged(node),
    );
  }

  bool _isDragged(Line line) {
    final dragged = _drag.dragged.value;
    if (dragged == null) return false;
    final offset = line.documentOffset;
    return offset >= dragged.start && offset <= dragged.end;
  }

  InlineSpan _buildSpan(
    BuildContext context,
    Node node,
    int nodeOffset,
    String text,
    TextStyle? style,
    GestureRecognizer? recognizer,
  ) {
    final line = node.parent;
    if (line is Line && isFoldedLine(line)) {
      return TextSpan(text: text, style: foldedTextStyle);
    }
    if (line is Line && _isDragged(line)) style = _draggedStyle(line, style);
    return defaultSpanBuilder(
      context,
      node,
      nodeOffset,
      text,
      style,
      recognizer,
    );
  }

  TextStyle _draggedStyle(Line line, TextStyle? style) {
    final isChecked =
        line.style.attributes[Attribute.list.key]?.value == 'checked';
    final ink = isChecked ? widget.palette.muted : context.anchor.appText;
    final color = style?.color ?? ink;
    return (style ?? const TextStyle()).copyWith(
      color: draggedColor(color),
      decorationColor: draggedColor(
        style?.decorationColor ??
            (isChecked ? ink.withValues(alpha: 0.55) : color),
      ),
    );
  }

  void _toggleCheckbox(Line line, bool checked) {
    _sorter.cancelAll();
    Haptics.selection();
    if (checked) {
      _justCheckedTimers[line]?.cancel();
      _justCheckedTimers[line] = Timer(
        AnchorTokens.motionDurationTick,
        () => _justCheckedTimers.remove(line),
      );
    }
    _consumeNextEditorTap();
    final lines = parseDocumentLines(_controller.document);
    final index = lineIndexAt(lines, line.documentOffset);
    if (index == -1) return;
    final blockEnd = checklistBlockEnd(lines, index, lines.length - 1);
    var toggledLines = 0;
    for (var i = index; i <= blockEnd; i++) {
      if (lines[i].isChecklist) toggledLines++;
    }
    final delta = buildChecklistToggleDelta(lines, index, checked);
    _editWithoutFocus(
      () =>
          _controller.compose(delta, _controller.selection, ChangeSource.local),
    );
    // A cascade changes several lines in one delta, so handleChange cannot
    // read it as one toggle. A single line still uses the delayed path.
    if (toggledLines > 1) _sorter.sortAfterToggle(index);
  }

  /// Quill's own tap recognizer gets a tap on a control in the text too;
  /// _onEditorTapUp drops it.
  void _consumeNextEditorTap() {
    _consumeEditorTapUp = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _consumeEditorTapUp = false;
    });
  }

  bool _onEditorTapUp(
    TapUpDetails details,
    TextPosition Function(Offset offset) getPosition,
  ) {
    if (_consumeEditorTapUp) {
      _consumeEditorTapUp = false;
      return true;
    }
    final position = getPosition(details.globalPosition);
    // True ends the tap here: Quill won't move the caret or raise the keyboard.
    if (_showLinkAt(position.offset)) return !_isEditing;
    if (!widget.canEdit) widget.onReadOnlyTap?.call();
    return false;
  }

  /// With this recognizer, Quill neither shows its link menu nor opens links.
  GestureRecognizer? _buildLinkRecognizer(Attribute attribute, Leaf leaf) {
    if (attribute.key != Attribute.link.key || attribute.value == null) {
      return null;
    }
    return LongPressGestureRecognizer()
      ..onLongPress = () => _showLinkAt(leaf.documentOffset);
  }

  bool _showLinkAt(int offset) {
    final editor = _renderEditor;
    final onLinkTap = widget.onLinkTap;
    if (editor == null || onLinkTap == null) return false;
    final link = _controller.linkAt(offset, editor);
    if (link == null) return false;
    Haptics.selection();
    onLinkTap(link);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final spacing = NoteBlockSpacing(context.noteTypography);
    final styles = noteEditorStyles(
      context,
      muted: palette.muted,
      surface: palette.surface,
      border: palette.border,
      spacing: spacing,
    );
    final editor = Stack(
      key: _stackKey,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: HighlightUnderlay(
                  repaint: _paintTick,
                  controller: _controller,
                  editor: () => _renderEditor,
                  stack: () => _overlayBox,
                  colors: palette.highlightFill,
                  isDragged: _isDragged,
                  typography: context.noteTypography,
                  textScaler: MediaQuery.textScalerOf(context),
                  search: widget.search,
                  searchFill: context.anchor.searchHighlight,
                  searchActiveFill: context.anchor.searchHighlightActive,
                ),
              ),
            ),
          ),
        ),
        if (widget.hasSlashHint && widget.canEdit)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _slashHintOf(
                    styles.paragraph!.style.copyWith(color: palette.muted),
                  ),
                ),
              ),
            ),
          ),
        CollapsedBlockSpacing(
          spacing: spacing,
          editor: () => _renderEditor,
          changes: _controller,
          child: QuillEditor.basic(
            controller: _controller,
            focusNode: widget.focusNode,
            scrollController: widget.scrollController,
            config: QuillEditorConfig(
              placeholder: widget.canEdit && !_isEditing && _isBlank
                  ? context.l10n.editorPlaceholder
                  : null,
              padding: EdgeInsets.zero,
              autoFocus: false,
              expands: false,
              scrollable: false,
              scrollBottomInset: math.max(0, widget.bottomInset - _caretMargin),
              showCursor: _isEditing && widget.canEdit,
              enableInteractiveSelection: true,
              customStyles: styles,
              customStyleBuilder: (attribute) =>
                  checkedLineStyle(attribute, palette.muted),
              textSpanBuilder: _buildSpan,
              // ignore: experimental_member_use
              customLeadingBlockBuilder: _buildLeading,
              // ignore: experimental_member_use
              onKeyPressed: _onKeyPressed,
              editorKey: _editorKey,
              onTapUp: _onEditorTapUp,
              customRecognizerBuilder: _buildLinkRecognizer,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(child: ChecklistDragOverlay(drag: _drag)),
        ),
      ],
    );
    return OverlayPortal(
      controller: _ghost,
      overlayChildBuilder: (context) => ChecklistDragGhost(drag: _drag),
      child: editor,
    );
  }
}

/// An edit made from outside the text, for a snackbar's Undo.
class UndoableEdit {
  UndoableEdit._(this._editor, this.count, this._change, this._before);

  final RichTextEditorState _editor;

  final int count;

  final Delta _change;
  final Delta _before;
  late final int _steps;
  Delta _since = Delta();
  bool _hasSeenOwnChange = false;
  Delta? _closedAs;

  Delta get _inverse => _since.transform(_change.invert(_before), false);

  /// False once the note is closed or the edit was undone in the text.
  bool undo() => _editor._undo(this);

  /// Null when the note changed after it was closed.
  String? undoneContent(String? content) {
    final closedAs = _closedAs;
    if (closedAs == null) return null;
    try {
      final saved = Document.fromJson(decodeNoteOps(content)).toDelta();
      if (saved != closedAs) return null;
    } catch (_) {
      return null;
    }
    return jsonEncode({'ops': closedAs.compose(_inverse).toJson()});
  }
}

final _typedBreak = RegExp(r'^\S*[ \u00a0\n]$');

bool _isBlankNote(Document document) {
  for (final node in document.root.children) {
    if (node is! Line || lineKindOfLine(node) != LineKind.text) return false;
    for (final leaf in node.children) {
      if (leaf is! QuillText || leaf.value.trim().isNotEmpty) return false;
    }
  }
  return true;
}
