import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/motion/springs.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../core/widgets/selection_ring.dart';
import '../../../../core/widgets/shimmer.dart';
import '../../../../core/widgets/trailing_wrap.dart';
import '../../../../l10n/l10n.dart';
import '../../../tags/domain/tag.dart';
import '../../data/repository/attachment_file_provider.dart';
import '../../domain/note.dart';
import '../note_labels.dart';
import 'card_body.dart';
import 'note_chips.dart';
import 'note_surface.dart';

class NoteCardContent extends StatelessWidget {
  const NoteCardContent({
    super.key,
    required this.note,
    required this.tags,
    required this.appearance,
    required this.layout,
    required this.status,
    required this.isSelected,
    this.check,
  });

  final Note note;
  final List<Tag> tags;
  final NoteAppearance appearance;
  final CardLayout layout;
  final String? status;
  final bool isSelected;

  final Widget? check;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final list = layout == CardLayout.list;
    final previews = note.imagePreviewData;
    final radius = BorderRadius.circular(AnchorTokens.radiusCard);
    final density = context.density;
    // The first line keeps clear of the selection check over it.
    final checkInset = check != null && (list || previews.isEmpty)
        ? AnchorTokens.space24
        : 0.0;

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: density.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: density.space8,
        children: [
          if (note.hasTitle)
            Padding(
              padding: EdgeInsets.only(right: checkInset),
              child: Text(
                note.title,
                maxLines: list ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: context.noteTypography.cardTitle
                    .withSize(AnchorTokens.typeUi.fontSize!)
                    .copyWith(color: colors.appText, height: 1.3),
              ),
            ),
          CardBody(
            content: note.content,
            hideCompleted: note.noteType == NoteType.checklist,
            appearance: appearance,
            layout: layout,
            firstLineEndInset: note.hasTitle ? 0 : checkInset,
          ),
          if (list)
            _Footer(
              note: note,
              appearance: appearance,
              status: status,
              showDate: true,
              tags: tags,
            )
          else ...[
            if (tags.isNotEmpty) _Tags(tags: tags, appearance: appearance),
            _Footer(
              note: note,
              appearance: appearance,
              status: status,
              showDate: false,
            ),
          ],
        ],
      ),
    );

    Widget body;
    if (list) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (previews.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AnchorTokens.radiusLg),
                child: SizedBox.square(
                  dimension: 52, // off-scale: the list card's picture
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _Thumbnail(
                        preview: previews.first,
                        appearance: appearance,
                      ),
                      if (note.attachmentCount > 1)
                        Positioned(
                          right: 3, // off-scale: picture count
                          bottom: 3, // off-scale: as above
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: AnchorTokens.colorMediaShadeStrong,
                              borderRadius: BorderRadius.circular(
                                AnchorTokens.radiusPill,
                              ),
                            ),
                            child: Text(
                              '+${note.attachmentCount - 1}',
                              style: AppTypography.footnote.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AnchorTokens.colorMediaText,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: content),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (previews.isNotEmpty)
            _Pictures(
              previews: previews,
              fileCount: note.attachmentCount,
              appearance: appearance,
              grid: layout == CardLayout.grid,
            ),
          content,
        ],
      );
    }

    return SelectionRing(
      isShown: isSelected,
      borderRadius: radius,
      gap: colors.appPage,
      child: AnimatedContainer(
        duration: context.motion(AnchorTokens.motionDurationFade),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: isSelected ? const [] : colors.shadowXs,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: NoteSurface(
            appearance: appearance,
            child: Stack(
              children: [
                body,
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: isSelected ? 0 : 1,
                      duration: context.motion(AnchorTokens.motionDurationFade),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(color: appearance.colors.border),
                        ),
                      ),
                    ),
                  ),
                ),
                if (check != null)
                  Positioned(
                    top: 9, // off-scale: card check
                    right: 9, // off-scale: as above
                    child: check!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tags extends StatelessWidget {
  const _Tags({required this.tags, required this.appearance});

  final List<Tag> tags;
  final NoteAppearance appearance;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5, // off-scale: card chips
      runSpacing: 5, // off-scale: card chips
      children: [
        for (final t in tags.take(3))
          TagChip(tag: t, appearance: appearance, isSmall: true),
        if (tags.length > 3)
          MoreChip(count: tags.length - 3, appearance: appearance),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.note,
    required this.appearance,
    required this.status,
    required this.showDate,
    this.tags = const [],
  });

  final Note note;
  final NoteAppearance appearance;
  final String? status;
  final bool showDate;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    final muted = appearance.colors.muted;
    final style = AppTypography.footnote.copyWith(color: muted);
    final items = <Widget>[
      if (tags.isNotEmpty)
        Padding(
          padding: const EdgeInsetsDirectional.only(end: AnchorTokens.space4),
          child: _Tags(tags: tags, appearance: appearance),
        ),
      if (!note.isSynced)
        Tooltip(
          message: context.l10n.cardNotSynced,
          child: Icon(
            LucideIcons.cloudOff,
            size: 13, // off-scale: card footer
            color: muted,
          ),
        ),
      if (note.reminder != null)
        ReminderChip(
          reminder: note.reminder!,
          appearance: appearance,
          isSmall: true,
        ),
      if (note.sharedBy != null)
        Semantics(
          label: context.l10n.shareSharedBy(note.sharedBy!.name),
          child: PersonAvatar(
            name: note.sharedBy!.name,
            imageUrl: note.sharedBy!.profileImage,
            size: PersonAvatar.inline,
            ring: appearance.colors.bg,
          ),
        ),
      if (note.isOwner && note.hasShares)
        Semantics(
          label: context.l10n.shareSharedWithCount(note.shareIds!.length),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.users,
                  size: 13, // off-scale: card footer
                  color: muted,
                ),
                const SizedBox(width: 3),
                Text(
                  '${note.shareIds!.length}',
                  style: style.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
    ];
    final date =
        status ??
        (showDate && note.updatedAt != null
            ? shortDayLabel(note.updatedAt!.toLocal(), context.l10n)
            : null);
    if (items.isEmpty && date == null) return const SizedBox.shrink();
    return TrailingWrap(
      spacing: 6, // off-scale: card footer
      runSpacing: 4,
      trailing: date == null ? null : Text(date, style: style),
      children: items,
    );
  }
}

