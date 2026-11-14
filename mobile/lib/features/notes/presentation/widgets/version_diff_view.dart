import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/motion/haptics.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/note_typography.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/highlighted_text.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/note_blocks.dart';
import '../../domain/version_diff.dart';
import '../editor/editor_styles.dart';
import '../editor/list_markers.dart';
import 'note_surface.dart';
import 'note_text.dart';

class DiffColors {
  factory DiffColors.of(BuildContext context, NoteAppearance appearance) {
    final colors = context.anchor;
    final plain = colors.notes['none']!.bg;
    Color band(Color status, double percent) =>
        _tintInPlainHue(appearance.colors.bg, plain, status, percent);
    return DiffColors._(
      addedLine: band(colors.statusAdded, colors.blendAddedLine),
      addedWord: band(colors.statusAdded, colors.blendAddedWord),
      removedLine: band(colors.statusRemoved, colors.blendRemovedLine),
      removedWord: band(colors.statusRemoved, colors.blendRemovedWord),
      addedText: colors.statusAddedInk,
      removedText: colors.statusRemovedInk,
    );
  }

  const DiffColors._({
    required this.addedLine,
    required this.addedWord,
    required this.removedLine,
    required this.removedWord,
    required this.addedText,
    required this.removedText,
  });

  final Color addedLine;
  final Color addedWord;
  final Color removedLine;
  final Color removedWord;
  final Color addedText;
  final Color removedText;

  static Color _tintInPlainHue(
    Color note,
    Color plain,
    Color status,
    double percent,
  ) {
    final onNote = HSLColor.fromColor(Color.lerp(note, status, percent / 100)!);
    final onPlain = HSLColor.fromColor(
      Color.lerp(plain, status, percent / 100)!,
    );
    return onNote
        .withHue(onPlain.hue)
        .withSaturation(math.max(onNote.saturation, onPlain.saturation))
        .toColor();
  }
}

class VersionDiffView extends StatelessWidget {
  const VersionDiffView({
    super.key,
    required this.diff,
    required this.appearance,
    required this.open,
    required this.onOpen,
    this.showsAllLines = false,
  });

  final VersionDiff diff;
  final NoteAppearance appearance;

  /// Lines opened from a fold.
  final Set<int> open;
  final ValueChanged<FoldedLines> onOpen;

  /// Shows every line, with nothing folded.
  final bool showsAllLines;

  @override
  Widget build(BuildContext context) {
    final colors = DiffColors.of(context, appearance);
    final lines = diff.lines;
    final markers = orderedMarkers([for (final l in lines) l.block]);
    final items = showsAllLines
        ? List<Object>.generate(lines.length, (i) => i)
        : foldLines(lines, open);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          if (item is FoldedLines)
            _FoldRow(
              fold: item,
              appearance: appearance,
              onTap: () => onOpen(item),
            )
          else
            _Line(
              line: lines[item as int],
              marker: markers[item],
              appearance: appearance,
              colors: colors,
            ),
      ],
    );
  }
}

class _FoldRow extends StatelessWidget {
  const _FoldRow({
    required this.fold,
    required this.appearance,
    required this.onTap,
  });

