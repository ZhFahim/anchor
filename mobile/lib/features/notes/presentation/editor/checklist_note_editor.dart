import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _tasks = _load(widget.initialContent);
  }

  List<_TaskEntry> _load(String? content) => [
    for (final task in readChecklist(content)) _entry(task),
  ];

  _TaskEntry _entry(ChecklistTask task) {
    final entry = _TaskEntry(task);
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
    setState(change);
    widget.onChanged();
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
                    entry.focus.unfocus();
                    _changed(() => entry.task = task.copyWith(done: checked));
                  },
          ),
          Expanded(
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
    return Column(
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
              onPressed: () => setState(() => _completedOpen = !_completedOpen),
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
    );
  }
}

class _TaskEntry {
  _TaskEntry(this.task) : text = TextEditingController(text: task.text);
  ChecklistTask task;
  final TextEditingController text;
  final FocusNode focus = FocusNode();
  final Key key = UniqueKey();
  void dispose() {
    text.dispose();
    focus.dispose();
  }
}
