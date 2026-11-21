import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/motion/haptics.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/session/active_user_id_provider.dart';
import '../../../core/text/date_formats.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/bar_title.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/notice.dart';
import '../../../core/widgets/person_avatar.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/l10n.dart';
import '../data/repository/note_history_repository.dart';
import '../data/repository/note_revisions_store.dart';
import '../domain/note_dates.dart';
import '../domain/note_history.dart';
import '../domain/note_revision.dart';
import '../domain/user_summary.dart';
import 'note_history_controller.dart';
import 'note_labels.dart';
import 'notes_controller.dart';
import 'widgets/diff_bar.dart';
import 'widgets/note_surface.dart';

class NoteHistoryScreen extends ConsumerStatefulWidget {
  const NoteHistoryScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteHistoryScreen> createState() => _NoteHistoryScreenState();
}

class _NoteHistoryScreenState extends ConsumerState<NoteHistoryScreen> {
  final _scroll = ScrollController();
  bool _fetching = false;
  bool _fetchQueued = false;
  bool _failed = false;

  NoteHistoryPosition? get _position =>
      ref.read(noteHistoryPositionProvider(widget.noteId)).value;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onPosition(
    NoteHistoryPosition? previous,
    NoteHistoryPosition position,
  ) {
    final wentStale = previous != null && previous.isRead && !position.isRead;
    if ((previous == null || wentStale) && !position.isComplete) {
      unawaited(_fetch());
    }
  }

  void _onScroll() {
    if (_failed || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels > position.maxScrollExtent - 300) unawaited(_fetch());
  }

