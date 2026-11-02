"use client";

import { useQuery } from "@tanstack/react-query";
import {
  Check,
  CloudOff,
  EyeOff,
  ImageOff,
  Lock,
  LockOpen,
  Paperclip,
  Pin,
  Snowflake,
  Users,
} from "lucide-react";
import Link from "next/link";
import * as React from "react";
import { Avatar } from "@/components/ui/avatar";
import {
  Dialog,
  DialogBody,
  DialogContent,
  DialogDescription,
  DialogTitle,
} from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { Tip } from "@/components/ui/tooltip";
import { usePreferencesStore } from "@/features/preferences";
import { MoreChip, TagChip } from "@/features/tags/components/tag-chip";
import type { TagLabel } from "@/features/tags/types";
import { sortTagsByName } from "@/features/tags/utils";
import { useHighlightPaint } from "@/lib/highlight-paint";
import { useNearScreen } from "@/lib/hooks/use-near-screen";
import { rememberCard } from "@/lib/morph";
import { cn } from "@/lib/utils";
import { getNoteAttachments } from "../api";
import { noteOpenedByKey } from "../card-focus";
import { useAttachmentBlob } from "../hooks/use-attachment-blob";
import {
  canTickFromCard,
  useCardAppendText,
  useCardChecklist,
} from "../hooks/use-card-checklist";
import { useUnlockedIds } from "../hooks/use-note-lock";
import { deltaToBlocks, type NoteBlock } from "../note-blocks";
import { isLockHidden } from "../note-lock";
import { hasTitle } from "../title";
import type { Note } from "../types";
import { Viewer } from "./attachments/attachment-viewer";
import { UnlockForm } from "./lock/unlock-form";
import { NoteBody } from "./note-body";
import { ReminderChip } from "./reminder-chip";

export type CardLayout = "masonry" | "grid" | "list";

interface NoteCardProps {
  note: Note;
  tagMap: Map<string, TagLabel>;
  layout?: CardLayout;
  picking?: boolean;
  picked?: boolean;
  onPick?: (noteId: string, range: boolean) => void;
  onShare?: (note: Note) => void;
  /** Pins or unpins it from the card, as in Google Keep. */
  onTogglePin?: (note: Note) => void;
  renderActions?: (note: Note) => React.ReactNode;
  dateLabel?: string;
  /** A search the card was found by, marked in the note when it opens. */
  searchTerm?: string;
}

const ROW_LIMIT: Record<CardLayout, number> = { list: 2, grid: 4, masonry: 6 };

const dayFormat = new Intl.DateTimeFormat(undefined, {
  month: "short",
  day: "numeric",
});
const dayAndYearFormat = new Intl.DateTimeFormat(undefined, {
  month: "short",
  day: "numeric",
  year: "numeric",
});

/** “Today”, “Yesterday”, “Sep 22”, or “Sep 22, 2025” in another year. */
export function formatCardDate(iso: string, now = new Date()): string {
  const date = new Date(iso);
  const startOfDay = (d: Date) =>
    new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  const daysAgo = Math.round((startOfDay(now) - startOfDay(date)) / 86400000);
  if (daysAgo === 0) return "Today";
  if (daysAgo === 1) return "Yesterday";
  return (
    date.getFullYear() === now.getFullYear() ? dayFormat : dayAndYearFormat
  ).format(date);
}

const blocksByNote = new WeakMap<Note, NoteBlock[]>();
const NO_BLOCKS: NoteBlock[] = [];

function cardBlocks(note: Note) {
  let blocks = blocksByNote.get(note);
  if (!blocks) {
    blocks = deltaToBlocks(note.content);
    blocksByNote.set(note, blocks);
  }
  return blocks;
}