  final FoldedLines fold;
  final NoteAppearance appearance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = fold.to - fold.from;
    Widget dashes() => Expanded(
      child: CustomPaint(
        size: const Size.fromHeight(1),
        painter: _DashedLinePainter(
          appearance.colors.muted.withValues(alpha: 0.45),
        ),
      ),
    );
    return Pressable(
      style: PressStyle.button,
      onTap: () {
        Haptics.selection();
        onTap();
      },
      semanticLabel: context.l10n.diffShowUnchanged(count),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          spacing: 10, // off-scale: the fold
          children: [
            dashes(),
            DecoratedBox(
              decoration: BoxDecoration(
                color: appearance.colors.surface,
                borderRadius: BorderRadius.circular(AnchorTokens.radiusPill),
                border: Border.all(
                  color: appearance.colors.border.withValues(alpha: 0.6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 3, 11, 3),
                // off-scale: the fold
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6, // off-scale: the fold
                  children: [
                    Icon(
                      LucideIcons.chevronsUpDown,
                      size: 13, // off-scale: the fold
                      color: appearance.colors.muted,
                    ),
                    Text(
                      context.l10n.diffUnchanged(count),
                      style: AppTypography.chip.copyWith(
                        fontWeight: FontWeight.w400,
                        height: 1.7,
                        color: appearance.colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            dashes(),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 4, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

class _Line extends StatelessWidget {
  const _Line({
    required this.line,
    required this.marker,
    required this.appearance,
    required this.colors,
  });

  final VersionLine line;
  final String? marker;
  final NoteAppearance appearance;
  final DiffColors colors;

  TextStyle _style(NoteTypography typography) => switch (line.block.type) {
    BlockType.h1 => typography.versionHeading(1),
    BlockType.h2 => typography.versionHeading(2),
    BlockType.h3 => typography.versionHeading(3),
    BlockType.code => AppTypography.code,
    _ => typography.versionBody,
  };

  @override
  Widget build(BuildContext context) {
    final themeColors = context.anchor;
    final block = line.block;
    final kind = line.kind;
    final typography = context.noteTypography;
    final base = _style(typography).copyWith(
      color: block.done ? appearance.colors.muted : themeColors.appText,
      decoration: block.done ? TextDecoration.lineThrough : null,
      decorationColor: appearance.colors.muted,
    );

    Widget text;
    if (kind == ChangeKind.changed) {
      text = Text.rich(
        TextSpan(
          style: base,
          children: [
            for (final word in line.words)
              TextSpan(
                text: word.text,
                style: switch (word.kind) {
                  WordKind.same => null,
                  WordKind.removed => TextStyle(
                    backgroundColor: colors.removedWord,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: colors.removedText,
                    decorationThickness: 1.5,
                  ),
                  WordKind.added => TextStyle(
                    backgroundColor: colors.addedWord,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.addedText,
                    decorationThickness: 1.5,
                  ),
                },
              ),
          ],
        ),
      );
    } else {
      final (span, marks) = spanOfRuns(
        context,
        block.runs,
        style: kind == ChangeKind.removed
            ? base.copyWith(
                color: base.color!.withValues(alpha: 0.65),
                decoration: TextDecoration.lineThrough,
                decorationColor: colors.removedText.withValues(alpha: 0.6),
                decorationThickness: 1.5,
              )
            : base,
        appearance: appearance,
        isStrikethrough: kind == ChangeKind.removed,
      );
      text = HighlightedText(
        span: span,
        highlights: marks,
        maxLines: null,
        overflow: TextOverflow.clip,
      );
    }

    final fontSize = MediaQuery.textScalerOf(context).scale(base.fontSize!);
    final lineHeight = fontSize * base.height!;
    final lettersOffset = typography.font.lettersMiddleOffset(
      fontSize,
      base.height!,
    );
    Widget content = text;
    if (block.isList) {
      final lead = SizedBox(
        width: 22, // off-scale: note text and change marks
        height: lineHeight,
        child: switch (block.type) {
          BlockType.check => Transform.translate(
            offset: Offset(0, lettersOffset),
            child: Center(
              child: NoteCheckBox(
                checked: block.done,
                size: NoteCheckBox.maxSize,
                border: appearance.colors.muted,
                tick: themeColors.checkMark,
              ),
            ),
          ),
          BlockType.ordered => Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 3,
              ), // off-scale: note text and change marks
              child: Text(
                marker ?? '1.',
                style: typography.versionBody
                    .withSize(typography.versionBody.fontSize! * 0.9)
                    .copyWith(
                      fontWeight: FontWeight.w600,
                      color: appearance.colors.muted,
                      height: 1,
                    ),
              ),
            ),
          ),
          _ => Transform.translate(
            offset: Offset(0, lettersOffset),
            child: Center(
              child: ListBullet(
                level: block.level,
                color: appearance.colors.muted,
              ),
            ),
          ),
        },
      );
      content = Padding(
        padding: EdgeInsets.only(
          left: AnchorTokens.sizeListIndent * block.level,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            lead,
            SizedBox(
              width: block.type == BlockType.check ? 10 : 6,
            ), // off-scale: note text and change marks
            Expanded(child: text),
          ],
        ),
      );
    } else if (block.type == BlockType.quote) {
      final size = base.fontSize!;
      content = Container(
        margin: EdgeInsets.only(
          left: size * 1.15,
          right: size * 1.1,
        ), // off-scale: quote block
        padding: EdgeInsets.only(
          left: size + 8,
          top: 2,
          bottom: 2,
        ), // off-scale: as above
        decoration: quoteBlockDecoration(appearance.colors.surface),
        child: text,
      );
    } else if (block.type == BlockType.code) {
      content = Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: codeBlockDecoration(
          surface: appearance.colors.surface,
          border: appearance.colors.border,
        ),
        child: text,
      );
    }

    final heading =
        block.type == BlockType.h1 ||
        block.type == BlockType.h2 ||
        block.type == BlockType.h3;
    content = Padding(
      padding: EdgeInsets.only(
        top: heading ? 10 : 2,
        bottom: 2,
      ), // off-scale: note text and change marks
      child: content,
    );
    if (kind == ChangeKind.same) {
      return Semantics(
        label: block.type == BlockType.check
            ? (block.done
                  ? context.l10n.diffCheckedMark
                  : context.l10n.diffUncheckedMark)
            : null,
        child: content,
      );
    }

    final (fill, spokenLabel) = switch (kind) {
      ChangeKind.added => (colors.addedLine, context.l10n.diffAddedMark),
      ChangeKind.removed => (colors.removedLine, context.l10n.diffRemovedMark),
      _ => (
        appearance.colors.surface.withValues(alpha: 0.75),
        context.l10n.diffChangedMark,
      ),
    };
    return ChangeMarker(
      fill: fill,
      label: spokenLabel,
      bandTop: heading ? 8 : 0,
      child: content,
    );
  }
}

/// A tinted band behind a changed line, a little wider than the line.
class ChangeMarker extends StatelessWidget {
  const ChangeMarker({
    super.key,
    required this.fill,
    required this.label,
    this.bandTop = 0,
    required this.child,
  });

  final Color fill;

  /// Read before the line, such as "Added:".
  final String label;

  /// Where the band starts, below the top of [child].
  final double bandTop;
  final Widget child;

  static const double reach = AnchorTokens.space8;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -reach,
            right: -reach,
            top: bandTop,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(
                  AnchorTokens.radiusXs, // off-scale: the change band
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