  Future<void> _fetch({bool force = false}) async {
    if (_fetching) {
      _fetchQueued = true;
      return;
    }
    if (!force && (_position?.isComplete ?? false)) return;
    if (!ref.read(isOnlineProvider)) return;
    setState(() {
      _fetching = true;
      _failed = false;
    });
    try {
      await ref.read(noteHistoryRepositoryProvider).fetch(widget.noteId);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _fetching = false);
      if (_fetchQueued) {
        _fetchQueued = false;
        if (mounted) unawaited(_fetch());
      }
    }
  }

  Future<void> _retry() async {
    Haptics.selection();
    await ref.read(noteRevisionsStoreProvider).markStale(widget.noteId);
    await _fetch(force: true);
    if (mounted && !_failed) Haptics.success();
  }

  Future<void> _open(String id) async {
    Haptics.selection();
    final restored = await context.push<RestoredVersion>(
      AppRoutes.revision(widget.noteId, id),
    );
    if (restored != null && mounted) context.pop(restored);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(isOnlineProvider, (was, now) {
      if (now && was != true) unawaited(_failed ? _retry() : _fetch());
    });
    ref.listen(noteHistoryPositionProvider(widget.noteId), (previous, next) {
      if (next.value case final position?) {
        _onPosition(previous?.value, position);
      }
    });
    final colors = context.anchor;
    final density = context.density;
    final note = ref.watch(noteProvider(widget.noteId)).value;
    final revisions =
        ref.watch(noteRevisionsProvider(widget.noteId)).value ?? const [];
    final changes = ref.watch(versionChangesProvider(widget.noteId));
    final online = ref.watch(isOnlineProvider);
    final appearance = NoteAppearance.of(context, note?.background);
    final showsAuthors = historyHasMultipleAuthors(revisions);
    final me = ref.watch(activeUserIdProvider);
    final days = groupRevisionsByDay(revisions);
    final l10n = context.l10n;
    final now = DateTime.now();

    Widget versionRow(NoteRevision revision) {
      final counts = changes
          .of(revisions, revision, note)
          .lineCountsFrom(revision.title);
      final showsAuthor = showsAuthors || revision.author != null;
      final authorName = revisionAuthorName(revision, me, l10n);
      final cause = revision.cause == RevisionCause.edit
          ? null
          : revisionLabel(revision.cause, l10n);
      final spokenCounts = [
        if (counts.added > 0) l10n.diffAdded(counts.added),
        if (counts.removed > 0) l10n.diffRemoved(counts.removed),
        if (counts.changed > 0) l10n.diffChanged(counts.changed),
      ];
      return _VersionRow(
        author: revision.author,
        time: clockLabel(revision.createdAtLocal),
        cause: cause,
        isWarning: revision.cause == RevisionCause.conflict,
        summary: l10n.joinDetails([
          if (showsAuthor) authorName,
          lineChangesLabel(counts, l10n),
        ]),
        counts: counts,
        semanticLabel: l10n.joinList([
          dayTimeLabel(revision.createdAtLocal, l10n, now: now),
          if (showsAuthor) authorName,
          ?cause,
          spokenCounts.isEmpty
              ? l10n.historyNoChanges
              : l10n.joinList(spokenCounts),
        ]),
        onTap: () => _open(revision.id),
      );
    }

    final complete =
        ref
            .watch(noteHistoryPositionProvider(widget.noteId))
            .value
            ?.isComplete ??
        false;
    return AppScaffold(
      title: l10n.actionHistory,
      background: PageBackground.gradient,
      controller: _scroll,
      titleLine: BarTitleLine(
        displayTitleOf(note?.title ?? '', l10n),
        leading: Container(
          width: 12, // off-scale: a swatch of the note's color
          height: 12, // off-scale: as above
          decoration: BoxDecoration(
            color: appearance.colors.bg,
            borderRadius: BorderRadius.circular(4), // off-scale: as above
            border: Border.all(color: appearance.colors.border),
          ),
        ),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, density.space16, 16, 0),
          sliver: SliverList.list(
            children: [
              GroupedList(
                children: [
                  _CurrentVersionRow(
                    subtitle: note?.updatedAt == null
                        ? l10n.historySavedOnPhone
                        : editedTimeLabel(note!.updatedAt!, l10n),
                    onTap: () => _open(currentVersionId),
                  ),
                ],
              ),
              for (final day in days) ...[
                SizedBox(height: Section.gapOf(context)),
                Section(
                  label: dayLabel(day.date, now, l10n),
                  child: GroupedList(
                    children: [
                      for (final revision in day.revisions)
                        versionRow(revision),
                    ],
                  ),
                ),
              ],
              if (revisions.isEmpty && !_fetching)
                AppEmptyState(
                  kind: EmptyStateKind.history,
                  title: l10n.historyEmptyTitle,
                  message: l10n.historyKept(historyDays),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                ),
              SizedBox(height: Section.gapOf(context)),
              if (_fetching)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: Spinner()),
                )
              else if (_failed)
                Notice(
                  kind: NoticeKind.warn,
                  icon: LucideIcons.cloudAlert,
                  text: l10n.historyFetchFailed,
                  action: AppButton(
                    label: l10n.commonTryAgain,
                    kind: AppButtonKind.secondary,
                    isExpanded: false,
                    size: AppButtonSize.small,
                    onPressed: _retry,
                  ),
                )
              else if (!online)
                Notice(icon: LucideIcons.cloudOff, text: l10n.historyOffline),
              if (revisions.isNotEmpty && (complete || !online))
                Padding(
                  padding: EdgeInsets.only(top: density.space16),
                  child: Text(
                    l10n.historyLimit(historyDays),
                    textAlign: TextAlign.center,
                    style: AppTypography.footnote.copyWith(
                      color: colors.appMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A tappable row: a mark, two lines of text, then [trailing] before the
/// chevron.
class _HistoryRow extends GroupedListRow {
  const _HistoryRow({
    required this.mark,
    required this.title,
    required this.subtitle,
    required this.semanticLabel,
    required this.onTap,
    this.trailing,
  });

  /// [PersonAvatar.list] wide.
  final Widget mark;
  final Widget title;
  final String subtitle;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget? trailing;

  static const double textStart =
      GroupedListTile.inset + PersonAvatar.list + AnchorTokens.space12;

  @override
  double get dividerStart => textStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final density = context.density;
    return Pressable(
      style: PressStyle.row,
      onTap: onTap,
      semanticLabel: semanticLabel,
      tintRadius: BorderRadius.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: density.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GroupedListTile.inset,
          ),
          child: Row(
            spacing: AnchorTokens.space12,
            children: [
              mark,
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: density.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      title,
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.secondary.copyWith(
                          color: colors.appMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ?trailing,
              Icon(
                LucideIcons.chevronRight,
                size: AnchorTokens.sizeIconSmall,
                color: colors.appMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentVersionRow extends GroupedListRow {
  const _CurrentVersionRow({required this.subtitle, required this.onTap});

  final String subtitle;
  final VoidCallback onTap;

  @override
  double get dividerStart => _HistoryRow.textStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final label = context.l10n.historyCurrent;
    return _HistoryRow(
      mark: Container(
        width: PersonAvatar.list,
        height: PersonAvatar.list,
        decoration: BoxDecoration(
          color: colors.accentStrong.withValues(
            alpha: context.isDark ? 0.2 : 0.14,
          ),
          borderRadius: BorderRadius.circular(
            AnchorTokens.radiusSm, // off-scale: the mark's corner
          ),
        ),
        child: Icon(
          LucideIcons.penLine,
          size: AnchorTokens.sizeIconSmall,
          color: colors.accentInk,
        ),
      ),
      title: Text(
        label,
        style: AppTypography.row.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.appText,
        ),
      ),
      subtitle: subtitle,
      semanticLabel: label,
      onTap: onTap,
    );
  }
}

class _VersionRow extends GroupedListRow {
  const _VersionRow({
    required this.author,
    required this.time,
    required this.cause,
    required this.isWarning,
    required this.summary,
    required this.counts,
    required this.semanticLabel,
    required this.onTap,
  });

  final UserSummary? author;
  final String time;
  final String? cause;
  final bool isWarning;
  final String summary;
  final LineCounts counts;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  double get dividerStart => _HistoryRow.textStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final author = this.author;
    final cause = this.cause;
    return _HistoryRow(
      mark: author == null
          ? Container(
              width: PersonAvatar.list,
              height: PersonAvatar.list,
              decoration: BoxDecoration(
                color: colors.appText.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.user,
                size: AnchorTokens.sizeIconSmall,
                color: colors.appMuted,
              ),
            )
          : PersonAvatar(
              name: author.name,
              imageUrl: author.profileImage,
              size: PersonAvatar.list,
            ),
      title: Row(
        spacing: AnchorTokens.space8,
        children: [
          Text(
            time,
            style: AppTypography.row.tabular.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.appText,
            ),
          ),
          if (cause != null)
            Flexible(
              child: _CauseTag(label: cause, isWarning: isWarning),
            ),
        ],
      ),
      subtitle: summary,
      semanticLabel: semanticLabel,
      onTap: onTap,
      trailing: DiffBar(counts),
    );
  }
}

class _CauseTag extends StatelessWidget {
  const _CauseTag({required this.label, required this.isWarning});

  final String label;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return Container(
      constraints: const BoxConstraints(minHeight: 20), // off-scale: a badge
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isWarning
            ? colors.statusWarnFill
            : colors.appMuted.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AnchorTokens.radiusPill),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.footnote.copyWith(
            fontWeight: FontWeight.w600,
            color: isWarning ? colors.statusWarnText : colors.appText,
          ),
        ),
      ),
    );
  }
}