export const NoteCard = React.memo(function NoteCard({
  note,
  tagMap,
  layout = "masonry",
  picking,
  picked,
  onPick,
  onTogglePin,
  onShare,
  renderActions,
  dateLabel,
  searchTerm,
}: NoteCardProps) {
  // A note locked and not opened this session shows only its title.
  const lockHidden = isLockHidden(note, useUnlockedIds());
  const blocks = lockHidden ? NO_BLOCKS : cardBlocks(note);
  const hasHighlights = blocks.some((block) =>
    block.runs.some((run) => run.highlight),
  );
  const cardRef = React.useRef<HTMLElement>(null);
  const bodyRef = React.useRef<HTMLDivElement>(null);
  useHighlightPaint(
    cardRef,
    bodyRef,
    [note.content, layout, note.background],
    hasHighlights,
  );
  const title = hasTitle(note.title) ? note.title : "";
  const label = title || "Untitled";
  const isList = layout === "list";
  const showPictures = usePreferencesStore(
    (s) => s.notes.showPictures !== false,
  );
  const pictureIds =
    showPictures && !lockHidden ? (note.imagePreviewIds ?? []) : [];
  const attachmentCount = note.attachmentCount ?? 0;
  const loadPictures = useNearScreen(cardRef, pictureIds.length > 0);
  const tags = sortTagsByName(
    (note.tagIds ?? []).flatMap((id) => tagMap.get(id) ?? []),
  );
  const actions = renderActions?.(note);

  const tagRow = tags.length > 0 && (
    <div className="nc-tags">
      {tags.slice(0, 3).map((t) => (
        <TagChip key={t.id} name={t.name} color={t.color} size="sm" />
      ))}
      {tags.length > 3 && <MoreChip count={tags.length - 3} />}
    </div>
  );

  const shareCount =
    note.permission === "owner" ? (note.shareIds?.length ?? 0) : 0;
  const sharedWithLabel = `Shared with ${shareCount} ${shareCount === 1 ? "person" : "people"}`;
  const footer = (
    <div className="nc-foot">
      {note.reminder && (
        <ReminderChip noteId={note.id} reminder={note.reminder} size="sm" />
      )}
      {note.sharedBy && (
        <Tip label={`Shared by ${note.sharedBy.name.split(" ")[0]}`}>
          <span className="relative z-5">
            <Avatar
              id={note.sharedBy.id}
              name={note.sharedBy.name}
              src={note.sharedBy.profileImage}
              size="xs"
              ring
            />
          </span>
        </Tip>
      )}
      {shareCount > 0 &&
        (onShare ? (
          <Tip label={sharedWithLabel}>
            <button
              type="button"
              className="nc-count relative z-5 -mx-1 min-h-6 min-w-6 cursor-pointer justify-center rounded-xs bg-transparent px-1 py-0 text-inherit hover:text-foreground"
              aria-label={`${sharedWithLabel}. Open Share`}
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                onShare(note);
              }}
            >
              <Users aria-hidden />
              {shareCount}
            </button>
          </Tip>
        ) : (
          <span className="nc-count" title={sharedWithLabel}>
            <Users aria-hidden />
            {shareCount}
          </span>
        ))}
      {note.isInvisible && (
        // Found by a search; it stays out of the lists.
        <span className="nc-count" title="Invisible">
          <EyeOff aria-hidden />
          <span className="sr-only">Invisible</span>
        </span>
      )}
      {note.isFrozen && (
        <span className="nc-count" title="Frozen">
          <Snowflake aria-hidden />
          <span className="sr-only">Frozen</span>
        </span>
      )}
      {note.lock && !lockHidden && (
        // Locked, but opened this session.
        <span className="nc-count" title="Locked, unlocked for now">
          <LockOpen aria-hidden />
          <span className="sr-only">Locked, unlocked for now</span>
        </span>
      )}
      {attachmentCount > 0 && !pictureIds.length && (
        <span
          className="nc-count"
          title={`${attachmentCount} ${attachmentCount === 1 ? "attachment" : "attachments"}`}
        >
          <Paperclip aria-hidden />
          {attachmentCount}
        </span>
      )}
      <span className={cn("nc-date", dateLabel && "nc-status")}>
        {dateLabel ?? formatCardDate(note.updatedAt)}
      </span>
    </div>
  );

  const shownPictures =
    !isList && pictureIds.length
      ? pictureIds.slice(0, layout === "grid" ? 1 : 4)
      : [];
  const hiddenCount = attachmentCount - shownPictures.length;
  const [viewing, setViewing] = React.useState<string | null>(null);
  const [readingOffline, setReadingOffline] = React.useState(false);
  const tickItem = useCardChecklist();
  const appendText = useCardAppendText();
  const zoom = (id: string) => (
    <button
      type="button"
      className="nc-zoom"
      tabIndex={-1}
      aria-label="View picture"
      onClick={(e) => {
        e.preventDefault();
        e.stopPropagation();
        if (picking || e.metaKey || e.ctrlKey || e.shiftKey)
          onPick?.(note.id, e.shiftKey);
        else setViewing(id);
      }}
    />
  );

  return (
    <article
      ref={cardRef}
      data-note={note.background ?? ""}
      data-flip={note.id}
      aria-label={label}
      className={cn("nc", picked && "picked")}
    >
      <Link
        href={
          searchTerm
            ? `/notes/${note.id}?hl=${encodeURIComponent(searchTerm)}`
            : `/notes/${note.id}`
        }
        aria-label={label}
        className="nc-link absolute inset-0 z-1 rounded-[inherit] outline-none"
        onClick={(e) => {
          if (picking || e.metaKey || e.ctrlKey || e.shiftKey) {
            e.preventDefault();
            window.getSelection()?.removeAllRanges();
            onPick?.(note.id, e.shiftKey);
            return;
          }
          // Offline the note's page can't load unless the service worker
          // keeps the app; without it, read the list's copy here.
          if (!navigator.onLine && !navigator.serviceWorker?.controller) {
            e.preventDefault();
            setReadingOffline(true);
            return;
          }
          sessionStorage.setItem(`note-${note.id}`, JSON.stringify(note));
          if (cardRef.current) rememberCard(note.id, cardRef.current);
        }}
        onKeyDown={(e) => {
          if (e.ctrlKey || e.metaKey || e.altKey) return;
          if ((e.key === " " || e.key.toLowerCase() === "x") && onPick) {
            e.preventDefault();
            onPick(note.id, e.shiftKey);
          } else if ((e.key === "Enter" || e.key === "o") && !picking)
            noteOpenedByKey(note.id);
        }}
      />
      {/* Picking (after Select) shows the check; otherwise the pin. */}
      {!picking &&
        onTogglePin &&
        note.state !== "trashed" &&
        !note.isArchived && (
          <Tip label={note.isPinned ? "Unpin" : "Pin"}>
            <button
              type="button"
              className="nc-pin"
              aria-label={note.isPinned ? `Unpin ${label}` : `Pin ${label}`}
              aria-pressed={!!note.isPinned}
              onClick={(e) => {
                e.stopPropagation();
                onTogglePin(note);
              }}
            >
              <Pin aria-hidden />
            </button>
          </Tip>
        )}
      {onPick && picking && (
        <button
          type="button"
          className="nc-pick"
          aria-label={`Select ${label}`}
          aria-pressed={!!picked}
          onClick={(e) => {
            e.stopPropagation();
            onPick(note.id, e.shiftKey);
          }}
        >
          <Check aria-hidden />
        </button>
      )}
      {shownPictures.length > 0 && (
        <div className={cn("nc-pics", `n${shownPictures.length}`)}>
          {shownPictures.map((id, i) => (
            <div key={id} className="ph">
              <CardPicture
                noteId={note.id}
                attachmentId={id}
                isWanted={loadPictures}
              />
              {i === shownPictures.length - 1 && hiddenCount > 0 && (
                <span className="more">+{hiddenCount}</span>
              )}
              {zoom(id)}
            </div>
          ))}
        </div>
      )}
      <div className="nc-in">
        {title && <div className="nc-title">{title}</div>}
        {lockHidden ? (
          <div className="nc-locked">
            <Lock aria-hidden />
            Locked
          </div>
        ) : (
          <NoteBody
            ref={bodyRef}
            blocks={blocks}
            variant="card"
            maxRows={ROW_LIMIT[layout]}
            onToggle={
              !picking && canTickFromCard(note)
                ? (line) => void tickItem(note, line)
                : undefined
            }
          />
        )}
        {isList ? (
          <div className="nc-row">
            {tagRow}
            {footer}
          </div>
        ) : (
          <>
            {tagRow}
            {footer}
          </>
        )}
      </div>
      {isList && pictureIds.length > 0 && (
        <div className="nc-thumb">
          <CardPicture
            noteId={note.id}
            attachmentId={pictureIds[0]}
            isWanted={loadPictures}
          />
          {attachmentCount > 1 && (
            <span className="more">+{attachmentCount - 1}</span>
          )}
          {zoom(pictureIds[0])}
        </div>
      )}
      {actions && <div className="nc-acts">{actions}</div>}
      {readingOffline && (
        <OfflineNote
          note={note}
          blocks={cardBlocks(note)}
          tags={tags}
          locked={lockHidden}
          onClose={() => setReadingOffline(false)}
        />
      )}
      {viewing && (
        <CardViewer
          noteId={note.id}
          id={viewing}
          onShow={setViewing}
          onGrabText={
            canTickFromCard(note)
              ? (text) => void appendText(note, text)
              : undefined
          }
          onClosed={() =>
            cardRef.current?.querySelector<HTMLElement>(".nc-link")?.focus()
          }
        />
      )}
    </article>
  );
});

