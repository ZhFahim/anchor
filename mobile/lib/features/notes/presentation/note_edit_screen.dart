import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/motion/haptics.dart';
import '../../../core/motion/springs.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/session/active_user_id_provider.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/bottom_bar_frame.dart';
import '../../../core/widgets/page_bar.dart';
import '../../../l10n/l10n.dart';
import '../../reminders/presentation/reminder_permission_prompt.dart';
import '../../reminders/presentation/reminder_sheet.dart';
import '../../settings/presentation/editor_preferences_controller.dart';
import '../../tags/domain/tag.dart';
import '../../tags/presentation/tags_controller.dart';
import '../../tags/presentation/widgets/tag_sheets.dart';
import '../data/repository/note_attachments_repository.dart';
import '../data/repository/note_shares_repository.dart';
import '../data/repository/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_attachment.dart';
import '../domain/note_history.dart';
import 'checked_folds_controller.dart';
import 'editor/editor_overlay.dart';
import 'editor/editor_overlay_controller.dart';
import 'editor/editor_palette.dart';
import 'editor/line_kind.dart';
import 'editor/rich_text_editor.dart';
import 'note_actions.dart';
import 'note_editor_controller.dart';
import 'note_labels.dart';
import 'note_morph_route.dart';
import 'widgets/add_sheet.dart';
import 'widgets/background_sheet.dart';
import 'widgets/note_attachments_strip.dart';
import 'widgets/note_bar.dart';
import 'widgets/note_header.dart';
import 'widgets/note_more_sheet.dart';
import 'widgets/note_surface.dart';
import 'widgets/read_only_bottom_bar.dart';
import 'widgets/share_sheet.dart';
import 'widgets/title_input_formatter.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  const NoteEditScreen({super.key, this.noteId, this.note});

  final String? noteId;
  final Note? note;

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final _titleFocus = FocusNode();
  final _editorFocus = FocusNode();
  final _editorKey = GlobalKey<RichTextEditorState>();
  final _scroll = ScrollController();
  final _corrections = ScrollCorrections();
  late final _scrollOffset = ScrollOffset(_scroll, corrections: _corrections);
  final _titleHistory = UndoHistoryController();
  double _readOnlyBarHeight = 0;
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: AnchorTokens.motionDurationNudge,
  );

  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: AnchorTokens.motionDurationFlash,
  );

  late final NoteEditorController _draft = NoteEditorController(
    notes: ref.read(notesRepositoryProvider),
    sharesOf: (noteId) =>
        ref.read(noteSharesRepositoryProvider).getNoteShares(noteId),
    editor: _EditorContent(_editorKey),
    newNoteTagId: () => ref.read(selectedTagFilterProvider),
    onNoteDeleted: _handleNoteDeleted,
    note: widget.note,
    noteId: widget.noteId,
  );

  late final EditorOverlayController _editorOverlay = EditorOverlayController(
    _editorKey,
  );

  late final bool _openedAsNew = widget.note == null && widget.noteId == null;
  late final ValueNotifier<bool> _showsEmptyNoteActions = ValueNotifier(
    _openedAsNew,
  );
  bool _isBodyBlank = true;

  Animation<double>? _routeAnimation;
  bool _isOpen = true;

  bool get _isReadOnly => _draft.isReadOnly;

  bool get _writing => _titleFocus.hasFocus || _editorFocus.hasFocus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _draft.addListener(_draftChanged);
    _editorOverlay.addListener(_editorOverlayChanged);
    if (_openedAsNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    }
    _titleFocus.addListener(_focusChanged);
    _editorFocus.addListener(_focusChanged);
    if (_openedAsNew) _draft.title.addListener(_updateEmptyNoteActions);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NoteMorphRoute.of(context)?.isBlank = () => _draft.isBlankNew;
    final animation = ModalRoute.of(context)?.animation;
    if (animation != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_routeChanged);
      _routeAnimation = animation?..addStatusListener(_routeChanged);
      _isOpen =
          animation == null || animation.status == AnimationStatus.completed;
    }
  }

  void _routeChanged(AnimationStatus status) {
    final isOpen = status == AnimationStatus.completed;
    if (isOpen != _isOpen) setState(() => _isOpen = isOpen);
  }

  void _updateEmptyNoteActions() => _showsEmptyNoteActions.value =
      _openedAsNew && _isBodyBlank && _draft.title.text.trim().isEmpty;

  void _bodyBlankChanged(bool isBlank) {
    _isBodyBlank = isBlank;
    _updateEmptyNoteActions();
  }

  void _draftChanged() {
    if (!mounted) return;
    setState(() {});
    final route = NoteMorphRoute.of(context);
    if (route == null) return;
    route.backgroundId = _draft.background;
    if (_draft.note?.id case final id?) route.noteId.value = id;
    NoteMorphRoute.refreshOf(context);
  }

  void _focusChanged() {
    if (_editorFocus.hasFocus || _titleFocus.hasFocus) {
      _editorOverlay.closeLink();
    }
    if (!_editorFocus.hasFocus) _editorOverlay.closeSubmenu();
    setState(() {});
  }

  void _editorOverlayChanged() => setState(() {});

  void _handleNoteDeleted() {
    AppSnackbar.show(context, context.l10n.noteGone, kind: SnackbarKind.error);
    _leave();
  }

  void _back() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.maybePop();
    } else {
      _leave();
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      _draft.flushOnLeave();
      if (context.isCupertino) {
        context.go(AppRoutes.home);
      } else {
        SystemNavigator.pop();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _draft.saveIfChanged();
    }
  }

  @override
  void deactivate() {
    _draft.flushOnLeave();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _draft.reopen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeAnimation?.removeStatusListener(_routeChanged);
    _draft.removeListener(_draftChanged);
    _draft.title.removeListener(_updateEmptyNoteActions);
    _draft.dispose();
    _showsEmptyNoteActions.dispose();
    _editorOverlay.removeListener(_editorOverlayChanged);
    _editorOverlay.dispose();
    _titleFocus.removeListener(_focusChanged);
    _editorFocus.removeListener(_focusChanged);
    _titleFocus.dispose();
    _editorFocus.dispose();
    _scroll.dispose();
    _corrections.dispose();
    _titleHistory.dispose();
    _nudge.dispose();
    _flash.dispose();
    super.dispose();
  }

  void _showBackground() {
    if (_isReadOnly) return;
    showBackgroundSheet(
      context,
      current: _draft.background,
      onChanged: _draft.setBackground,
    );
  }

  Future<void> _showReminder() async {
    if (!_draft.isActive) return;
    final previousReminder = _draft.note?.reminder;
    final choice = await showReminderSheet(context, reminder: previousReminder);
    if (choice == null || !mounted) return;
    final reminder = choice.reminder;
    final repo = ref.read(notesRepositoryProvider);
    try {
      final id = _draft.noteId ?? await _draft.createNote();
      await repo.setReminder(id, reminder);
      if (!mounted) return;
      if (reminder == null) {
        AppSnackbar.show(
          context,
          context.l10n.reminderRemoved,
          actionLabel: context.l10n.commonUndo,
          onAction: () => repo.setReminder(id, previousReminder),
        );
        return;
      }
      Haptics.success();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          context.l10n.reminderSetFailed,
          kind: SnackbarKind.error,
        );
      }
      return;
    }
    if (previousReminder == null && mounted) {
      await ensureReminderPermissions(
        context,
        ref,
        trigger: ReminderPermissionTrigger.userSet,
      );
    }
  }

  Future<void> _showMore() async {
    final note = _draft.note;
    if (note == null) {
      return;
    }
    final checklist = _isReadOnly ? null : _editor?.checklistCount;
    final action = await showNoteMoreSheet(
      context,
      isPinned: note.isPinned,
      isOwner: note.isOwner,
      isArchived: note.isArchived,
      canSeeHistory: !_draft.isViewOnly,
      shareCount: note.shareIds?.length ?? 0,
      hasChecklist: (checklist?.items ?? 0) > 0,
      hasCheckedItems: (checklist?.checked ?? 0) > 0,
    );
    if (action == null || !mounted) return;
    final actions = NoteActions(context, ref);
    final l10n = context.l10n;
    switch (action) {
      case NoteAction.pin:
        Haptics.selection();
        await actions.pin([note]);
      case NoteAction.share:
        await showShareSheet(context, noteId: note.id);
      case NoteAction.history:
        await _openHistory();
      case NoteAction.uncheckAll:
        _offerUndo(_editor?.uncheckAll(), l10n.itemsUnchecked);
      case NoteAction.deleteChecked:
        _offerUndo(_editor?.deleteChecked(), l10n.checkedItemsDeleted);
      case NoteAction.archive:
        await actions.archive(
          [note],
          beforeChange: _draft.flushOnLeave,
          afterChange: _leave,
        );
      case NoteAction.unarchive:
        await actions.unarchive([note]);
      case NoteAction.trash:
        await actions.trash(
          [note],
          beforeChange: _draft.flushOnLeave,
          afterChange: _leaveDeleted,
        );
      case NoteAction.tag || NoteAction.restore || NoteAction.deleteForever:
        break;
    }
  }

  void _offerUndo(UndoableEdit? edit, String Function(int count) message) {
    final noteId = _draft.noteId;
    if (edit == null || noteId == null) return;
    final repo = ref.read(notesRepositoryProvider);
    AppSnackbar.show(
      context,
      message(edit.count),
      actionLabel: context.l10n.commonUndo,
      onAction: () async {
        if (edit.undo()) return;
        final note = await repo.getNote(noteId);
        final content = edit.undoneContent(note?.content);
        if (note == null || content == null) return;
        await repo.updateNote(note.copyWith(content: content, isSynced: false));
      },
    );
  }

  void _leaveDeleted() {
    _draft.markDeleted();
    _leave();
  }

  Future<void> _openHistory() async {
    final id = _draft.noteId;
    if (id == null) return;
    await _draft.saveNow();
    if (!mounted) return;
    final restored = await context.push<RestoredVersion>(AppRoutes.history(id));
    if (restored == null || !mounted) return;
    if (!context.isMotionReduced) _flash.forward(from: 0);
    final repo = ref.read(notesRepositoryProvider);
    AppSnackbar.show(
      context,
      context.l10n.versionRestored,
      kind: SnackbarKind.success,
      actionLabel: context.l10n.commonUndo,
      onAction: () async {
        if (mounted) await _draft.saveNow();
        await repo.undoRestore(id, restored);
      },
    );
  }

  Future<void> _restoreFromTrash() async {
    final note = _draft.note;
    if (note == null) return;
    await NoteActions(context, ref).restore([note]);
  }

  Future<void> _deleteForever() async {
    final note = _draft.note;
    if (note == null) return;
    await NoteActions(
      context,
      ref,
    ).deleteForever([note], afterChange: _leaveDeleted);
  }

  Future<void> _addTags() async {
    if (!_draft.isActive) return;
    final isNew = _draft.isNew;
    final id = _draft.noteId ?? await _draft.createNote();
    if (!mounted) return;
    final note =
        _draft.note ?? await ref.read(notesRepositoryProvider).getNote(id);
    if (note == null || !mounted) return;
    await showTagPicker(context, [note]);
    if (isNew) await _draft.discardIfBlank();
  }

  Future<void> _removeTag(Tag tag) async {
    final note = _draft.note;
    if (note == null) return;
    Haptics.selection();
    await ref.read(notesRepositoryProvider).removeTags([note.id], [tag.id]);
  }

  Future<void> _showAdd() async {
    if (_isReadOnly) return;
    final file = await showAddSheet(context);
    if (file == null || !mounted) return;
    final kind = AttachmentKind.of(mimeType: file.mime, filename: file.name);
    final l10n = context.l10n;
    final attachments = ref.read(noteAttachmentsRepositoryProvider);
    try {
      await attachments.checkSize(file.path);
      final id = _draft.noteId ?? await _draft.createNote();
      await attachments.addAttachment(id, file.path, file.mime, file.name);
      if (!mounted) return;
      final online = ref.read(isOnlineProvider);
      AppSnackbar.show(
        context,
        attachmentAddedLabel(kind, l10n, isOnline: online),
        kind: SnackbarKind.success,
      );
    } on AttachmentTooBigException {
      if (mounted) {
        AppSnackbar.show(
          context,
          l10n.attachmentTooBig,
          kind: SnackbarKind.error,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          attachmentAddFailedLabel(kind, l10n),
          kind: SnackbarKind.error,
        );
      }
    }
  }

  RichTextEditorState? get _editor => _editorKey.currentState;

  void _focusEditorEnd() {
    if (_isReadOnly) return _shakeReadOnly();
    _editor?.focusEnd();
  }

  void _splitTitle() {
    final editor = _editor;
    if (editor == null) return;
    final value = _draft.title.value;
    final text = value.text;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    final head = text.substring(0, selection.start);
    _draft.title.value = TextEditingValue(
      text: head,
      selection: TextSelection.collapsed(offset: head.length),
    );
    editor.addFirstLine(text.substring(selection.end));
  }

  void _joinTitle(String words) {
    final title = _draft.title.text;
    _draft.title.value = TextEditingValue(
      text: '$title$words',
      selection: TextSelection.collapsed(offset: title.length),
    );
    _titleFocus.requestFocus();
    Haptics.light();
  }

  Rect _visibleArea() {
    final view = View.of(context);
    final scale = view.devicePixelRatio;
    final size = view.physicalSize / scale;
    final keyboard = view.viewInsets.bottom / scale;
    return Rect.fromLTRB(
      0,
      view.viewPadding.top / scale + PageBar.heightOf(context),
      size.width,
      keyboard > 0
          ? size.height - keyboard - _editorOverlay.barHeight
          : size.height,
    );
  }

  void _shakeReadOnly() {
    Haptics.warning();
    if (!context.isMotionReduced) _nudge.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final appearance = NoteAppearance.of(context, _draft.background);
    final writing = _writing && !_isReadOnly;
    final density = context.density;
    final titleStyle = context.noteTypography.title;
    final safeBottom = context.safeBottomAtRest;
    final underText = _isReadOnly
        ? safeBottom + 8 + _readOnlyBarHeight + density.space24
        : writing
        ? 2 * AnchorTokens.sizeControlMedium + AnchorTokens.space32
        : safeBottom + density.space48;
    final palette = EditorPalette(
      muted: appearance.colors.muted,
      surface: appearance.colors.surface,
      border: appearance.colors.border,
      background: appearance.colors.bg,
      highlightFill: (name) => appearance.highlight(context, name),
      highlightInk: (name) =>
          colors.highlights[name]?.ink ?? colors.accentStrong,
    );
    final note = _draft.note;
    final isNew = _draft.isNew;
    final isTrashed = _draft.isTrashed;
    final bar = NoteBar(
      appearance: appearance,
      scrollOffset: _scrollOffset,
      reminder: note?.reminder,
      isUnsynced: note != null && !note.isSynced && !_isReadOnly,
      isTrashed: isTrashed,
      isReadOnly: _isReadOnly,
      onBack: _back,
      onHistory: _openHistory,
      onBackground: _showBackground,
      onReminder: _showReminder,
      onMore: isNew ? null : _showMore,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height:
              MediaQuery.viewPaddingOf(context).top +
              PageBar.heightOf(context) +
              4,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AnchorTokens.spaceGutterPhone,
          ),
          child: _isReadOnly
              ? GestureDetector(
                  onTap: _shakeReadOnly,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: density.space8),
                    child: Text(
                      displayTitleOf(note?.title ?? '', context.l10n),
                      style: titleStyle.copyWith(color: colors.appText),
                    ),
                  ),
                )
              : TextField(
                  controller: _draft.title,
                  focusNode: _titleFocus,
                  showCursor: _isOpen,
                  undoController: _titleHistory,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [TitleInputFormatter(onEnter: _splitTitle)],
                  onEditingComplete: _splitTitle,
                  style: titleStyle.copyWith(color: colors.appText),
                  cursorColor: colors.accentStrong,
                  decoration: InputDecoration(
                    hintText: context.l10n.noteTitleHint,
                    hintStyle: titleStyle.copyWith(
                      color: appearance.colors.muted,
                    ),
                    contentPadding: EdgeInsets.only(bottom: density.space8),
                  ),
                ),
        ),
        if (note != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AnchorTokens.spaceGutterPhone,
              0,
              AnchorTokens.spaceGutterPhone,
              density.space12,
            ),
            child: NoteMetaLine(
              note: note,
              appearance: appearance,
              words: _draft.words,
              sharedWith: _draft.sharedWith,
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AnchorTokens.spaceGutterPhone,
            0,
            AnchorTokens.spaceGutterPhone,
            density.space16,
          ),
          child: NoteTagRow(
            note: note,
            appearance: appearance,
            readOnly: isTrashed,
            onAdd: _addTags,
            onRemove: isTrashed ? null : _removeTag,
            onReminder: _showReminder,
          ),
        ),
        if (note != null)
          NoteAttachmentsStrip(
            noteId: note.id,
            appearance: appearance,
            isOwner: note.isOwner,
            canEdit: note.canEdit && note.isActive,
            currentUserId: ref.watch(activeUserIdProvider),
            onAdd: _showAdd,
          ),
        ValueListenableBuilder(
          valueListenable: _showsEmptyNoteActions,
          builder: (context, showsEmptyNoteActions, editor) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AnchorTokens.spaceGutterPhone,
                  AnchorTokens.space4,
                  AnchorTokens.spaceGutterPhone,
                  0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: showsEmptyNoteActions
                        ? 40
                        : 140, // off-scale: spacer
                  ),
                  child: editor,
                ),
              ),
              if (showsEmptyNoteActions)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AnchorTokens.spaceGutterPhone,
                    density.space16,
                    AnchorTokens.spaceGutterPhone,
                    0,
                  ),
                  child: EmptyNoteActions(
                    appearance: appearance,
                    onChecklist: () =>
                        _editor?.applyLineKind(LineKind.checklist),
                    onList: () => _editor?.applyLineKind(LineKind.bullet),
                    onAdd: _showAdd,
                  ),
                ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _flash,
            builder: (context, child) => DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                color: colors.appText.withValues(
                  alpha:
                      0.07 *
                      (1 -
                          AnchorTokens.motionEaseStandard.transform(
                            ((_flash.value - 0.4) / 0.6).clamp(0.0, 1.0),
                          )) *
                      (_flash.isAnimating ? 1 : 0),
                ),
                borderRadius: BorderRadius.circular(AnchorTokens.radiusLg),
              ),
              child: child,
            ),
            child: _draft.isLoaded
                ? RichTextEditor(
                    key: _editorKey,
                    initialContent: _draft.initialContent,
                    contentVersion: _draft.contentVersion,
                    focusNode: _editorFocus,
                    canEdit: !_isReadOnly,
                    scrollController: _scroll,
                    palette: palette,
                    bottomInset: _editorOverlay.caretSpace,
                    sortChecklistItems: ref.watch(
                      editorPreferencesControllerProvider.select(
                        (preferences) => preferences.sortChecklistItems,
                      ),
                    ),
                    isCheckedFolded:
                        note != null &&
                        ref.watch(
                          checkedFoldsProvider.select(
                            (folds) => folds.contains(note.id),
                          ),
                        ),
                    onCheckedFoldChanged: note == null
                        ? null
                        : (isFolded) => ref
                              .read(checkedFoldsProvider.notifier)
                              .setFolded(note.id, isFolded: isFolded),
                    visibleArea: _visibleArea,
                    hasSlashHint: _openedAsNew,
                    onChanged: _draft.contentChanged,
                    onSelectionChanged: _editorOverlay.selectionMoved,
                    onBlankChanged: _bodyBlankChanged,
                    onBackspaceAtStart: _isReadOnly ? null : _joinTitle,
                    onLinkTap: _editorOverlay.showLink,
                    onReadOnlyTap: _shakeReadOnly,
                  )
                : const SizedBox(height: 140), // off-scale: as above
          ),
        ),
      ],
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _draft.flushOnLeave();
      },
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: context.motion(AnchorTokens.motionDurationFade),
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: AnimatedBuilder(
                  key: ValueKey(
                    '${appearance.background.id}|${context.isDark}',
                  ),
                  animation: _scrollOffset,
                  builder: (context, _) => NoteSurface(
                    appearance: appearance,
                    offset: Offset(0, -_scrollOffset.value),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: _AboveKeyboard(
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: _corrections.onMetrics,
                  child: CustomScrollView(
                    controller: _scroll,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    slivers: [
                      SliverToBoxAdapter(child: content),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _focusEditorEnd,
                          child: _BottomSpacer(
                            height: underText,
                            slashQuery: writing ? _editor?.slashQuery : null,
                            slashHeight: _editorOverlay.slashMenuSpace,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(left: 0, right: 0, top: 0, child: bar),
            Positioned.fill(
              child: EditorOverlay(
                controller: _editorOverlay,
                palette: palette,
                hasToolbar: !_isReadOnly && _draft.isLoaded,
                canEdit: !_isReadOnly,
                isWriting: writing,
                isTitleFocused: _titleFocus.hasFocus,
                titleHistory: _titleHistory,
                onAddAttachment: _showAdd,
              ),
            ),
            if (_isReadOnly && note != null && !note.isDeleted)
              Positioned(
                left: AnchorTokens.spaceGutterPhone,
                right: AnchorTokens.spaceGutterPhone,
                bottom: safeBottom + 8,
                child: BottomBarFrame(
                  bottom: safeBottom + 8,
                  onHeightChanged: (height) =>
                      setState(() => _readOnlyBarHeight = height),
                  child: AnimatedBuilder(
                    animation: _nudge,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        math.sin(_nudge.value * math.pi * 6) *
                            6 *
                            (1 - _nudge.value),
                        0,
                      ),
                      child: child,
                    ),
                    child: ReadOnlyBottomBar(
                      note: note,
                      appearance: appearance,
                      onRestore: _restoreFromTrash,
                      onDeleteForever: _deleteForever,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditorContent implements NoteEditorContent {
  const _EditorContent(this._key);

  final GlobalKey<RichTextEditorState> _key;

  @override
  String? get content => _key.currentState?.getContent();

  @override
  String? get plainText => _key.currentState?.getPlainText();

  @override
  bool? matches(String? content) => _key.currentState?.matchesContent(content);
}

class _AboveKeyboard extends StatelessWidget {
  const _AboveKeyboard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: child,
  );
}

class _BottomSpacer extends StatefulWidget {
  const _BottomSpacer({
    required this.height,
    required this.slashQuery,
    required this.slashHeight,
  });

  final double height;
  final ValueListenable<String?>? slashQuery;
  final double slashHeight;

  @override
  State<_BottomSpacer> createState() => _BottomSpacerState();
}

class _BottomSpacerState extends State<_BottomSpacer> {
  bool _hasSlash = false;

  @override
  void initState() {
    super.initState();
    widget.slashQuery?.addListener(_slashChanged);
  }

  @override
  void didUpdateWidget(covariant _BottomSpacer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slashQuery == widget.slashQuery) return;
    oldWidget.slashQuery?.removeListener(_slashChanged);
    widget.slashQuery?.addListener(_slashChanged);
    if (widget.slashQuery == null) _hasSlash = false;
  }

  @override
  void dispose() {
    widget.slashQuery?.removeListener(_slashChanged);
    super.dispose();
  }

  void _slashChanged() {
    if (_hasSlash || widget.slashQuery?.value == null) return;
    setState(() => _hasSlash = true);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _hasSlash
        ? math.max(widget.height, widget.slashHeight)
        : widget.height,
  );
}
