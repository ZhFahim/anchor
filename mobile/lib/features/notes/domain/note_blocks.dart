import 'dart:convert';

/// Lists go four levels deep.
const int maxListIndent = 3;

bool isChecklistValue(Object? list) => list == 'checked' || list == 'unchecked';

enum BlockType { paragraph, h1, h2, h3, quote, code, bullet, ordered, check }

class InlineRun {
  const InlineRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.link,
    this.highlight,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final String? link;

  /// A highlight's name, such as "yellow". Notes store the name, never a color.
  final String? highlight;
}

class NoteBlock {
  const NoteBlock({
    required this.type,
    this.level = 0,
    this.done = false,
    this.runs = const [],
  });

  final BlockType type;

  /// List depth, 0 to [maxListIndent].
  final int level;

  final bool done;
  final List<InlineRun> runs;

  String get text => runs.map((r) => r.text).join();

  bool get isList =>
      type == BlockType.bullet ||
      type == BlockType.ordered ||
      type == BlockType.check;

  bool get isEmpty => text.trim().isEmpty;
}

List<dynamic> decodeNoteOps(String? content) {
  if (content == null || content.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(content);
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['ops'] is List) return decoded['ops'] as List;
  } catch (_) {}
  return [
    {'insert': '$content\n'},
  ];
}

/// Pictures and other embeds are skipped.
List<NoteBlock> parseNoteBlocks(String? content) {
  final ops = decodeNoteOps(content);
  final blocks = <NoteBlock>[];
  var runs = <InlineRun>[];
  for (final op in ops) {
    if (op is! Map) continue;
    final insert = op['insert'];
    final attrs =
        (op['attributes'] as Map?)?.cast<String, dynamic>() ?? const {};
    if (insert is! String) continue;
    final parts = insert.split('\n');
    for (var i = 0; i < parts.length; i++) {
      final piece = parts[i];
      if (piece.isNotEmpty) runs.add(_run(piece, attrs));
      if (i < parts.length - 1) {
        blocks.add(_block(runs, attrs));
        runs = <InlineRun>[];
      }
    }
  }
  if (runs.isNotEmpty) blocks.add(_block(runs, const {}));
  return blocks;
}

InlineRun _run(String text, Map<String, dynamic> attributes) => InlineRun(
  text,
  bold: attributes['bold'] == true,
  italic: attributes['italic'] == true,
  underline: attributes['underline'] == true,
  strike: attributes['strike'] == true,
  code: attributes['code'] == true,
  link: attributes['link'] is String ? attributes['link'] as String : null,
  highlight: attributes['highlight'] is String
      ? attributes['highlight'] as String
      : null,
);

NoteBlock _block(List<InlineRun> runs, Map<String, dynamic> attributes) {
  final level = (attributes['indent'] is int ? attributes['indent'] as int : 0)
      .clamp(0, maxListIndent);
  final list = attributes['list'];
  final header = attributes['header'];
  final type = switch (list) {
    'bullet' => BlockType.bullet,
    'ordered' => BlockType.ordered,
    _ when isChecklistValue(list) => BlockType.check,
    _ =>
      header == 1
          ? BlockType.h1
          : header == 2
          ? BlockType.h2
          : header == 3
          ? BlockType.h3
          : attributes['blockquote'] == true
          ? BlockType.quote
          : attributes['code-block'] != null
          ? BlockType.code
          : BlockType.paragraph,
  };
  return NoteBlock(
    type: type,
    level: type == BlockType.paragraph ? 0 : level,
    done: list == 'checked',
    runs: runs,
  );
}

String plainTextOf(String? content) =>
    parseNoteBlocks(content).map((b) => b.text).join('\n').trim();

class CardLine {
  const CardLine.block(this.block) : checkedCount = null, isAllChecked = false;
  const CardLine.checked(int count, {required this.isAllChecked})
    : block = null,
      checkedCount = count;

  final NoteBlock? block;
  final int? checkedCount;
  final bool isAllChecked;
}

List<CardLine> foldCheckedItems(List<NoteBlock> blocks) {
  final out = <CardLine>[];
  var checked = 0;
  var unchecked = 0;
  void endList() {
    if (checked > 0) {
      out.add(
        CardLine.checked(checked, isAllChecked: unchecked == 0 && checked > 1),
      );
    }
    checked = 0;
    unchecked = 0;
  }

  for (final block in blocks) {
    if (block.type == BlockType.check) {
      if (block.done) {
        checked++;
      } else {
        unchecked++;
        out.add(CardLine.block(block));
      }
      continue;
    }
    endList();
    out.add(CardLine.block(block));
  }
  endList();
  return out;
}

List<String?> orderedMarkers(List<NoteBlock?> blocks) {
  final counts = List.filled(maxListIndent + 1, 0);
  final out = <String?>[];
  for (final block in blocks) {
    if (block == null || block.type != BlockType.ordered) {
      if (block == null || !block.isList) counts.fillRange(0, counts.length, 0);
      out.add(null);
      continue;
    }
    final level = block.level.clamp(0, maxListIndent);
    counts[level]++;
    for (var k = level + 1; k < counts.length; k++) {
      counts[k] = 0;
    }
    out.add('${_marker(counts[level], level)}.');
  }
  return out;
}

String _marker(int number, int level) => switch (level % 3) {
  0 => '$number',
  1 => String.fromCharCode(96 + ((number - 1) % 26) + 1),
  _ => _roman(number),
};

String _roman(int number) {
  const numerals = [
    'i',
    'ii',
    'iii',
    'iv',
    'v',
    'vi',
    'vii',
    'viii',
    'ix',
    'x',
  ];
  return number >= 1 && number <= numerals.length
      ? numerals[number - 1]
      : '$number';
}

final _word = RegExp(r'\S+');

int countWords(String text) => _word.allMatches(text).length;

int wordCount(String? content) => countWords(plainTextOf(content));

String snippetTextOf(String? content, {bool hideCompleted = false}) =>
    parseNoteBlocks(content)
        .where((block) => !hideCompleted || !block.done)
        .map((b) => b.text.trim())
        .where((l) => l.isNotEmpty)
        .join('\n');