/** The note read-only, from the list's copy, while the browser is offline. */
function OfflineNote({
  note,
  blocks,
  tags,
  locked,
  onClose,
}: {
  note: Note;
  blocks: NoteBlock[];
  tags: TagLabel[];
  locked: boolean;
  onClose: () => void;
}) {
  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent size="lg" data-note={note.background ?? ""}>
        <DialogTitle>
          {hasTitle(note.title) ? note.title : "Untitled"}
        </DialogTitle>
        <DialogDescription className="flex items-center gap-1.5">
          <CloudOff aria-hidden className="size-3.5" />
          You’re offline, so this is read-only. Open it again to edit once
          you’re back online.
        </DialogDescription>
        <DialogBody className="grid gap-3">
          {locked && note.lock ? (
            <div className="grid justify-items-center py-4">
              <UnlockForm noteId={note.id} kind={note.lock} />
            </div>
          ) : (
            <>
              {tags.length > 0 && (
                <div className="nc-tags">
                  {tags.map((t) => (
                    <TagChip
                      key={t.id}
                      name={t.name}
                      color={t.color}
                      size="sm"
                    />
                  ))}
                </div>
              )}
              <NoteBody blocks={blocks} variant="full" />
            </>
          )}
        </DialogBody>
      </DialogContent>
    </Dialog>
  );
}

