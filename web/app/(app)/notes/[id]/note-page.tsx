"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { HTTPError } from "ky";
import {
  useParams,
  usePathname,
  useRouter,
  useSearchParams,
} from "next/navigation";
import { useEffect, useMemo, useRef, useState } from "react";
import { flushSync } from "react-dom";
import { ConfirmationDialog } from "@/components/ui/confirmation-dialog";
import { toast } from "@/components/ui/toast";
import { useAuth } from "@/features/auth";
import {
  deletionDate,
  EditorSkeleton,
  getNoteShares,
  HistoryView,
  type Note,
  NoteEditorContent,
  NoteEditorHeader,
  NoteLoadFailed,
  NoteUnavailable,
  ReadOnlyBar,
  type SaveState,
  ShareDialog,
  useChecklistActions,
  useEditorChrome,
  useNoteActions,
  useNoteEditor,
} from "@/features/notes";
import { copyNote } from "@/features/notes/api";
import {
  forgetOpenedByKey,
  noteLeft,
  wasOpenedByKey,
} from "@/features/notes/card-focus";
import type { RichTextEditorHandle } from "@/features/notes/components/editor";
import { isOnChecklistItem } from "@/features/notes/components/editor/use-checklist-boxes";
import { LockDialog } from "@/features/notes/components/lock/lock-dialog";
import { LockGate } from "@/features/notes/components/lock/lock-gate";
import { useApplyFreeze } from "@/features/notes/hooks/use-note-freeze";
import { useApplyInvisible } from "@/features/notes/hooks/use-note-invisible";
import {
  useApplyLock,
  useUnlockedIds,
} from "@/features/notes/hooks/use-note-lock";
import {
  clampCaret,
  hasReturnCaret,
  type NoteCaret,
  takeReturnCaret,
} from "@/features/notes/note-caret";
import { isLockHidden, useUnlockedNotes } from "@/features/notes/note-lock";
import { sendNote } from "@/features/notes/note-text";
import { parseStoredContent } from "@/features/notes/quill";
import { checkboxesAction } from "@/features/notes/quill-checklist";
import { createTag, nextTagColor, type Tag, useTags } from "@/features/tags";
import { useDelayedFlag } from "@/lib/hooks/use-delayed-flag";
import {
  hasOverlay,
  isTypingTarget,
  useShortcuts,
} from "@/lib/hooks/use-shortcuts";
import { swapView } from "@/lib/morph";
import { hasShortcutKey } from "@/lib/platform";
import { useSearchHits } from "@/lib/search-hits";
import { cn } from "@/lib/utils";

export default function NoteEditorPage() {
  const params = useParams();
  const pathname = usePathname();
  // After a create in place, params.id stays "new"; the address has the id.
  const routeId = pathname.startsWith("/notes/")
    ? decodeURIComponent(pathname.slice("/notes/".length))
    : (params.id as string);
  const [newVisit, setNewVisit] = useState(0);
  const [createdHere, setCreatedHere] = useState<string | null>(null);
  const [seenPath, setSeenPath] = useState(pathname);
  if (pathname !== seenPath) {
    setSeenPath(pathname);
    if (pathname === "/notes/new") setNewVisit((visit) => visit + 1);
    if (createdHere && pathname !== `/notes/${createdHere}`)
      setCreatedHere(null);
  }
  const editsInPlace = routeId === "new" || routeId === createdHere;
  return (
    <NoteEditor
      key={editsInPlace ? `new-${newVisit}` : routeId}
      routeId={routeId}
      onCreated={setCreatedHere}
    />
  );
}

