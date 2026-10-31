import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/motion/springs.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/check_circle.dart';
import '../../../../l10n/l10n.dart';
import '../../../reminders/presentation/reminder_labels.dart';
import '../../../tags/domain/tag.dart';
import '../../domain/checklist_task.dart';
import '../../domain/note.dart';
import '../../domain/note_blocks.dart';
import '../note_labels.dart';
import 'card_body.dart';
import 'card_registry.dart';
import 'note_card_content.dart';
import 'note_surface.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.tags,
    this.layout = CardLayout.masonry,
    this.isSelecting = false,
    this.isSelected = false,
    this.index = 0,
    this.status,
    this.onTap,
    this.onLongPress,
  });

  final Note note;

  final List<Tag> tags;
  final CardLayout layout;
  final bool isSelecting;
  final bool isSelected;

  final int index;

  /// Replaces the date, like "29 days left" in Trash.
  final String? status;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    value: 1,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _pressTo(double scale) {
    if (context.isMotionReduced) return;
    _press.springTo(scale, spring: Spring.snappy);
  }

  void _release() {
    if (context.isMotionReduced) return;
    _press.springTo(1, spring: Spring.snappy);
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final appearance = NoteAppearance.of(context, note.background);
    final isChecklist = note.noteType == NoteType.checklist;
    final snippet = snippetTextOf(note.content, hideCompleted: isChecklist);
    final progress = isChecklist
        ? ChecklistProgress.fromContent(note.content)
        : null;
    final l10n = context.l10n;
    final reminder = note.reminder;
    final date =
        widget.status ??
        (widget.layout == CardLayout.list && note.updatedAt != null
            ? shortDayLabel(note.updatedAt!.toLocal(), l10n)
            : null);
    final label = [
      if (isChecklist) l10n.noteTypeChecklist,
      displayTitleOf(note.title, l10n),
      if (progress != null)
        l10n.checklistProgressSpoken(progress.done, progress.total),
      if (snippet.isNotEmpty)
        snippet.length > 120 ? '${snippet.substring(0, 120)}…' : snippet,
      if (note.imagePreviewData.isNotEmpty)
        l10n.cardPictures(note.imagePreviewData.length),
      for (final tag in widget.tags) l10n.tagSheetLabel(tag.name),
      if (reminder != null) reminderSpokenLabel(reminder, l10n),
      if (note.sharedBy != null) l10n.shareSharedBy(note.sharedBy!.name),
      if (note.isOwner && note.hasShares)
        l10n.shareSharedWithCount(note.shareIds!.length),
      if (!note.isSynced) l10n.cardNotSynced,
      ?date,
    ].join('. ');

    final card = ValueListenableBuilder<Set<String>>(
      valueListenable: CardRegistry.leaving,
      builder: (context, leaving, child) => AnimatedOpacity(
        opacity: leaving.contains(note.id) ? 0 : 1,
        duration: context.motion(AnchorTokens.motionDurationExit),
        child: child,
      ),
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: CardRegistry.hidden,
        builder: (context, hidden, child) =>
            Opacity(opacity: hidden.contains(note.id) ? 0 : 1, child: child),
        child: RepaintBoundary(
          key: CardRegistry.keyFor(note.id),
          child: NoteCardContent(
            note: note,
            tags: widget.tags,
            appearance: appearance,
            layout: widget.layout,
            status: widget.status,
            isSelected: widget.isSelected,
            check: widget.isSelecting
                ? _SelectionCheck(
                    isSelected: widget.isSelected,
                    appearance: appearance,
                    index: widget.index,
                  )
                : null,
          ),
        ),
      ),
    );

    final gestures = <Type, GestureRecognizerFactory>{
      LongPressGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(
              duration: AnchorTokens.motionDurationLongPress,
            ),
            (recognizer) {
              recognizer.onLongPressStart = (_) {
                _release();
                widget.onLongPress?.call();
              };
            },
          ),
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            TapGestureRecognizer.new,
            (recognizer) {
              recognizer
                ..onTapDown = ((_) => _pressTo(0.97))
                ..onTapCancel = _release
                ..onTap = (() {
                  _release();
                  widget.onTap?.call();
                });
            },
          ),
    };

    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      selected: widget.isSelecting ? widget.isSelected : null,
      label: label,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: RawGestureDetector(
        gestures: gestures,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) =>
              Transform.scale(scale: _press.value, child: child),
          child: card,
        ),
      ),
    );
  }
}

class _SelectionCheck extends StatefulWidget {
  const _SelectionCheck({
    required this.isSelected,
    required this.appearance,
    required this.index,
  });

  final bool isSelected;
  final NoteAppearance appearance;
  final int index;

  @override
  State<_SelectionCheck> createState() => _SelectionCheckState();
}

class _SelectionCheckState extends State<_SelectionCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: math.min(widget.index, 12) * 18), () {
      if (mounted) _entrance.springTo(1, spring: Spring.pop);
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.4, end: 1).animate(_entrance),
      child: FadeTransition(
        opacity: _entrance.drive(
          Tween<double>(
            begin: 0,
            end: 1,
          ).chain(CurveTween(curve: const Interval(0, 0.5))),
        ),
        child: CheckCircle(
          value: widget.isSelected,
          background: widget.appearance.colors.bg,
          ringColor: widget.appearance.colors.muted,
          hasShadow: true,
        ),
      ),
    );
  }
}