/** The note's pictures, full size, opened from a card. */
function CardViewer({
  noteId,
  id,
  onShow,
  onClosed,
  onGrabText,
}: {
  noteId: string;
  id: string;
  onShow: (id: string | null) => void;
  onClosed: () => void;
  /** Adds text read from a picture to the note; absent when it can't. */
  onGrabText?: (text: string) => void;
}) {
  const { data } = useQuery({
    queryKey: ["attachments", noteId],
    queryFn: () => getNoteAttachments(noteId),
  });
  const pictures = React.useMemo(
    () => (data ?? []).filter((a) => a.type === "image"),
    [data],
  );
  return (
    <Viewer
      noteId={noteId}
      pictures={pictures}
      id={id}
      onShow={onShow}
      canDelete={() => false}
      onDelete={() => {}}
      onReturnFocus={() => {
        onClosed();
        return true;
      }}
      onGrabText={onGrabText}
    />
  );
}

function CardPicture({
  noteId,
  attachmentId,
  isWanted,
}: {
  noteId: string;
  attachmentId: string;
  isWanted: boolean;
}) {
  const { blobUrl, isLoading, error } = useAttachmentBlob(
    noteId,
    attachmentId,
    isWanted,
  );
  const [isArriving] = React.useState(!blobUrl);
  if (isLoading || (!blobUrl && !isWanted))
    return <Skeleton shape="block" className="size-full rounded-none" />;
  if (error || !blobUrl)
    return (
      <span
        className="grid size-full place-items-center text-note-muted"
        title="Couldn’t load this picture"
      >
        <ImageOff aria-hidden className="size-4.5" />
      </span>
    );
  return (
    <img
      src={blobUrl}
      alt=""
      className={isArriving ? "animate-fade-in" : undefined}
    />
  );
}
