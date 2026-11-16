import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../domain/note_blocks.dart';
import 'document_lines.dart';
import 'line_kind.dart';

/// Notes store a highlight's name, never a color.
const String highlightKey = 'highlight';

/// The highlight attribute for [name]; null removes it.
Attribute<String?> highlightAttribute(String? name) =>
    Attribute<String?>(highlightKey, AttributeScope.inline, name);

LineKind lineKindOf(Map<String, dynamic>? attributes) {
  final list = attributes?[Attribute.list.key];
  if (isChecklistValue(list)) return LineKind.checklist;
  if (list == 'bullet') return LineKind.bullet;
  if (list == 'ordered') return LineKind.numbered;
  return switch (attributes?[Attribute.header.key]) {
    1 => LineKind.h1,
    2 => LineKind.h2,
    3 => LineKind.h3,
    _ when attributes?[Attribute.blockQuote.key] != null => LineKind.quote,
    _ when attributes?[Attribute.codeBlock.key] != null => LineKind.code,
    _ => LineKind.text,
  };
}

LineKind lineKindOfLine(Line line) => lineKindOf(line.style.toJson());

Map<String, dynamic> lineAttributesChange(
  LineKind kind,
  Map<String, dynamic>? current,
) => {
  for (final MapEntry(:key, :value) in lineAttributesOf(kind).entries)
    if (value != null || (current?.containsKey(key) ?? false)) key: value,
};

Map<String, dynamic> lineAttributesOf(LineKind kind) => {
  Attribute.header.key: switch (kind) {
    LineKind.h1 => 1,
    LineKind.h2 => 2,
    LineKind.h3 => 3,
    _ => null,
  },
  Attribute.list.key: switch (kind) {
    LineKind.checklist => Attribute.unchecked.value,
    LineKind.bullet => Attribute.ul.value,
    LineKind.numbered => Attribute.ol.value,
    _ => null,
  },
  Attribute.blockQuote.key: kind == LineKind.quote ? true : null,
  Attribute.codeBlock.key: kind == LineKind.code ? true : null,
  if (!kind.isList) Attribute.indent.key: null,
};

extension EditorFormat on QuillController {
  Style get _style => getSelectionStyle();

  /// Quill's selection style gives an empty line the style of the line above it.
  LineKind get lineKind {
    final line = document.queryChild(selection.start).node;
    return line is Line ? lineKindOfLine(line) : LineKind.text;
  }

  /// A selection ending at the very start of a line leaves that line out.
  void setLineKind(LineKind kind) {
    final lines = parseDocumentLines(document);
    final first = lineIndexAt(lines, selection.start);
    var last = lineIndexAt(lines, selection.end);
    if (first < 0 || last < 0) return;
    if (last > first && selection.end == lines[last].startOffset) last--;
    final touched = lines.sublist(first, last + 1);
    final isAll = touched.every(
      (line) => lineKindOf(line.newlineAttributes) == kind,
    );
    final target = isAll ? LineKind.text : kind;
    final change = Delta();
    var cursor = 0;
    for (final line in touched) {
      final attributes = lineAttributesChange(target, line.newlineAttributes);
      if (attributes.isEmpty) continue;
      final newline = line.startOffset + line.length - 1;
      if (newline > cursor) change.retain(newline - cursor);
      change.retain(1, attributes);
      cursor = newline + 1;
    }
    if (change.isEmpty) return;
    compose(change, selection, ChangeSource.local);
  }

  void startLineAtTop(LineKind kind) {
    final first = parseDocumentLines(document).first;
    final isBlank =
        first.length == 1 &&
        lineKindOf(first.newlineAttributes) == LineKind.text;
    if (!isBlank) {
      // Composed as is: Quill's insert rules would copy line 1's style.
      compose(Delta()..insert('\n'), selection, ChangeSource.local);
    }
    updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
    setLineKind(kind);
  }

  void addFirstLine(String text) {
    final first = document.root.children.first;
    final isBlank =
        first is Line &&
        first.length == 1 &&
        lineKindOfLine(first) == LineKind.text;
    // Composed as is: Quill's insert rules would copy line 1's style.
    compose(
      Delta()..insert(isBlank ? text : '$text\n'),
      selection,
      ChangeSource.local,
    );
    updateSelection(
      const TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
  }

  /// Null when the first line isn't plain text.
  String? removeFirstLine() {
    final first = document.root.children.first;
    if (first is! Line ||
        lineKindOfLine(first) != LineKind.text ||
        first.children.any((leaf) => leaf is! QuillText)) {
      return null;
    }
    final text = first.toPlainText();
    // The note always keeps its last line break.
    final length = first.isLast ? first.length - 1 : first.length;
    compose(Delta()..delete(length), selection, ChangeSource.local);
    return text.substring(0, text.length - 1);
  }

  /// False when Backspace should join the line to the one above.
  bool handleBackspaceAtLineStart(int offset) {
    final query = document.queryChild(offset);
    if (query.node is! Line || query.offset != 0) return false;
    final lines = parseDocumentLines(document);
    final index = lineIndexAt(lines, offset);
    if (index < 0 || lines[index].startOffset != offset) return false;
    final line = lines[index];
    final kind = lineKindOf(line.newlineAttributes);
    if (kind == LineKind.text) return false;
    final Delta change;
    if (kind.isList && line.indent > 0) {
      change = buildListIndentDelta(lines, offset, offset, increase: false)!;
    } else if (kind == LineKind.code &&
        index > 0 &&
        lineKindOf(lines[index - 1].newlineAttributes) == LineKind.code) {
      return false;
    } else {
      change = Delta()
        ..retain(line.startOffset + line.length - 1)
        ..retain(
          1,
          lineAttributesChange(LineKind.text, line.newlineAttributes),
        );
    }
    compose(change, selection, ChangeSource.local);
    return true;
  }

  bool isOn(Attribute attribute) => _style.isOn(attribute);

  void toggleInline(Attribute attribute) {
    formatSelection(
      isOn(attribute) ? Attribute.clone(attribute, null) : attribute,
    );
  }

  /// Null unless all of the selection has the same one.
  String? get highlight => _style.highlight;

  void setHighlight(String? name) => formatSelection(highlightAttribute(name));

  void indentBy(int delta) {
    if (delta == 0) return;
    final change = buildListIndentDelta(
      parseDocumentLines(document),
      selection.start,
      selection.end,
      increase: delta > 0,
    );
    if (change == null) return;
    compose(change, selection, ChangeSource.local);
  }

  int get indentLevel => _style.attributes.indentLevel;

  void appendLine(LineKind kind) {
    final end = document.length - 1;
    final lastLineEmpty =
        document.toPlainText().endsWith('\n\n') ||
        document.toPlainText().trim().isEmpty;
    if (!lastLineEmpty) {
      replaceText(end, 0, '\n', TextSelection.collapsed(offset: end + 1));
    } else {
      updateSelection(TextSelection.collapsed(offset: end), ChangeSource.local);
    }
    setLineKind(kind);
  }
}

extension StyleFormat on Style {
  bool isOn(Attribute attribute) =>
      attributes[attribute.key]?.value == attribute.value;

  String? get highlight => attributes[highlightKey]?.value as String?;
}
