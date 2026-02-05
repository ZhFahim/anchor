import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';

/// Creates custom styles for the Quill editor matching the app theme
DefaultStyles getEditorStyles(BuildContext context) {
  final theme = Theme.of(context);

  // Use DM Sans for body text (matching app theme)
  final baseStyle = GoogleFonts.dmSans(
    color: theme.colorScheme.onSurface,
    fontSize: 18,
    height: 1.6,
  );

  // Use Playfair Display for headers (matching app theme)
  final headerStyle = GoogleFonts.playfairDisplay(
    color: theme.colorScheme.onSurface,
    fontWeight: FontWeight.bold,
  );

  return DefaultStyles(
    paragraph: DefaultTextBlockStyle(
      baseStyle,
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(0, 8),
      const VerticalSpacing(0, 0),
      null,
    ),
    h1: DefaultTextBlockStyle(
      headerStyle.copyWith(fontSize: 28, height: 1.3),
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(16, 8),
      const VerticalSpacing(0, 0),
      null,
    ),
    h2: DefaultTextBlockStyle(
      headerStyle.copyWith(fontSize: 24, height: 1.3),
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(12, 6),
      const VerticalSpacing(0, 0),
      null,
    ),
    h3: DefaultTextBlockStyle(
      headerStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(8, 4),
      const VerticalSpacing(0, 0),
      null,
    ),
    bold: const TextStyle(fontWeight: FontWeight.bold),
    italic: const TextStyle(fontStyle: FontStyle.italic),
    underline: const TextStyle(decoration: TextDecoration.underline),
    strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
    link: TextStyle(
      color: theme.colorScheme.tertiary,
      decoration: TextDecoration.underline,
    ),
    placeHolder: DefaultTextBlockStyle(
      baseStyle.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(0, 0),
      const VerticalSpacing(0, 0),
      null,
    ),
    lists: DefaultListBlockStyle(
      baseStyle.copyWith(height: 1.2),
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(0, 12),
      const VerticalSpacing(8, 0),
      null,
      null,
      indentWidthBuilder: (block, context, count, widthBuilder) {
        final attrs = block.style.attributes;
        final listAttr = attrs[Attribute.list.key];
        final isOrdered = listAttr?.value == 'ordered';
        final isBullet = listAttr?.value == 'bullet';

        if (attrs.containsKey(Attribute.blockQuote.key)) {
          return HorizontalSpacing(16, 0);
        }
        if (isOrdered) {
          final base = widthBuilder(16, count);
          return HorizontalSpacing(base, 0);
        }
        if (isBullet) {
          return HorizontalSpacing(24, 0);
        }
        return HorizontalSpacing(36, 0);
      },
    ),
    quote: DefaultTextBlockStyle(
      baseStyle.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        fontStyle: FontStyle.italic,
      ),
      const HorizontalSpacing(16, 0),
      const VerticalSpacing(8, 8),
      const VerticalSpacing(0, 0),
      BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
    ),
    code: DefaultTextBlockStyle(
      GoogleFonts.jetBrainsMono(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      const HorizontalSpacing(0, 0),
      const VerticalSpacing(8, 8),
      const VerticalSpacing(0, 0),
      BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

/// Custom style builder that adds strikethrough for checked list items
TextStyle getCheckedListStyle(Attribute attribute, BuildContext context) {
  // Check if this is a checked list item
  if (attribute.key == Attribute.list.key && attribute.value == 'checked') {
    final theme = Theme.of(context);
    return TextStyle(
      decoration: TextDecoration.lineThrough,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      decorationColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );
  }
  // Return empty style for non-matching attributes (no additional styling)
  return const TextStyle();
}
