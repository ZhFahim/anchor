import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A single line in the preview with optional list/checklist state.
class _PreviewLine {
  final String text;
  final String?
  listType; // 'checked' | 'unchecked' | 'ordered' | 'bullet' | null

  const _PreviewLine({required this.text, this.listType});

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

    var orderedListIndex = 0;
    final children = <Widget>[];

    for (final line in displayLines) {
      final lineText = line.text.trim();

      if (line.isChecklist) {
        orderedListIndex = 0;
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
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
        orderedListIndex++;
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '$orderedListIndex.',
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
        orderedListIndex = 0;
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
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
        orderedListIndex = 0;
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
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
          result.add(_PreviewLine(text: lineText, listType: listType));
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
