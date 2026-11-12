import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/motion/reorder_animation.dart';
import '../../../core/motion/springs.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/bar_title.dart';
import '../../../core/widgets/selection_bar.dart';
import '../../../l10n/l10n.dart';
import '../../reminders/data/reminder_permissions.dart';
import '../../reminders/presentation/reminder_permission_prompt.dart';
import '../../sync/data/sync_manager.dart';
import '../../sync/presentation/sync_warning.dart';
import '../../tags/domain/tag.dart';
import '../../tags/presentation/tags_controller.dart';
import '../../tags/presentation/widgets/tag_sheets.dart';
import '../domain/note.dart';
import '../domain/note_dates.dart';
import 'note_actions.dart';
import 'note_folder.dart';
import 'note_labels.dart';
import 'notes_controller.dart';
import 'notes_list_controller.dart';
import 'notes_view_options.dart';
import 'widgets/app_drawer.dart';
import 'widgets/card_body.dart';
import 'widgets/card_registry.dart';
import 'widgets/drawer_host.dart';
import 'widgets/list_title.dart';
import 'widgets/note_card.dart';
import 'widgets/note_cards_loading.dart';
import 'widgets/note_surface.dart';
import 'widgets/notes_board.dart';
import 'widgets/notes_bottom_bar.dart';
import 'widgets/pull_to_refresh.dart';
import 'widgets/view_options_sheet.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _scroll = ScrollController();
  final _scrollKey = GlobalKey();
  final _drawerKey = GlobalKey<DrawerHostState>();
  final _reorderPositions = ReorderPositions();
  final _isBottomBarCompact = ValueNotifier(false);
  double _scrollDistance = 0;
  bool _searching = false;

  NoteSelection get _selection => NoteSelection(ref);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NoteSurfacePainter.precachePatterns(context);
    });
    ref.listenManual(
      shouldAskForReminderPermissionsProvider,
      (_, shouldAsk) => _askForReminderPermissions(shouldAsk),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _isBottomBarCompact.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollUpdateNotification update) {
    final metrics = update.metrics;
    if (update.depth != 0 || metrics.axis != Axis.vertical || _searching) {
      return false;
    }
    if (metrics.pixels < 40) {
      _scrollDistance = 0;
      _isBottomBarCompact.value = false;
      return false;
    }
    final delta = update.scrollDelta ?? 0;
    if (delta == 0 || metrics.outOfRange) return false;
    _scrollDistance = delta.sign == _scrollDistance.sign
        ? _scrollDistance + delta
        : delta;
    if (_scrollDistance > 4) {
      _isBottomBarCompact.value = true;
    } else if (_scrollDistance < -4) {
      _isBottomBarCompact.value = false;
    }
    return false;
  }

  void _askForReminderPermissions(bool shouldAsk) {
    final controller = ref.read(reminderPermissionsControllerProvider.notifier);
    if (!shouldAsk || controller.wasPromptedThisRun) return;
    controller.wasPromptedThisRun = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ensureReminderPermissions(
          context,
          ref,
          trigger: ReminderPermissionTrigger.synced,
        );
      }
    });
  }

  void _endSearch() {
    setState(() => _searching = false);
    ref.read(searchQueryProvider.notifier).set('');
  }

  Future<void> _runOnSelection(
    NoteAction action,
    List<Note> selectedNotes,
    VisibleNotes shown,
  ) async {
    if (selectedNotes.isEmpty) return;
    if (action == NoteAction.tag) {
      await showTagPicker(context, selectedNotes);
      _selection.end();
      return;
    }
    final fadeOut = context.motion(AnchorTokens.motionDurationExit);
    final leaving = _leavingAfter(action, selectedNotes, shown);
    await NoteActions(context, ref).run(
      action,
      selectedNotes,
      beforeChange: () async {
        _selection.end();
        if (leaving.isEmpty) return;
        CardRegistry.leave(leaving);
        await Future<void>.delayed(fadeOut);
      },
    );
  }

  /// The notes [action] takes off the list.
  List<String> _leavingAfter(
    NoteAction action,
    List<Note> selectedNotes,
    VisibleNotes shown,
  ) {
    if (action == NoteAction.pin) return const [];
    if (action != NoteAction.archive) {
      return [for (final note in selectedNotes) note.id];
    }
    if (selectedNotes.every((note) => note.isArchived)) return const [];
    final selectedIds = {for (final note in selectedNotes) note.id};
    final hasOtherNotes = shown.notes.any(
      (note) => !note.isArchived && !selectedIds.contains(note.id),
    );
    if (shown.showsArchived(hasOtherNotes: hasOtherNotes)) return const [];
    return [
      for (final note in selectedNotes)
        if (!note.isArchived) note.id,
    ];
  }

  void _open(Note note) {
    if (_searching) FocusScope.of(context).unfocus();
    context.go(AppRoutes.note(note.id), extra: note);
  }

  void _newNote() => context.go(AppRoutes.newNote);

  void _openSettings() => context.push(AppRoutes.settings);

  @override
  Widget build(BuildContext context) {
    final folder = ref.watch(noteFolderProvider);
    final shown = ref.watch(visibleNotesProvider);
    final visible = shown.notes;
    final shownIds = {for (final note in visible) note.id};
    if (CardRegistry.leaving.value.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => CardRegistry.forgetLeavingExcept(shownIds),
      );
    }
    final firstDownload = ref.watch(firstDownloadProvider);
    final isLoading =
        !shown.isLoaded ||
        (visible.isEmpty && firstDownload == FirstDownload.running);
    final allTags = ref.watch(tagsControllerProvider).value ?? const <Tag>[];
    final tagsById = {for (final t in allTags) t.id: t};
    final tagId = folder == NoteFolder.notes
        ? ref.watch(selectedTagFilterProvider)
        : null;
    final tag = tagId == null ? null : tagsById[tagId];
    _reorderPositions.keepShown((folder, tagId), shownIds);
    final isSelecting = ref.watch(selectionModeProvider);
    final selectedIds = ref.watch(selectedNoteIdsProvider);
    final options =
        ref.watch(notesViewOptionsProvider).value ?? const NotesViewOptions();
    final query = ref.watch(searchQueryProvider);
    final selectedNotes = visible
        .where((n) => selectedIds.contains(n.id))
        .toList();
    final layout = switch (options.viewType) {
      ViewType.masonry => CardLayout.masonry,
      ViewType.grid => CardLayout.grid,
      ViewType.list => CardLayout.list,
    };
    void openMenu() => _drawerKey.currentState?.open();
    void clearTag() => ref.read(selectedTagFilterProvider.notifier).clear();

    final actions = <Widget>[
      if (isSelecting)
        BarTextButton(
          label:
              selectedNotes.length == visible.length && selectedNotes.isNotEmpty
              ? context.l10n.commonDeselectAll
              : context.l10n.commonSelectAll,
          onPressed: () => _selection.toggleAll(visible),
        )
      else ...[
        if (folder == NoteFolder.trash)
          BarButton(
            icon: LucideIcons.ellipsis,
            label: context.l10n.commonMore,
            onPressed: () => NoteActions(context, ref).emptyTrash(),
          )
        else
          BarButton(
            icon: options.viewType == ViewType.list
                ? LucideIcons.rows3
                : LucideIcons.layoutGrid,
            label: context.l10n.listViewOptions,
            onPressed: () => showViewOptionsSheet(context),
          ),
      ],
    ];

    Widget card(Note note, int index) => ReorderAnimatedBox(
      key: ValueKey(note.id),
      id: note.id,
      memory: _reorderPositions,
      child: NoteCard(
        note: note,
        tags: tagsByName(note.tagIds, tagsById),
        layout: layout,
        isSelecting: isSelecting,
        isSelected: selectedIds.contains(note.id),
        index: index,
        status: folder == NoteFolder.trash
            ? trashDaysLeftLabel(note.updatedAt, context.l10n)
            : null,
        onTap: () => isSelecting ? _selection.toggle(note) : _open(note),
        onLongPress: () =>
            isSelecting ? _selection.toggle(note) : _selection.start(note),
      ),
    );

    final page = AppScaffold(
      title: tag == null ? folder.titleIn(context.l10n) : '#${tag.name}',
      isTall: true,
      largeTitle: isSelecting
          ? null
          : ListLargeTitle(folder: folder, tag: tag, onOpenMenu: openMenu),
      barTitle: isSelecting
          ? Semantics(
              liveRegion: true,
              child: BarTitle(
                selectedNotes.isEmpty
                    ? context.l10n.notesSelectTitle
                    : context.l10n.commonSelectedCount(selectedNotes.length),
              ),
            )
          : ListBarTitle(folder: folder, tag: tag, onOpenMenu: openMenu),
      leading: isSelecting
          ? BarButton(
              icon: LucideIcons.x,
              label: context.l10n.commonCancel,
              onPressed: _selection.end,
            )
          : null,
      showBack: false,
      actions: actions,
      controller: _scroll,
      scrollKey: _scrollKey,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      refreshSliver: isSelecting || _searching
          ? null
          : PullToRefresh(
              isOnline: () => ref.read(isOnlineProvider),
              onSync: () =>
                  ref.read(syncManagerProvider.notifier).requestSync(),
            ),
      slivers: [
        NotesBoard(
          groups: shown.groups,
          layout: layout,
          generation: Object.hashAll([
            folder,
            layout,
            tagId,
            query,
            ...visible.map((n) => n.id),
            ...visible.map((n) => n.isPinned),
            ...visible.map((n) => n.isArchived),
          ]),
          contentKey: _scrollKey,
          cardBuilder: card,
          onToggleFold: tagId == null
              ? null
              : () => ref.read(openArchivedTagsProvider.notifier).toggle(tagId),
          header: [
            if (folder == NoteFolder.notes)
              SliverToBoxAdapter(
                child: SyncWarning(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    context.density.space8,
                    16,
                    context.density.space8,
                  ),
                ),
              ),
          ],
          empty: isLoading
              ? NoteCardsLoading(layout: layout)
              : visible.isEmpty
              ? firstDownload == FirstDownload.done
                    ? _empty(folder, query, tag)
                    : _notDownloaded(firstDownload)
              : null,
        ),
      ],
      bottomBarFollowsKeyboard: _searching,
      bottomBar: SelectionBarSwitcher(
        isSelecting: isSelecting,
        bottomBar: ValueListenableBuilder<bool>(
          valueListenable: _isBottomBarCompact,
          builder: (context, isCompact, _) => NotesBottomBar(
            placeholder: tag != null
                ? context.l10n.searchTag(tag.name)
                : folder.searchHintIn(context.l10n),
            compact: isCompact,
            searching: _searching,
            query: query,
            onStartSearch: () => setState(() => _searching = true),
            onQuery: (q) => ref.read(searchQueryProvider.notifier).set(q),
            onCancel: _endSearch,
            onNewNote: folder == NoteFolder.notes ? _newNote : null,
            newNoteKey: CardRegistry.newNoteButton,
          ),
        ),
        selectionBar: SelectionBar(
          enabled: selectedNotes.isNotEmpty,
          actions: [
            for (final action in folder.selectionActions)
              if (action.iconAndLabelFor(selectedNotes, context.l10n)
                  case final appearance)
                SelectionAction(
                  icon: appearance.icon,
                  label: appearance.label,
                  isDanger: action.isDanger,
                  onPressed: () =>
                      _runOnSelection(action, selectedNotes, shown),
                ),
          ],
        ),
      ),
    );

    return PopScope(
      canPop:
          !isSelecting &&
          !_searching &&
          folder == NoteFolder.notes &&
          tagId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // The drawer closes itself.
        if (_drawerKey.currentState?.isCovered ?? false) return;
        if (isSelecting) return _selection.end();
        if (_searching) return _endSearch();
        if (tagId != null) return clearTag();
        ref.read(noteFolderProvider.notifier).go(NoteFolder.notes);
      },
      child: DrawerHost(
        key: _drawerKey,
        canSwipeOpen: !isSelecting,
        drawerBuilder: (close) => AppDrawer(
          onClose: close,
          onOpenSettings: _openSettings,
          onOpenList: () {
            if (_searching) _endSearch();
          },
        ),
        child: NotificationListener<ScrollUpdateNotification>(
          onNotification: _onScroll,
          child: page,
        ),
      ),
    );
  }

  Widget _notDownloaded(FirstDownload firstDownload) {
    final l10n = context.l10n;
    final canRetry = firstDownload == FirstDownload.failed;
    return AppEmptyState(
      kind: EmptyStateKind.loadFailed,
      title: l10n.notesLoadFailedTitle,
      message: canRetry ? l10n.notesLoadFailedHelp : l10n.notesLoadPausedHelp,
      action: canRetry
          ? AppButton(
              label: l10n.commonTryAgain,
              isExpanded: false,
              onPressed: () =>
                  ref.read(syncManagerProvider.notifier).requestSync(),
            )
          : null,
    );
  }

  Widget _empty(NoteFolder folder, String query, Tag? tag) {
    final l10n = context.l10n;
    if (query.trim().isNotEmpty) {
      return AppEmptyState(
        kind: EmptyStateKind.search,
        title: l10n.searchNoResults(query.trim()),
        message: l10n.searchNoResultsHelp,
      );
    }
    return switch (folder) {
      NoteFolder.archive => AppEmptyState(
        kind: EmptyStateKind.archive,
        title: l10n.archiveEmptyTitle,
        message: l10n.archiveEmptyHelp,
      ),
      NoteFolder.trash => AppEmptyState(
        kind: EmptyStateKind.trash,
        title: l10n.trashEmptyStateTitle,
        message: l10n.trashEmpty(trashDays),
      ),
      NoteFolder.notes => AppEmptyState(
        title: tag != null
            ? l10n.tagEmptyTitle(tag.name)
            : l10n.notesEmptyTitle,
        message: tag != null ? l10n.tagEmptyHelp : l10n.notesEmptyHelp,
        action: AppButton(
          label: l10n.noteNew,
          icon: LucideIcons.plus,
          isExpanded: false,
          onPressed: _newNote,
        ),
      ),
    };
  }
}
