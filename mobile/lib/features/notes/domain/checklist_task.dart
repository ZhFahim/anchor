import 'dart:convert';

import 'note_blocks.dart';

/// Tasks keep the same Quill storage format as web and regular note checkboxes.
class ChecklistTask {
  const ChecklistTask({
    this.text = '',
    this.done = false,
    this.contentOps = const [],
    this.attributes = const {},
  });

  final String text;
  final bool done;
  final List<Map<String, dynamic>> contentOps;
  final Map<String, dynamic> attributes;

  ChecklistTask copyWith({String? text, bool? done}) => ChecklistTask(
    text: text ?? this.text,
    done: done ?? this.done,
    contentOps: text == null || text == this.text ? contentOps : const [],
    attributes: attributes,
  );
}

List<ChecklistTask> readChecklist(String? content) {
  final tasks = <ChecklistTask>[];
  var ops = <Map<String, dynamic>>[];
  var text = '';
  for (final raw in decodeNoteOps(content)) {
    if (raw is! Map) continue;
    final op = Map<String, dynamic>.from(raw);
    final insert = op['insert'];
    if (insert is! String) {
      ops.add(op);
      continue;
    }
    final parts = insert.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        text += parts[i];
        ops.add({...op, 'insert': parts[i]});
      }
      if (i < parts.length - 1) {
        final attributes =
            (op['attributes'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
        tasks.add(
          ChecklistTask(
            text: text,
            done: attributes['list'] == 'checked',
            contentOps: ops,
            attributes: attributes,
          ),
        );
        ops = [];
        text = '';
      }
    }
  }
  if (ops.isNotEmpty) tasks.add(ChecklistTask(text: text, contentOps: ops));
  return tasks.isEmpty ? [const ChecklistTask()] : tasks;
}

String writeChecklist(Iterable<ChecklistTask> tasks) => jsonEncode({
  'ops': [
    for (final task in tasks) ...[
      if (task.contentOps.isNotEmpty)
        ...task.contentOps
      else if (task.text.isNotEmpty)
        {'insert': task.text},
      {
        'insert': '\n',
        'attributes': {
          ...task.attributes,
          'list': task.done ? 'checked' : 'unchecked',
        },
      },
    ],
  ],
});

bool checklistContentsMatch(String? left, String? right) =>
    writeChecklist(readChecklist(left)) == writeChecklist(readChecklist(right));

/// Entry rows without text do not count toward a checklist's progress.
class ChecklistProgress {
  const ChecklistProgress({required this.total, required this.done});

  factory ChecklistProgress.fromContent(String? content) {
    final tasks = readChecklist(
      content,
    ).where((task) => task.text.trim().isNotEmpty).toList();
    return ChecklistProgress(
      total: tasks.length,
      done: tasks.where((task) => task.done).length,
    );
  }

  final int total;
  final int done;
  bool get allDone => total > 0 && done == total;
}
