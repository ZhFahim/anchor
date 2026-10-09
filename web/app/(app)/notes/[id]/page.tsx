"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { useParams, usePathname } from "next/navigation";
import { useRef, useState } from "react";
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
  useEditorChrome,
  useNoteActions,
  useNoteEditor,
} from "@/features/notes";
import type { RichTextEditorHandle } from "@/features/notes/components/editor";
import { createTag, nextTagColor, type Tag, useTags } from "@/features/tags";
import { useDelayedFlag } from "@/lib/hooks/use-delayed-flag";
import { swapView } from "@/lib/morph";
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
  const actions = useNoteActions({
    noteId,
    note,
    isOwner,
    save,
    refetchNote: editor.refetchNote,
    setIsArchived: editor.setIsArchived,
  });
  const contentEditorRef = useRef<RichTextEditorHandle | null>(null);
  const { articleRef, scrollRef } = useEditorChrome({
    noteId,
    isLoading,
    isNew,
    contentEditorRef,
  });
  const [shareDialogOpen, setShareDialogOpen] = useState(false);
  const [previewBackground, setPreviewBackground] = useState<
    string | null | false
  >(false);
  const [nudge, setNudge] = useState(0);

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

  const showSkeleton = useDelayedFlag(isLoading && !isNew);
  if (isLoading && !isNew) return showSkeleton ? <EditorSkeleton /> : null;
  if (!isNew && !note && editor.noteError)
    return isGoneError(editor.noteError) ? (
      <NoteUnavailable />
    ) : (
      <NoteLoadFailed onRetry={() => editor.refetchNote()} />
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

  const readOnlyBar = trashed ? (
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
            onBack={() => {
              save();
              actions.goBack();
            }}
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
            onArchive={actions.archive}
            onUnarchive={actions.unarchive}
            onTrash={actions.trash}
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