class _Pictures extends StatelessWidget {
  const _Pictures({
    required this.previews,
    required this.fileCount,
    required this.appearance,
    required this.grid,
  });

  final List<NoteImagePreview> previews;
  final int fileCount;
  final NoteAppearance appearance;
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final shown = previews
        .take(grid ? 1 : context.density.previewPictures)
        .toList();
    final extra = fileCount - shown.length;
    Widget tile(int i, double ratio) => AspectRatio(
      aspectRatio: ratio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Thumbnail(preview: shown[i], appearance: appearance),
          if (i == shown.length - 1 && extra > 0)
            ColoredBox(
              color: AnchorTokens.colorMediaShade,
              child: Center(
                child: Text(
                  '+$extra',
                  style: AppTypography.row.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AnchorTokens.colorMediaText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    const gap = 2.0;
    switch (shown.length) {
      case 1:
        return tile(0, grid ? 2 : 16 / 10);
      case 2:
        return Row(
          children: [
            Expanded(child: tile(0, 1)),
            const SizedBox(width: gap),
            Expanded(child: tile(1, 1)),
          ],
        );
      case 3:
        return Column(
          children: [
            tile(0, 2),
            const SizedBox(height: gap),
            Row(
              children: [
                Expanded(child: tile(1, 1)),
                const SizedBox(width: gap),
                Expanded(child: tile(2, 1)),
              ],
            ),
          ],
        );
      default:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: tile(0, 1)),
                const SizedBox(width: gap),
                Expanded(child: tile(1, 1)),
              ],
            ),
            const SizedBox(height: gap),
            Row(
              children: [
                Expanded(child: tile(2, 1)),
                const SizedBox(width: gap),
                Expanded(child: tile(3, 1)),
              ],
            ),
          ],
        );
    }
  }
}

class _Thumbnail extends ConsumerWidget {
  const _Thumbnail({required this.preview, required this.appearance});

  final NoteImagePreview preview;
  final NoteAppearance appearance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(attachmentFileProvider(previewFileKeyOf(preview)));
    final path = loaded.value;
    final missing = Center(
      child: Icon(
        LucideIcons.imageOff,
        size: AnchorTokens.sizeIconMedium,
        color: appearance.colors.muted,
      ),
    );
    return ColoredBox(
      color: appearance.colors.surface,
      child: path != null
          ? Image.file(
              File(path),
              fit: BoxFit.cover,
              cacheWidth: 400,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, sync) => sync
                  ? child
                  : AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: context.motion(AnchorTokens.motionDurationSlow),
                      child: child,
                    ),
              errorBuilder: (_, _, _) => missing,
            )
          : loaded.isLoading
          ? Shimmer(color: appearance.colors.border.withValues(alpha: 0.6))
          : missing,
    );
  }
}
