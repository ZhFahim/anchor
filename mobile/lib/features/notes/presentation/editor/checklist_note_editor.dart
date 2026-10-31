import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/checklist_task.dart';
import 'editor_palette.dart';

class ChecklistNoteEditor extends StatefulWidget {
  const ChecklistNoteEditor({
    super.key,
    this.initialContent,
    this.contentVersion = 0,
    required this.canEdit,
    required this.palette,
    required this.onChanged,
    this.onFocusChanged,
  });

  final String? initialContent;
  final int contentVersion;
  final bool canEdit;
  final EditorPalette palette;
  final VoidCallback onChanged;
  final ValueChanged<bool>? onFocusChanged;

  @override
  State<ChecklistNoteEditor> createState() => ChecklistNoteEditorState();
}

class ChecklistNoteEditorState extends State<ChecklistNoteEditor> {
  late List<_TaskEntry> _tasks;
  bool _completedOpen = false;
  final _undo = <_ChecklistSnapshot>[];
  final _redo = <_ChecklistSnapshot>[];
  final _addFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tasks = _load(widget.initialContent);
  }

  List<_TaskEntry> _load(String? content) => [
    for (final task in readChecklist(content)) _entry(task),
  ];

  _TaskEntry _entry(ChecklistTask task, {Key? key}) {
    final entry = _TaskEntry(task, key: key);
    entry.focus.addListener(_focusChanged);
    return entry;
  }

  void _focusChanged() =>
      widget.onFocusChanged?.call(_tasks.any((task) => task.focus.hasFocus));

  @override
  void didUpdateWidget(ChecklistNoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentVersion != oldWidget.contentVersion &&
        !matchesContent(widget.initialContent)) {
      final old = _tasks;
      _undo.clear();
      _redo.clear();
      _tasks = _load(widget.initialContent);
      _retire(old);
    }
  }

  void _retire(Iterable<_TaskEntry> entries) {
    for (final entry in entries) {
      entry.focus.removeListener(_focusChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final entry in entries) {
        entry.dispose();
      }
      if (mounted) _focusChanged();
    });
  }

  @override
  void dispose() {
    _addFocus.dispose();
    for (final entry in _tasks) {
      entry.focus.removeListener(_focusChanged);
      entry.dispose();
    }
    super.dispose();
  }

  String getContent() => writeChecklist(_tasks.map((entry) => entry.task));
  String getPlainText() =>
      _tasks.map((entry) => entry.task.text).join('\n').trim();
  bool matchesContent(String? content) =>
      checklistContentsMatch(getContent(), content);

  void _changed(VoidCallback change) {
    if (!widget.canEdit) return;
    _undo.add(_snapshot());
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
    setState(change);
    for (final entry in _tasks) {
      entry.rememberSelection();
    }
    widget.onChanged();
  }

  _ChecklistSnapshot _snapshot() => _ChecklistSnapshot(
    [
      for (final entry in _tasks)
        _SavedTask(entry.task, entry.key, entry.selection),
    ],
    _tasks.where((entry) => entry.focus.hasFocus).firstOrNull?.key,
    _completedOpen,
  );

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  bool undo() => _restoreHistory(_undo, _redo);
  bool redo() => _restoreHistory(_redo, _undo);

  bool _restoreHistory(
    List<_ChecklistSnapshot> from,
    List<_ChecklistSnapshot> to,
  ) {
    if (!widget.canEdit || from.isEmpty) return false;
    to.add(_snapshot());
    final snapshot = from.removeLast();
    final old = {for (final entry in _tasks) entry.key: entry};
    setState(() {
      _completedOpen = snapshot.completedOpen;
      _tasks = [
        for (final saved in snapshot.tasks)
          old.remove(saved.key) ?? _entry(saved.task, key: saved.key),
      ];
      for (var i = 0; i < _tasks.length; i++) {
        final entry = _tasks[i];
        final saved = snapshot.tasks[i];
        entry.task = saved.task;
        entry.text.value = TextEditingValue(
          text: saved.task.text,
          selection: TextSelection(
            baseOffset: saved.selection.baseOffset.clamp(
              0,
              saved.task.text.length,
            ),
            extentOffset: saved.selection.extentOffset.clamp(
              0,
              saved.task.text.length,
            ),
          ),
        );
      }
    });
    _retire(old.values);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focused = _tasks
          .where((entry) => entry.key == snapshot.focused)
          .firstOrNull;
      if (focused != null && (!focused.task.done || _completedOpen)) {
        focused.focus.requestFocus();
      }
    });
    widget.onChanged();
    return true;
  }

  KeyEventResult _historyKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        !widget.canEdit ||
        _tasks.any(
          (entry) =>
              entry.focus.hasFocus && !entry.text.value.composing.isCollapsed,
        )) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isAltPressed ||
        (!keyboard.isControlPressed && !keyboard.isMetaPressed)) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyZ) {
      keyboard.isShiftPressed ? redo() : undo();
    } else if (event.logicalKey == LogicalKeyboardKey.keyY &&
        !keyboard.isShiftPressed) {
      redo();
    } else {
      return KeyEventResult.ignored;
    }
    // Do not fall back to a TextField's separate native history at the boundary.
    return KeyEventResult.handled;
  }

  void _focus(_TaskEntry entry) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_tasks.contains(entry)) return;
        entry.focus.requestFocus();
        entry.text.selection = TextSelection.collapsed(
          offset: entry.text.text.length,
        );
      });

  void _add({_TaskEntry? after, String text = ''}) {
    if (!widget.canEdit) return;
    final entry = _entry(ChecklistTask(text: text));
    _changed(
      () => _tasks.insert(
        after == null ? _tasks.length : _tasks.indexOf(after) + 1,
        entry,
      ),
    );
    _focus(entry);
  }

  void focusEnd() {
    if (!widget.canEdit) return;
    final active = _tasks.where((entry) => !entry.task.done);
    if (active.isEmpty) {
      _add();
      return;
    }
    _focus(active.last);
  }

  void addFirstLine(String text) {
    if (!widget.canEdit) return;
    final active = _tasks.where((entry) => !entry.task.done);
    if (text.isEmpty && active.isNotEmpty) {
      _focus(active.first);
      return;
    }
    final entry = _entry(ChecklistTask(text: text));
    _changed(() => _tasks.insert(0, entry));
    _focus(entry);
  }

  void _edit(_TaskEntry entry, String text) {
    if (!text.contains('\n')) {
      _changed(() => entry.task = entry.task.copyWith(text: text));
      return;
    }
    final lines = text.split(RegExp(r'\r?\n'));
    final added = [
      for (final line in lines.skip(1)) _entry(ChecklistTask(text: line)),
    ];
    _changed(() {
      entry.task = entry.task.copyWith(text: lines.first);
      entry.text.text = lines.first;
      _tasks.insertAll(_tasks.indexOf(entry) + 1, added);
    });
    _focus(added.last);
  }

  KeyEventResult _navigate(_TaskEntry entry, KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        (keyboard.isControlPressed || keyboard.isMetaPressed) &&
        !keyboard.isAltPressed &&
        !keyboard.isShiftPressed &&
        entry.text.value.composing.isCollapsed) {
      if (!widget.canEdit) return KeyEventResult.ignored;
      final active = _tasks.where((task) => !task.task.done).toList();
      final index = active.indexOf(entry);
      final next = entry.task.done
          ? entry
          : index + 1 < active.length
          ? active[index + 1]
          : index > 0
          ? active[index - 1]
          : null;
      _changed(() => entry.task = entry.task.copyWith(done: !entry.task.done));
      if (next != null) {
        _focus(next);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _addFocus.requestFocus();
        });
      }
      return KeyEventResult.handled;
    }
    final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
        keyboard.isAltPressed &&
        !keyboard.isControlPressed &&
        !keyboard.isMetaPressed &&
        !keyboard.isShiftPressed &&
        entry.text.value.composing.isCollapsed &&
        (up || down)) {
      if (!widget.canEdit) return KeyEventResult.ignored;
      if (entry.task.done) return KeyEventResult.handled;
      final active = _tasks.where((task) => !task.task.done).toList();
      final from = active.indexOf(entry);
      final to = from + (up ? -1 : 1);
      if (to >= 0 && to < active.length) {
        active.insert(to, active.removeAt(from));
        var index = 0;
        _changed(() {
          _tasks = [
            for (final task in _tasks) task.task.done ? task : active[index++],
          ];
        });
      }
      return KeyEventResult.handled;
    }
    if ((event is! KeyDownEvent && event is! KeyRepeatEvent) ||
        keyboard.isAltPressed ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isShiftPressed ||
        !entry.text.value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    if (!up && event.logicalKey != LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.ignored;
    }
    final selection = entry.text.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final editable = entry.focus.context
        ?.findAncestorStateOfType<EditableTextState>();
    if (editable == null) return KeyEventResult.ignored;
    final line = editable.renderEditable.getLineAtOffset(selection.extent);
    // Let the standard text-field shortcuts handle movement inside wrapped text.
    if (up ? line.start > 0 : line.end < entry.text.text.length) {
      return KeyEventResult.ignored;
    }
    final visible = [
      ..._tasks.where((task) => !task.task.done),
      if (_completedOpen) ..._tasks.where((task) => task.task.done),
    ];
    final index = visible.indexOf(entry) + (up ? -1 : 1);
    if (index < 0 || index >= visible.length) return KeyEventResult.handled;
    final target = visible[index];
    final targetEditable = target.focus.context
        ?.findAncestorStateOfType<EditableTextState>();
    if (targetEditable == null) return KeyEventResult.ignored;
    final targetLine = targetEditable.renderEditable.getLineAtOffset(
      TextPosition(offset: up ? target.text.text.length : 0),
    );
    final column = selection.extentOffset - line.start;
    target.focus.requestFocus();
    target.text.selection = TextSelection.collapsed(
      offset: (targetLine.start + column).clamp(
        targetLine.start,
        targetLine.end,
      ),
    );
    Scrollable.ensureVisible(target.focus.context!);
    return KeyEventResult.handled;
  }

  Widget _row(_TaskEntry entry, {int? dragIndex}) {
    final task = entry.task;
    final l10n = context.l10n;
    return Material(
      key: entry.key,
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.canEdit && dragIndex != null)
            ReorderableDragStartListener(
              index: dragIndex,
              child: SizedBox(
                width: AnchorTokens.space32,
                height: context.density.control,
                child: Icon(
                  LucideIcons.gripVertical,
                  size: AnchorTokens.sizeIconSmall,
                  color: widget.palette.muted,
                ),
              ),
            ),
          Checkbox(
            value: task.done,
            semanticLabel: task.done
                ? l10n.checklistRestoreTask(task.text)
                : l10n.checklistCompleteTask(task.text),
            onChanged: !widget.canEdit
                ? null
                : (checked) {
                    _changed(() {
                      entry.focus.unfocus();
                      entry.task = task.copyWith(done: checked);
                    });
                  },
          ),
          Expanded(
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: (_, event) => _navigate(entry, event),
              child: TextField(
                controller: entry.text,
                focusNode: entry.focus,
                readOnly: !widget.canEdit,
                minLines: 1,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => _add(after: entry),
                onChanged: (text) => _edit(entry, text),
                style: context.noteTypography.body.copyWith(
                  color: task.done
                      ? widget.palette.muted
                      : context.anchor.appText,
                  decoration: task.done ? TextDecoration.lineThrough : null,
                ),
                decoration: InputDecoration(
                  hintText: widget.canEdit ? l10n.checklistAddTask : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          if (widget.canEdit)
            IconButton(
              tooltip: l10n.checklistDeleteTask,
              icon: Icon(
                LucideIcons.x,
                size: AnchorTokens.sizeIconSmall,
                color: widget.palette.muted,
              ),
              onPressed: () {
                _changed(() {
                  _tasks.remove(entry);
                  if (_tasks.isEmpty) _tasks.add(_entry(const ChecklistTask()));
                });
                _retire([entry]);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _tasks.where((entry) => !entry.task.done).toList();
    final completed = _tasks.where((entry) => entry.task.done).toList();
    final l10n = context.l10n;
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => _historyKey(event),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            buildDefaultDragHandles: false,
            itemCount: active.length,
            itemBuilder: (context, index) =>
                _row(active[index], dragIndex: index),
            onReorderItem: (from, to) {
              if (!widget.canEdit) return;
              final moved = active.removeAt(from);
              active.insert(to, moved);
              var index = 0;
              _changed(() {
                _tasks = [
                  for (final task in _tasks)
                    task.task.done ? task : active[index++],
                ];
              });
            },
          ),
          if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.checklistAllCompleted,
                style: TextStyle(color: widget.palette.muted),
              ),
            ),
          if (widget.canEdit)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                focusNode: _addFocus,
                onPressed: () => _add(),
                icon: const Icon(
                  LucideIcons.plus,
                  size: AnchorTokens.sizeIconSmall,
                ),
                label: Text(l10n.checklistAddTask),
              ),
            ),
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: widget.palette.border),
            Semantics(
              expanded: _completedOpen,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _completedOpen = !_completedOpen),
                icon: Icon(
                  _completedOpen
                      ? LucideIcons.chevronDown
                      : LucideIcons.chevronRight,
                  size: AnchorTokens.sizeIconSmall,
                ),
                label: Text(l10n.checklistCompleted(completed.length)),
              ),
            ),
            if (_completedOpen) ...completed.map((entry) => _row(entry)),
          ],
        ],
      ),
    );
  }
}

class _TaskEntry {
  _TaskEntry(this.task, {Key? key})
    : key = key ?? UniqueKey(),
      text = TextEditingController(text: task.text) {
    text.addListener(rememberSelection);
  }
  ChecklistTask task;
  TextSelection selection = const TextSelection.collapsed(offset: -1);
  // onChanged runs after the controller updates. Keep the pre-edit caret for undo.
  void rememberSelection() {
    if (text.text == task.text) selection = text.selection;
  }

  final TextEditingController text;
  final FocusNode focus = FocusNode();
  final Key key;
  void dispose() {
    text.dispose();
    focus.dispose();
  }
}

class _SavedTask {
  const _SavedTask(this.task, this.key, this.selection);
  final ChecklistTask task;
  final Key key;
  final TextSelection selection;
}

class _ChecklistSnapshot {
  const _ChecklistSnapshot(this.tasks, this.focused, this.completedOpen);
  final List<_SavedTask> tasks;
  final Key? focused;
  final bool completedOpen;
}
