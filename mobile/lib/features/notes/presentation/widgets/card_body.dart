import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/highlighted_text.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/note_blocks.dart';
import 'note_surface.dart';
import 'note_text.dart';

enum CardLayout { masonry, grid, list }

class CardBody extends StatelessWidget {
  const CardBody({
    super.key,
    required this.content,
    required this.appearance,
    required this.layout,
    this.firstLineEndInset = 0,
    this.hideCompleted = false,
  });

  final String? content;
  final bool hideCompleted;
  final NoteAppearance appearance;
  final CardLayout layout;

  /// Room kept at the end of the first line, for the selection check.
  final double firstLineEndInset;

  @override
  Widget build(BuildContext context) {
    final blocks = parseNoteBlocks(
      content,
    ).where((b) => !b.isEmpty && (!hideCompleted || !b.done)).toList();
    if (blocks.isEmpty) return const SizedBox.shrink();
    final lines = foldCheckedItems(blocks);
    final density = context.density;
    final cap = switch (layout) {
      CardLayout.list => density.previewList,
      CardLayout.grid => density.previewGrid,
      CardLayout.masonry => density.previewMasonry,
    };
    final isTruncated = lines.length > cap;
    final shown = lines.take(cap).toList();
    final numbers = orderedMarkers(shown.map((l) => l.block).toList());
    final colors = context.anchor;
    final base = context.noteTypography.cardBody
        .withSize(13) // off-scale: card text
        .copyWith(height: 1.5, color: colors.appText);

    final rows = <Widget>[];
    for (var i = 0; i < shown.length; i++) {
      final line = shown[i];
      if (line.checkedCount case final count?) {
        rows.add(
          Row(
            children: [
              Icon(
                LucideIcons.circleCheck,
                size: 14, // off-scale: card summary
                color: appearance.colors.muted,
              ),
              const SizedBox(width: 7), // off-scale: card summary
              Text(
                line.isAllChecked
                    ? context.l10n.cardAllChecked(count)
                    : context.l10n.cardChecked(count),
                style: base
                    .withSize(12.5) // off-scale: card text
                    .copyWith(color: appearance.colors.muted),
              ),
            ],
          ),
        );
        continue;
      }
      rows.add(
        _CardLine(
          block: line.block!,
          marker: numbers[i],
          base: base,
          appearance: appearance,
          isFirst: i == 0,
          isSingleLine: layout == CardLayout.list,
        ),
      );
    }
    if (firstLineEndInset > 0) {
      rows[0] = Padding(
        padding: EdgeInsets.only(right: firstLineEndInset),
        child: rows[0],
      );
    }
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 3, // off-scale: card lines
      children: rows,
    );
    // A done count ends the preview at full strength, not faded.
    if (!isTruncated ||
        layout == CardLayout.list ||
        shown.last.checkedCount != null) {
      return column;
    }
    final line = MediaQuery.textScalerOf(context).scale(13) * 1.7;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [((rect.height - line) / rect.height).clamp(0.0, 1.0), 1],
        colors: const [Color(0xFF000000), Color(0x00000000)],
      ).createShader(rect),
      child: column,
    );
  }
}

class _CardLine extends StatelessWidget {
  const _CardLine({
    required this.block,
    required this.marker,
    required this.base,
    required this.appearance,
    required this.isFirst,
    required this.isSingleLine,
  });

