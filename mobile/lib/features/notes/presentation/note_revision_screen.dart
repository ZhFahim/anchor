import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/haptics.dart';
import '../../../core/motion/springs.dart';
import '../../../core/session/active_user_id_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/bar_title.dart';
import '../../../core/widgets/bottom_bar_frame.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/page_bar.dart';
import '../../../l10n/l10n.dart';
import '../data/repository/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_history.dart';
import '../domain/note_revision.dart';
import 'note_history_controller.dart';
import 'note_labels.dart';
import 'notes_controller.dart';
import 'widgets/note_surface.dart';
import 'widgets/version_diff_view.dart';

class NoteRevisionScreen extends ConsumerStatefulWidget {
  const NoteRevisionScreen({
    super.key,
    required this.noteId,
    required this.revisionId,
  });

  final String noteId;
  final String revisionId;

  @override
  ConsumerState<NoteRevisionScreen> createState() => _NoteRevisionScreenState();
}

class _NoteRevisionScreenState extends ConsumerState<NoteRevisionScreen> {
  PageController? _pages;
  int _index = 0;
  bool _restoring = false;

  final ValueNotifier<double> _offset = ValueNotifier(0);

  /// Lines opened from folds, by version.
  final Map<String, Set<int>> _opened = {};

  List<NoteRevision> get _revisions =>
      ref.read(noteRevisionsProvider(widget.noteId)).value ?? const [];

  Note? get _note => ref.read(noteProvider(widget.noteId)).value;

