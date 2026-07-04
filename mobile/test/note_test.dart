import 'package:anchor/features/notes/domain/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('displayTitle falls back to Untitled for blank titles', () {
    // Empty title is canonical in storage; 'Untitled' is display-only.
    expect(const Note(id: 'n1', title: '').displayTitle, 'Untitled');
    expect(const Note(id: 'n1', title: '  ').displayTitle, 'Untitled');
    expect(const Note(id: 'n1', title: 'Groceries').displayTitle, 'Groceries');
  });

  test('permission gates editing', () {
    expect(const Note(id: 'n1', title: '').canEdit, isTrue); // owner default
    expect(
      const Note(id: 'n1', title: '', permission: NotePermission.editor)
          .canEdit,
      isTrue,
    );
    expect(
      const Note(id: 'n1', title: '', permission: NotePermission.viewer)
          .canEdit,
      isFalse,
    );
  });
}
