import 'dart:convert';

import 'package:anchor/features/notes/domain/checklist_task.dart';
import 'package:anchor/features/notes/domain/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('note types default safely for older and unknown servers', () {
    expect(NoteType.fromString(null), NoteType.note);
    expect(NoteType.fromString('other'), NoteType.note);
    expect(NoteType.fromString('checklist'), NoteType.checklist);
    expect(const Note(id: 'n', title: '').noteType, NoteType.note);
  });

  test('tasks round-trip in the web checklist format', () {
    final content = writeChecklist([
      const ChecklistTask(text: 'Milk 🥛'),
      const ChecklistTask(text: 'Bread', done: true),
      const ChecklistTask(),
    ]);
    final tasks = readChecklist(content);
    expect(tasks.map((task) => task.text), ['Milk 🥛', 'Bread', '']);
    expect(tasks.map((task) => task.done), [false, true, false]);
    expect(checklistContentsMatch(content, writeChecklist(tasks)), isTrue);
    expect(
      checklistContentsMatch(null, writeChecklist([const ChecklistTask()])),
      isTrue,
    );
  });

  test('toggling keeps formatting from other clients', () {
    final original = {
      'ops': [
        {
          'insert': 'Milk',
          'attributes': {'bold': true},
        },
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked', 'indent': 1},
        },
      ],
    };
    final tasks = readChecklist(jsonEncode(original));
    final saved =
        jsonDecode(writeChecklist([tasks.single.copyWith(done: true)])) as Map;
    expect((saved['ops'] as List).first, (original['ops'] as List).first);
    expect((saved['ops'] as List).last, {
      'insert': '\n',
      'attributes': {'list': 'checked', 'indent': 1},
    });
  });

  test('editing a task changes its text without dropping other tasks', () {
    final tasks = readChecklist(
      writeChecklist([
        const ChecklistTask(text: 'Milk'),
        const ChecklistTask(text: 'Bread', done: true),
      ]),
    );
    tasks[0] = tasks[0].copyWith(text: 'Coffee');
    expect(readChecklist(writeChecklist(tasks)).map((task) => task.text), [
      'Coffee',
      'Bread',
    ]);
  });
}