  @override
  void dispose() {
    _pages?.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _openAt(List<NoteRevision> revisions) {
    final at = widget.revisionId == currentVersionId
        ? 0
        : revisions.indexWhere((r) => r.id == widget.revisionId) + 1;
    _index = at < 0 ? 0 : at;
    _pages = PageController(initialPage: _index);
  }

  int get _count => _revisions.length + 1;

  bool get _canRestore {
    final note = _note;
    return note != null && note.isActive && note.canEdit;
  }

  void _step(int by) {
    final to = _index + by;
    final pages = _pages;
    if (pages == null || to < 0 || to >= _count) return;
    if (context.isMotionReduced) {
      pages.jumpToPage(to);
      return;
    }
    pages.animateToPage(
      to,
      duration: Spring.smooth.duration,
      curve: Spring.smooth.curve,
    );
  }

  Future<void> _restore(NoteRevision revision) async {
    final note = _note;
    if (note == null || _restoring) return;
    if (note.title == revision.title && note.content == revision.content) {
      AppSnackbar.show(
        context,
        context.l10n.revisionAlreadyMatches,
        kind: SnackbarKind.info,
      );
      return;
    }
    setState(() => _restoring = true);
    try {
      await ref
          .read(notesRepositoryProvider)
          .restoreVersion(widget.noteId, revision);
      if (!mounted) return;
      context.pop<RestoredVersion>((
        previousTitle: note.title,
        previousContent: note.content,
        revision: revision,
      ));
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          context.l10n.revisionRestoreFailed,
          kind: SnackbarKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final loaded = ref.watch(noteRevisionsProvider(widget.noteId));
    final revisions = loaded.value ?? const <NoteRevision>[];
    if (_pages == null && loaded.hasValue) _openAt(revisions);
    final note = ref.watch(noteProvider(widget.noteId)).value;
    final changes = ref.watch(versionChangesProvider(widget.noteId));
    final appearance = NoteAppearance.of(context, note?.background);
    final me = ref.watch(activeUserIdProvider);
    final current = _index == 0;
    final revision = current || _index - 1 >= revisions.length
        ? null
        : revisions[_index - 1];

    final l10n = context.l10n;
    final (barTitle, barSub) = revision == null
        ? (
            l10n.historyCurrent,
            note?.updatedAt == null
                ? ''
                : editedTimeLabel(note!.updatedAt!, l10n),
          )
        : (
            dayTimeLabel(revision.createdAtLocal, l10n),
            lineChangesLabel(
              changes
                  .of(revisions, revision, note)
                  .lineCountsFrom(revision.title),
              l10n,
            ),
          );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(child: NoteSurface(appearance: appearance)),
          if (_pages != null)
            Positioned.fill(
              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: _scrolled,
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _count,
                  onPageChanged: (i) {
                    Haptics.selection();
                    _offset.value = 0;
                    setState(() => _index = i);
                  },
                  itemBuilder: (context, i) =>
                      _page(context, i, appearance, changes, me),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: PageBar(
              color: appearance.colors.bg,
              scrollOffset: _offset,
              leading: PageBackButton(label: l10n.revisionBackToList),
              title: Semantics(
                liveRegion: true,
                child: BarTitle(
                  barTitle,
                  style: AppTypography.navTitle.tabular.copyWith(
                    color: colors.appText,
                  ),
                  line: barSub.isEmpty
                      ? null
                      : BarTitleLine(barSub, color: appearance.colors.muted),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: context.safeBottom + 8,
            child: BottomBarFrame(
              bottom: context.safeBottom + 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FrostedGlass(
                    child: SizedBox(
                      height: context.density.control,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BarButton(
                              icon: LucideIcons.chevronLeft,
                              label: l10n.revisionNewer,
                              onPressed: _index > 0 ? () => _step(-1) : null,
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 58, // off-scale: room for "12 of 12"
                              ),
                              child: Text(
                                l10n.revisionPosition(_index + 1, _count),
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                style: AppTypography.footnote.tabular.copyWith(
                                  color: colors.appMuted,
                                ),
                              ),
                            ),
                            BarButton(
                              icon: LucideIcons.chevronRight,
                              label: l10n.revisionOlder,
                              onPressed: _index < _count - 1
                                  ? () => _step(1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: context.motion(AnchorTokens.motionDurationFade),
                      child: revision != null && _canRestore
                          ? AppButton(
                              key: const ValueKey('restore'),
                              label: l10n.actionRestore,
                              busyLabel: l10n.revisionRestoring,
                              isBusy: _restoring,
                              icon: LucideIcons.rotateCcw,
                              isExpanded: false,
                              hasShadow: true,
                              onPressed: () => _restore(revision),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _scrolled(ScrollUpdateNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      _offset.value = notification.metrics.pixels;
    }
    return false;
  }

  Widget _page(
    BuildContext context,
    int i,
    NoteAppearance appearance,
    VersionChanges changes,
    String? me,
  ) {
    final themeColors = context.anchor;
    final density = context.density;
    final media = MediaQuery.of(context);
    final note = _note;
    final colors = DiffColors.of(context, appearance);
    final revisions = _revisions;
    final revision = i == 0 || i - 1 >= revisions.length
        ? null
        : revisions[i - 1];
    if (i > 0 && revision == null) {
      return Center(
        child: Text(
          context.l10n.revisionGone,
          style: AppTypography.secondary.copyWith(
            color: appearance.colors.muted,
          ),
        ),
      );
    }

    final change = revision == null
        ? null
        : changes.of(revisions, revision, note);
    final target = change?.target;
    final title = revision?.title ?? note?.title ?? '';
    final nextTitle = change?.nextTitle;
    final titleChanged = change?.isTitleChangedFrom(title) ?? false;
    final diff = change?.diff ?? changes.current(note);
    final key = revision?.id ?? 'now';
    final l10n = context.l10n;
    final meta = revision == null
        ? null
        : l10n.joinDetails([
            if (historyHasMultipleAuthors(revisions) || revision.author != null)
              revisionAuthorName(revision, me, l10n),
            if (revision.cause == RevisionCause.restore)
              revisionLabel(revision.cause, l10n),
            target == null
                ? l10n.revisionComparedCurrent
                : comparedWithLabel(target.createdAtLocal, l10n),
          ]);

    final titleStyle = context.noteTypography.versionTitle.copyWith(
      color: themeColors.appText,
    );
    final mutedStyle = AppTypography.footnote.copyWith(
      color: appearance.colors.muted,
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AnchorTokens.space16,
        media.padding.top + PageBar.heightOf(context) + density.space8,
        AnchorTokens.space16,
        context.safeBottom + density.control * 2 + AnchorTokens.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (revision?.cause == RevisionCause.conflict) ...[
            Notice(
              kind: NoticeKind.warn,
              icon: LucideIcons.triangleAlert,
              title: l10n.revisionNotSavedLead,
              text: l10n.revisionNotSavedText,
            ),
            SizedBox(height: density.space16),
          ],
          if (titleChanged)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AnchorTokens.space4,
              children: [
                ChangeMarker(
                  fill: colors.removedLine,
                  label: l10n.diffRemovedTitle,
                  child: Text(
                    displayTitleOf(title, l10n),
                    style: titleStyle.copyWith(
                      color: themeColors.appText.withValues(alpha: 0.65),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: colors.removedText,
                    ),
                  ),
                ),
                ChangeMarker(
                  fill: colors.addedLine,
                  label: l10n.diffAddedTitle,
                  child: Text(
                    displayTitleOf(nextTitle ?? '', l10n),
                    style: titleStyle,
                  ),
                ),
              ],
            )
          else
            Text(displayTitleOf(title, l10n), style: titleStyle),
          if (meta != null)
            Padding(
              padding: const EdgeInsets.only(top: AnchorTokens.space4),
              child: Text(meta, style: mutedStyle),
            ),
          SizedBox(height: density.space16),
          if (revision != null && !titleChanged && diff.isUnchanged)
            Padding(
              padding: EdgeInsets.only(bottom: density.space12),
              child: Text(
                target != null
                    ? l10n.revisionSameAsNext
                    : l10n.revisionSameAsCurrent,
                style: AppTypography.secondary.copyWith(
                  color: appearance.colors.muted,
                ),
              ),
            ),
          if (diff.lines.isEmpty)
            Text(
              l10n.revisionEmpty,
              style: AppTypography.secondary.copyWith(
                color: appearance.colors.muted,
              ),
            )
          else
            VersionDiffView(
              diff: diff,
              appearance: appearance,
              showsAllLines: revision == null,
              open: _opened[key] ?? const {},
              onOpen: (fold) => setState(() {
                (_opened[key] ??= {}).addAll([
                  for (var k = fold.from; k < fold.to; k++) k,
                ]);
              }),
            ),
        ],
      ),
    );
  }
}