function NoteEditor({
  routeId,
  onCreated,
}: {
  routeId: string;
  onCreated: (id: string) => void;
}) {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const router = useRouter();
  const pageRef = useRef<HTMLDivElement>(null);
  const editorTop = useRef(0);
  const editor = useNoteEditor({
    routeId,
    onCreated,
    onOpenHistory: () => showHistory(true),
  });
  const {
    noteId,
    isNew,
    note,
    isLoading,
    isOwner,
    isViewer,
    saveFailure,
    save,
  } = editor;
  const contentEditorRef = useRef<RichTextEditorHandle | null>(null);
  const checklist = useChecklistActions(noteId, contentEditorRef);
  // The field the caret was last in, which a menu or button may since have
  // taken focus from.
  const caretField = useRef<NoteCaret["field"] | null>(null);
  const readCaret = (): NoteCaret | null => {
    if (caretField.current === "title") {
      const input = editor.titleInputRef.current;
      if (!input) return null;
      const start = input.selectionStart ?? input.value.length;
      const end = input.selectionEnd ?? start;
      return { field: "title", index: start, length: end - start };
    }
    if (caretField.current === "content") {
      const caret = contentEditorRef.current?.getCaret();
      return caret ? { field: "content", ...caret } : null;
    }
    return null;
  };
  const actions = useNoteActions({
    noteId,
    note,
    isOwner,
    save,
    refetchNote: editor.refetchNote,
    setIsArchived: editor.setIsArchived,
    readCaret,
  });
  // A locked note shows its lock screen until it is unlocked this session.
  const unlockedIds = useUnlockedIds();
  const lockedOut = !isNew && !!note && isLockHidden(note, unlockedIds);
  const lock = note?.lock ?? null;
  const applyLock = useApplyLock();
  const applyFreeze = useApplyFreeze();
  const applyInvisible = useApplyInvisible();
  const [lockDialogOpen, setLockDialogOpen] = useState(false);
  const { articleRef, scrollRef } = useEditorChrome({
    noteId,
    // The editor mounts once the note is unlocked.
    isLoading: isLoading || lockedOut,
    isNew,
    contentEditorRef,
  });
  const [shareDialogOpen, setShareDialogOpen] = useState(false);
  const [previewBackground, setPreviewBackground] = useState<
    string | null | false
  >(false);
  const [nudge, setNudge] = useState(0);
  const checkboxes = useMemo(
    () => checkboxesAction(parseStoredContent(editor.content)),
    [editor.content],
  );

  const {
    data: allTags = [],
    isLoading: tagsLoading,
    isLoadingError: tagsLoadFailed,
    isFetching: tagsFetching,
    refetch: refetchTags,
  } = useTags();
  const shareCount = note?.shareIds?.length ?? 0;
  const { data: shares = [] } = useQuery({
    queryKey: ["note-shares", noteId],
    queryFn: () => getNoteShares(noteId),
    enabled: !isNew && isOwner && shareCount > 0,
  });

  const createTagMutation = useMutation({
    mutationFn: (name: string) =>
      createTag({ name, color: nextTagColor(allTags.length) }),
    onSuccess: (tag) => {
      queryClient.setQueryData<Tag[]>(["tags"], (list = []) => [
        ...list.filter((t) => t.id !== tag.id),
        tag,
      ]);
      queryClient.invalidateQueries({ queryKey: ["tags"] });
    },
    onError: () => toast.error("Couldn’t create tag"),
  });

  const showHistory = (open: boolean) => {
    if (open === editor.historyOpen) return;
    const scroll = scrollRef.current;
    if (open) editorTop.current = scroll?.scrollTop ?? 0;
    const swap = () => {
      flushSync(() => editor.setHistoryOpen(open));
      if (!open && scroll) scroll.scrollTop = editorTop.current;
    };
    const page = pageRef.current;
    if (!page) return swap();
    swapView(
      page,
      swap,
      open
        ? { into: ".hs-paper", side: ".hs-side" }
        : { from: ".hs-paper", grow: ".note" },
    );
  };
  const openHistory = () => {
    save();
    showHistory(true);
  };
  const closeHistory = () => {
    showHistory(false);
    document
      .querySelector<HTMLElement>(
        '.ed-head [aria-label="More"], .ed-head [aria-label="Version history"]',
      )
      ?.focus({ preventScroll: true });
  };

  const leave = () => {
    save();
    actions.goBack();
  };
  const leaveRef = useRef(leave);
  leaveRef.current = leave;
  const trashedNote = note?.state === "trashed";
  // A frozen note still pins and archives; it can't be trashed.
  const canEditNote =
    !isNew && !trashedNote && (!editor.isReadOnly || editor.isFrozen);
  const canTrash = !isNew && !trashedNote && !(editor.isFrozen && isOwner);
  // I, as in Vim, goes back into the text, where the caret was.
  const resumeTyping = () => {
    if (editor.isReadOnly) return;
    if (caretField.current === "title") {
      editor.titleInputRef.current?.focus();
      return;
    }
    const caret = contentEditorRef.current?.getCaret();
    if (caret)
      contentEditorRef.current?.setSelection(caret.index, caret.length);
    else document.querySelector<HTMLElement>(".ed .ql-editor")?.focus();
  };
  // Google Keep's keys while no text field has focus.
  useShortcuts(
    lockedOut
      ? { Escape: leave }
      : {
          Escape: leave,
          e: () =>
            editor.isArchived
              ? actions.unarchive()
              : canEditNote && actions.archive(),
          "#": () => canTrash && actions.trash(),
          f: () => canEditNote && editor.setIsPinned((was) => !was),
          i: resumeTyping,
        },
    !editor.historyOpen,
  );
  // Ctrl+Enter finishes from anywhere but a checklist item, which it ticks;
  // Esc first leaves the text field.
  useEffect(() => {
    if (editor.historyOpen) return;
    let overlayAtPress = false;
    // Caught before Quill, which takes every Enter.
    const capture = (e: KeyboardEvent) => {
      overlayAtPress = hasOverlay();
      if (
        e.key === "Enter" &&
        hasShortcutKey(e) &&
        !e.altKey &&
        !e.shiftKey &&
        !e.isComposing &&
        !overlayAtPress &&
        !isOnChecklistItem(e.target)
      ) {
        e.preventDefault();
        e.stopPropagation();
        leaveRef.current();
      }
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.defaultPrevented || e.isComposing) return;
      // Esc while typing leaves the text field, as Vim leaves insert mode;
      // the next Esc closes the note. An open menu or dialog takes it first.
      if (
        e.key === "Escape" &&
        !overlayAtPress &&
        !e.ctrlKey &&
        !e.metaKey &&
        !e.altKey &&
        isTypingTarget(e.target)
      ) {
        e.preventDefault();
        (e.target as HTMLElement).blur();
      }
    };
    window.addEventListener("keydown", capture, true);
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("keydown", capture, true);
      window.removeEventListener("keydown", onKey);
    };
  }, [editor.historyOpen]);

  // A new note opens with the caret in its text, ready to type ("New list",
  // the L key, starts a checklist there).
  const searchParams = useSearchParams();
  // Opened from search results: mark the term in the note.
  useSearchHits(articleRef, searchParams.get("hl"), !isLoading && !lockedOut);
  const startsList = searchParams.get("list") === "1";
  useEffect(() => {
    if (!isNew) return;
    let frame = 0;
    let tries = 0;
    const start = () => {
      if (!document.querySelector(".ed .ql-editor")) {
        if (++tries < 120) frame = requestAnimationFrame(start);
        return;
      }
      const editor = contentEditorRef.current;
      if (startsList) editor?.startList("unchecked");
      else editor?.setSelection(0, 0);
    };
    frame = requestAnimationFrame(start);
    return () => cancelAnimationFrame(frame);
  }, [isNew, startsList]);

  const editorShown = !isNew && !isLoading && !lockedOut && !!note;
  // Its card takes focus again when the list comes back.
  // A new note's card has the id it will be made with.
  const cardId = isNew ? editor.newNoteId : noteId;
  useEffect(() => () => noteLeft(cardId), [cardId]);
  // Opened from its card with Enter: straight into the text, where typing
  // goes, without moving the page (a search may have scrolled to a hit).
  useEffect(() => {
    if (!editorShown || !wasOpenedByKey(noteId) || hasReturnCaret(noteId))
      return;
    let frame = 0;
    let tries = 0;
    const place = () => {
      const text = document.querySelector<HTMLElement>(".ed .ql-editor");
      if (!text) {
        if (++tries < 120) frame = requestAnimationFrame(place);
        return;
      }
      // Forgotten only once placed: an effect run that was cut short keeps it.
      forgetOpenedByKey();
      const isIdle =
        !document.activeElement || document.activeElement === document.body;
      if (text.isContentEditable && isIdle) text.focus({ preventScroll: true });
    };
    frame = requestAnimationFrame(place);
    return () => cancelAnimationFrame(frame);
  }, [editorShown, noteId]);

  // Back from an undone trash: the caret goes where it was.
  useEffect(() => {
    if (!editorShown || !hasReturnCaret(noteId)) return;
    let frame = 0;
    let tries = 0;
    const place = () => {
      if (!document.querySelector(".ed .ql-editor")) {
        if (++tries < 120) frame = requestAnimationFrame(place);
        return;
      }
      // Taken only once placed: an effect run that was cut short leaves it.
      const caret = takeReturnCaret(noteId);
      if (!caret) return;
      if (caret.field === "content") {
        contentEditorRef.current?.setSelection(caret.index, caret.length);
        return;
      }
      const input = editor.titleInputRef.current;
      if (!input) return;
      const { index, length } = clampCaret(caret, input.value.length);
      input.focus();
      input.setSelectionRange(index, index + length);
    };
    frame = requestAnimationFrame(place);
    return () => cancelAnimationFrame(frame);
  }, [editorShown, noteId, editor.titleInputRef]);

  const showSkeleton = useDelayedFlag(isLoading && !isNew);
  if (isLoading && !isNew) return showSkeleton ? <EditorSkeleton /> : null;
  if (!isNew && !note && editor.noteError)
    return isGoneError(editor.noteError) ? (
      <NoteUnavailable />
    ) : (
      <NoteLoadFailed onRetry={() => editor.refetchNote()} />
    );

  if (lockedOut && note?.lock)
    return <LockGate note={{ ...note, lock: note.lock }} onBack={leave} />;

  const lockNote = async (kind: NonNullable<Note["lock"]>) => {
    // Locked by this person here, so it stays open.
    useUnlockedNotes.getState().unlock(noteId);
    await applyLock([{ id: noteId, lock }], kind);
    toast.success(lock ? "Lock changed" : "Note locked");
  };
  const removeLock = () => {
    const was = lock;
    applyLock([{ id: noteId, lock: was }], null).then(
      () =>
        toast.success("Lock removed", {
          undo: () =>
            void applyLock([{ id: noteId, lock: null }], was).catch(() =>
              toast.error("Couldn’t undo that"),
            ),
        }),
      () =>
        toast.error(
          navigator.onLine
            ? "Couldn’t remove the lock"
            : "Removing the lock needs a connection",
          { retry: removeLock },
        ),
    );
  };

  const freeze = (isFrozen: boolean) =>
    (isFrozen ? editor.flushEdits() : Promise.resolve())
      .then(() => applyFreeze([noteId], isFrozen))
      .then(
        () =>
          toast.success(isFrozen ? "Note frozen" : "Note unfrozen", {
            undo: () =>
              void applyFreeze([noteId], !isFrozen).catch(() =>
                toast.error("Couldn’t undo that"),
              ),
          }),
        () =>
          toast.error(
            navigator.onLine
              ? `Couldn’t ${isFrozen ? "freeze" : "unfreeze"} the note`
              : `${isFrozen ? "Freezing" : "Unfreezing"} needs a connection`,
            { retry: () => freeze(isFrozen) },
          ),
      );

  const invisible = !!note?.isInvisible;
  const setInvisible = (isInvisible: boolean) =>
    applyInvisible([noteId], isInvisible).then(
      () =>
        toast.success(
          isInvisible
            ? "Note made invisible; search finds it"
            : "Note made visible",
          {
            undo: () =>
              void applyInvisible([noteId], !isInvisible).catch(() =>
                toast.error("Couldn’t undo that"),
              ),
          },
        ),
      () =>
        toast.error(
          navigator.onLine
            ? `Couldn’t make the note ${isInvisible ? "invisible" : "visible"}`
            : `Making it ${isInvisible ? "invisible" : "visible"} needs a connection`,
          { retry: () => setInvisible(isInvisible) },
        ),
    );

  const trashed = note?.state === "trashed";
  const saveRefused =
    saveFailure?.httpStatus === 403 || saveFailure?.httpStatus === 404;
  const readOnly = editor.isReadOnly || saveRefused;
  const canSetReminder = !trashed && !saveRefused;
  const saveState: SaveState =
    saveFailure && !saveFailure.retryable && !saveRefused
      ? "failed"
      : editor.isSaveStuck
        ? "offline"
        : isNew && !editor.isCreating
          ? "new"
          : editor.isSavingDraft ||
              editor.isCreating ||
              editor.hasUnsavedChanges
            ? "saving"
            : "saved";

  const readOnlyBar = editor.isOfflineCopy ? (
    <ReadOnlyBar kind="offline" nudge={nudge} />
  ) : trashed ? (
    <ReadOnlyBar
      kind="trash"
      nudge={nudge}
      deletesOn={deletionDate(note as Note)}
      restoring={actions.isRestoring}
      onRestore={actions.restore}
      onDelete={() => actions.setConfirmPermanentDelete(true)}
    />
  ) : saveRefused ? (
    <ReadOnlyBar kind="refused" nudge={nudge} />
  ) : editor.isFrozen ? (
    <ReadOnlyBar
      kind="frozen"
      nudge={nudge}
      onUnfreeze={isOwner ? () => freeze(false) : undefined}
    />
  ) : isViewer && note?.sharedBy ? (
    <ReadOnlyBar kind="view" nudge={nudge} sharedBy={note.sharedBy} />
  ) : editor.isArchived ? (
    <ReadOnlyBar kind="archived" onUnarchive={actions.unarchive} />
  ) : null;

  return (
    <div ref={pageRef} className="pg-editor">
      <article
        ref={articleRef}
        className={cn("note ed", readOnly && "ro")}
        data-note={
          (previewBackground === false
            ? editor.background
            : previewBackground) ?? ""
        }
        data-blank={
          isNew && !editor.hasUnsavedChanges && !editor.isCreating
            ? ""
            : undefined
        }
        aria-label="Note"
        onFocus={(e) => {
          if (e.target === editor.titleInputRef.current)
            caretField.current = "title";
          else if (e.target.closest(".ql-editor"))
            caretField.current = "content";
        }}
      >
        {editor.historyOpen && !isNew && (
          <HistoryView
            noteId={noteId}
            note={note ?? null}
            title={editor.title}
            content={editor.content}
            currentUserId={user?.id ?? null}
            saving={editor.isSavingDraft || editor.hasUnsavedChanges}
            onClose={closeHistory}
            onRestored={(restored: Note) => editor.applyServerNote(restored)}
            flushEdits={editor.flushEdits}
          />
        )}
        <div
          ref={scrollRef}
          className="ed-scroll scrollbar-slim"
          hidden={editor.historyOpen && !isNew}
        >
          <NoteEditorHeader
            saveState={trashed || saveRefused ? "new" : saveState}
            onRetrySave={editor.retrySave}
            onBack={leave}
            trashed={trashed}
            readOnly={readOnly}
            saved={!isNew && !saveRefused}
            isOwner={isOwner}
            canViewHistory={!isViewer}
            canSetReminder={canSetReminder}
            isPinned={editor.isPinned}
            isArchived={editor.isArchived}
            background={editor.background}
            reminder={editor.reminder}
            sharedWithCount={shareCount}
            onTogglePin={() => editor.setIsPinned((was) => !was)}
            onBackground={editor.setBackground}
            onPreviewBackground={setPreviewBackground}
            onReminder={editor.changeReminder}
            onShare={() => setShareDialogOpen(true)}
            onHistory={openHistory}
            lock={lock}
            onLock={() => setLockDialogOpen(true)}
            onRemoveLock={removeLock}
            frozen={editor.isFrozen}
            onToggleFreeze={
              isOwner && !trashed && !editor.isOfflineCopy
                ? () => freeze(!editor.isFrozen)
                : undefined
            }
            invisible={invisible}
            onToggleInvisible={
              isNew || trashed || editor.isOfflineCopy
                ? undefined
                : () => setInvisible(!invisible)
            }
            onSend={async () => {
              try {
                const sent = await sendNote(editor.title, editor.content);
                if (sent === "copied") toast.success("Note copied as text");
              } catch {
                toast.error("Couldn’t send the note");
              }
            }}
            onCopy={
              isNew || trashed
                ? undefined
                : async () => {
                    try {
                      await editor.flushEdits();
                      const copy = await copyNote(noteId);
                      queryClient.invalidateQueries({ queryKey: ["notes"] });
                      queryClient.invalidateQueries({ queryKey: ["tags"] });
                      toast.success("Copy made", {
                        action: {
                          label: "Open",
                          onClick: () => router.push(`/notes/${copy.id}`),
                        },
                      });
                    } catch {
                      toast.error(
                        navigator.onLine
                          ? "Couldn’t make a copy"
                          : "Making a copy needs a connection",
                      );
                    }
                  }
            }
            onArchive={actions.archive}
            onUnarchive={actions.unarchive}
            onTrash={actions.trash}
            checkboxes={checkboxes}
            onCheckboxes={() =>
              checkboxes === "show"
                ? contentEditorRef.current?.showCheckboxes()
                : contentEditorRef.current?.hideCheckboxes()
            }
            checklist={readOnly ? undefined : checklist}
          />
          <NoteEditorContent
            noteId={!isNew ? noteId : undefined}
            isNew={isNew}
            readOnly={readOnly}
            tagsLocked={trashed || saveRefused}
            canSetReminder={canSetReminder}
            readOnlyBar={readOnlyBar}
            title={editor.title}
            content={editor.content}
            updatedAt={note?.updatedAt}
            sharedBy={note?.sharedBy ?? null}
            sharedWith={shares.map((sh) => sh.sharedWithUser)}
            tagIds={editor.selectedTagIds}
            allTags={allTags}
            tagsLoading={tagsLoading}
            tagsLoadFailed={tagsLoadFailed}
            tagsRetrying={tagsFetching}
            onRetryTags={() => void refetchTags()}
            reminder={editor.reminder}
            canUpload={editor.canUpload && !readOnly}
            isOwner={isOwner}
            currentUserId={user?.id ?? null}
            titleInputRef={editor.titleInputRef}
            contentEditorRef={contentEditorRef}
            onEnsureNoteIdForAttachmentUpload={
              editor.ensureNoteIdForAttachmentUpload
            }
            onTitleChange={editor.setTitle}
            onContentChange={editor.setContent}
            onTagsChange={editor.setSelectedTagIds}
            onCreateTag={(name) =>
              createTagMutation.mutateAsync(name).catch(() => undefined)
            }
            onReminder={editor.changeReminder}
            onReadOnlyAttempt={() => setNudge((n) => n + 1)}
          />
        </div>
      </article>

      <ConfirmationDialog
        open={actions.confirmPermanentDelete}
        onOpenChange={actions.setConfirmPermanentDelete}
        title="Permanently delete this note?"
        description="This can’t be undone. People you shared it with will lose access too."
        confirmLabel="Delete permanently"
        busyLabel="Deleting…"
        isPending={actions.isDeletingPermanently}
        onConfirm={actions.deletePermanently}
      />
      <ConfirmationDialog
        open={actions.confirmLeaveShare}
        onOpenChange={actions.setConfirmLeaveShare}
        title="Remove this note from your notes?"
        description="To see it again, its owner has to share it with you again."
        confirmLabel="Remove"
        busyLabel="Removing…"
        isPending={actions.isLeavingShare}
        onConfirm={actions.leaveShare}
      />
      {!isNew && (
        <LockDialog
          open={lockDialogOpen}
          onOpenChange={setLockDialogOpen}
          current={lock}
          onLock={lockNote}
        />
      )}
      {!isNew && (
        <ShareDialog
          open={shareDialogOpen}
          onOpenChange={setShareDialogOpen}
          noteId={noteId}
          title={editor.title}
        />
      )}
    </div>
  );
}

const isGoneError = (error: unknown) =>
  error instanceof HTTPError &&
  (error.response.status === 404 || error.response.status === 403);