  final NoteBlock block;
  final String? marker;
  final TextStyle base;
  final NoteAppearance appearance;
  final bool isFirst;
  final bool isSingleLine;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    switch (block.type) {
      case BlockType.h1 || BlockType.h2 || BlockType.h3:
        final (span, marks) = spanOfRuns(
          context,
          block.runs,
          style: base
              .withSize(13 * 1.04) // off-scale: card heading
              .copyWith(
                fontWeight: FontWeight.w600,
                height: 1.45,
                letterSpacing: -0.07,
              ),
          appearance: appearance,
        );
        return Padding(
          padding: EdgeInsets.only(top: isFirst ? 0 : 4),
          child: HighlightedText(
            span: span,
            highlights: marks,
            maxLines: isSingleLine ? 1 : 2,
          ),
        );
      case BlockType.quote:
        final (span, marks) = spanOfRuns(
          context,
          block.runs,
          style: base.copyWith(color: appearance.colors.muted),
          appearance: appearance,
        );
        return Container(
          padding: const EdgeInsets.only(left: 10), // off-scale: card quote
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AnchorTokens.colorAccentFill.withValues(alpha: 0.75),
                width: 2,
              ),
            ),
          ),
          child: HighlightedText(
            span: span,
            highlights: marks,
            maxLines: isSingleLine ? 1 : 3,
          ),
        );
      case BlockType.code:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
          ), // off-scale: card code
          decoration: BoxDecoration(
            color: appearance.colors.surface,
            borderRadius: BorderRadius.circular(
              AnchorTokens.radiusXs,
            ), // off-scale: card code
          ),
          child: Text(
            block.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.code.copyWith(
              fontSize: 12, // off-scale: card code
              height: 1.65,
              color: colors.appText,
            ),
          ),
        );
      case BlockType.paragraph:
        final (span, marks) = spanOfRuns(
          context,
          block.runs,
          style: base,
          appearance: appearance,
        );
        return HighlightedText(
          span: span,
          highlights: marks,
          maxLines: isSingleLine ? 1 : 3,
        );
      case BlockType.bullet || BlockType.ordered || BlockType.check:
        final (span, marks) = spanOfRuns(
          context,
          block.runs,
          style: base,
          appearance: appearance,
          isStrikethrough: block.done,
        );
        final indent = block.level * AnchorTokens.sizeListIndentCard;
        final scaler = MediaQuery.textScalerOf(context);
        return Padding(
          padding: EdgeInsets.only(left: indent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: scaler.scale(21), // off-scale: card checkbox
                height: scaler.scale(13) * 1.5, // off-scale: card checkbox
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _ListMarker(
                    block: block,
                    marker: marker,
                    appearance: appearance,
                  ),
                ),
              ),
              Expanded(
                child: HighlightedText(
                  span: span,
                  highlights: marks,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _ListMarker extends StatelessWidget {
  const _ListMarker({
    required this.block,
    required this.marker,
    required this.appearance,
  });

  final NoteBlock block;
  final String? marker;
  final NoteAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    if (block.type == BlockType.ordered) {
      return SizedBox(
        width: 15, // off-scale: card bullets
        child: Padding(
          padding: const EdgeInsets.only(right: 3), // off-scale: card numbers
          child: OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              marker ?? '',
              maxLines: 1,
              softWrap: false,
              style: AppTypography.footnote.tabular.copyWith(
                fontFamily: context.noteTypography.family,
                fontWeight: FontWeight.w600,
                color: appearance.colors.muted,
              ),
            ),
          ),
        ),
      );
    }
    if (block.type == BlockType.check) {
      return Container(
        width: AnchorTokens.sizeCheckboxCard,
        height: AnchorTokens.sizeCheckboxCard,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.5), // off-scale: card checkbox
          border: Border.all(color: appearance.colors.muted, width: 1.5),
          color: block.done ? colors.accentStrong : null,
        ),
      );
    }
    return SizedBox(
      width: 15, // off-scale: card bullets
      child: Center(
        child: switch (block.level % 3) {
          0 => Container(
            width: 5, // off-scale: card bullets
            height: 5, // off-scale: card bullets
            decoration: BoxDecoration(
              color: colors.appText,
              shape: BoxShape.circle,
            ),
          ),
          1 => Container(
            width: 5, // off-scale: card bullets
            height: 5, // off-scale: card bullets
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.appText, width: 1.3),
            ),
          ),
          _ => Container(
            width: 6, // off-scale: card bullets
            height: 1.6,
            color: colors.appText,
          ),
        },
      ),
    );
  }
}
