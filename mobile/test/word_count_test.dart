import 'package:anchor/features/notes/domain/note_blocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts words between spaces', () {
    expect(countWords('Design review, Sep 26'), 4);
    expect(countWords("  to-do   don't\n1. "), 3);
    expect(countWords(''), 0);
  });

  test('skips dashes, arrows and emoji standing alone', () {
    expect(countWords('Lisbon — Porto → Faro 🎉'), 3);
  });

  test('counts each Chinese or Japanese character', () {
    expect(countWords('你好世界'), 4);
    expect(countWords('iPhone用のメモ'), 5);
  });

  test('counts other scripts by their spaces', () {
    expect(countWords('Привет мир'), 2);
    expect(countWords('안녕하세요 세계'), 2);
  });
}
