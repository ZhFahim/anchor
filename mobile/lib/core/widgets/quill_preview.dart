import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A single line in the preview with optional list/checklist state.
class _PreviewLine {
  final String text;
  final String?
  listType; // 'checked' | 'unchecked' | 'ordered' | 'bullet' | null

  /// Nesting level (0 = top level).
  final int indent;

  const _PreviewLine({required this.text, this.listType, this.indent = 0});

  bool get isChecklist => listType == 'checked' || listType == 'unchecked';
  bool get isChecked => listType == 'checked';
  bool get isOrderedList => listType == 'ordered';
  bool get isBulletList => listType == 'bullet';
}

/// A lightweight read-only preview of Quill content for list views.
/// Renders checklists with checkbox icons, bullet/ordered lists with markers, and plain text.
class QuillPreview extends StatelessWidget {
  /// The content in JSON Delta format or plain text.
  final String? content;

  /// Maximum lines to show.
  final int maxLines;

  /// Text style for the preview.
  final TextStyle? style;

  const QuillPreview({super.key, this.content, this.maxLines = 6, this.style});

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final lines = _parseQuillContentToPreviewLines(content);

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveStyle =
        style ??
        GoogleFonts.dmSans(
          fontSize: 14,
          height: 1.5,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
        );

    final displayLines = lines
        .where((l) => l.text.trim().isNotEmpty)
        .take(maxLines)
        .toList();

    // Ordered counters per nesting level: deeper levels reset when the list
    // returns to a shallower one; a level's own count continues across
    // nested runs, matching the editor's numbering.
    final orderedCounters = <int, int>{};
    final children = <Widget>[];

    for (final line in displayLines) {
      final lineText = line.text.trim();
      if (line.listType == null) {
        orderedCounters.clear();
      } else {
        orderedCounters.removeWhere((level, _) => level > line.indent);
      }

      if (line.isChecklist) {
        children.add(
          Padding(
            padding: EdgeInsets.only(bottom: 2, left: line.indent * 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: Icon(
                    line.isChecked
                        ? LucideIcons.checkSquare
                        : LucideIcons.square,
                    size: 16,
                    color: line.isChecked
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.6,
                          ),
                  ),
                ),
                Expanded(
                  child: Text(
                    lineText,
                    style: effectiveStyle.copyWith(
                      decoration: line.isChecked
                          ? TextDecoration.lineThrough
                          : null,
                      color: line.isChecked
                          ? theme.textTheme.bodyMedium?.color?.withValues(
                              alpha: 0.6,
                            )
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.isOrderedList) {
        final count = (orderedCounters[line.indent] ?? 0) + 1;
        orderedCounters[line.indent] = count;
        children.add(
          Padding(
            padding: EdgeInsets.only(bottom: 2, left: line.indent * 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    _orderedMarker(count, line.indent),
                    style: effectiveStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lineText,
                    style: effectiveStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.isBulletList) {
        children.add(
          Padding(
            padding: EdgeInsets.only(bottom: 2, left: line.indent * 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: Text('•', style: effectiveStyle),
                ),
                Expanded(
                  child: Text(
                    lineText,
                    style: effectiveStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: EdgeInsets.only(bottom: 2, left: line.indent * 12.0),
            child: Text(
              lineText,
              style: effectiveStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// Marker for an ordered item, cycling number styles by depth like the
/// editor: 1. at the top level, then a., then i.
String _orderedMarker(int count, int indent) {
  return switch (indent % 3) {
    1 => '${_alpha(count)}.',
    2 => '${_roman(count)}.',
    _ => '$count.',
  };
}

String _alpha(int count) => String.fromCharCode(97 + (count - 1) % 26);

String _roman(int count) {
  const pairs = [
    (1000, 'm'),
    (900, 'cm'),
    (500, 'd'),
    (400, 'cd'),
    (100, 'c'),
    (90, 'xc'),
    (50, 'l'),
    (40, 'xl'),
    (10, 'x'),
    (9, 'ix'),
    (5, 'v'),
    (4, 'iv'),
    (1, 'i'),
  ];
  var value = count;
  final buffer = StringBuffer();
  for (final (threshold, numeral) in pairs) {
    while (value >= threshold) {
      buffer.write(numeral);
      value -= threshold;
    }
  }
  return buffer.toString();
}

/// Parses Quill Delta JSON into preview lines with checklist state.
/// Returns empty list if content is null/empty/invalid.
List<_PreviewLine> _parseQuillContentToPreviewLines(String? content) {
  if (content == null || content.isEmpty) return [];
  try {
    final json = jsonDecode(content);
    if (json is! Map || json['ops'] is! List) return [];
    final document = Document.fromJson(json['ops'] as List);
    final ops = document.toDelta().toList();
    final result = <_PreviewLine>[];
    var currentLineParts = <String>[];

    for (final op in ops) {
      if (op.data is! String) {
        currentLineParts.add('');
        continue;
      }
      final text = op.data as String;
      final parts = text.split('\n');

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (part.isNotEmpty) {
          currentLineParts.add(part);
        }
        if (i < parts.length - 1) {
          final lineText = currentLineParts.join();
          final listType = op.attributes?['list'] as String?;
          final indent = op.attributes?['indent'] as int? ?? 0;
          result.add(
            _PreviewLine(text: lineText, listType: listType, indent: indent),
          );
          currentLineParts = [];
        }
      }
    }

    if (currentLineParts.isNotEmpty) {
      final lineText = currentLineParts.join();
      result.add(_PreviewLine(text: lineText, listType: null));
    }

    return result;
  } catch (_) {
    return [];
  }
}

/// Extracts plain text from canonical Quill Delta JSON (`{ops: [...]}`).
/// Strict: returns empty string if the content is null/empty/invalid.
String extractPlainTextFromQuillContent(String? content) {
  if (content == null || content.isEmpty) return '';
  try {
    final json = jsonDecode(content);
    if (json is Map && json['ops'] is List) {
      final document = Document.fromJson(json['ops'] as List);
      final raw = document.toPlainText();
      final lines = raw
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      // Preserve real newlines, but ignore multiple blank newlines.
      return lines.join('\n');
    }
  } catch (_) {
    // invalid JSON -> strict mode
  }
  return '';
}
