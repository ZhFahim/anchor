"use client";

import type { SyntheticListenerMap } from "@dnd-kit/core/dist/hooks/utilities";
import { Check, GripVertical, ImageOff, Paperclip, Users } from "lucide-react";
import Link from "next/link";
import * as React from "react";
import { Avatar } from "@/components/ui/avatar";
import { Skeleton } from "@/components/ui/skeleton";
import { Tip } from "@/components/ui/tooltip";
import { MoreChip, TagChip } from "@/features/tags/components/tag-chip";
import { useTagOrder } from "@/features/tags/hooks";
import type { TagLabel } from "@/features/tags/types";
import { sortTags } from "@/features/tags/utils";
import { useHighlightPaint } from "@/lib/highlight-paint";
import { useNearScreen } from "@/lib/hooks/use-near-screen";
import { rememberCard } from "@/lib/morph";
import { cn } from "@/lib/utils";
import { useAttachmentBlob } from "../hooks/use-attachment-blob";
import { deltaToBlocks, type NoteBlock } from "../note-blocks";
import { hasTitle } from "../title";
import type { Note } from "../types";
import { NoteBody } from "./note-body";
import { ReminderChip } from "./reminder-chip";

export type CardLayout = "masonry" | "grid" | "list";

/** How a card takes part in drag and drop on the board. */
export interface CardDrag {
  ref?: (element: HTMLElement | null) => void;
  listeners?: SyntheticListenerMap;
  /** The card's place while it is being dragged. */
  isPlaceholder?: boolean;
  /** The copy that follows the pointer. */
  isLifted?: boolean;
  /** Alt+Up and Alt+Down move the card one place. */
  onMoveByKey?: (noteId: string, step: -1 | 1) => void;
}

interface NoteCardProps {
  note: Note;
  tagMap: Map<string, TagLabel>;
  layout?: CardLayout;
  picking?: boolean;
  picked?: boolean;
  onPick?: (noteId: string, range: boolean) => void;
  onShare?: (note: Note) => void;
  renderActions?: (note: Note) => React.ReactNode;
  dateLabel?: string;
  drag?: CardDrag;
  href?: string;
  /** Open beside the list, in columns. */
  isOpen?: boolean;
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
  onShare,
  renderActions,
  dateLabel,
  drag,
  href = `/notes/${note.id}`,
  isOpen,
}: NoteCardProps) {
  const blocks = cardBlocks(note);
  const hasHighlights = blocks.some((block) =>
    block.runs.some((run) => run.highlight),
  );
  const cardRef = React.useRef<HTMLElement>(null);
  const dragRef = drag?.ref;
  // A new ref callback each render would detach and re-attach the card.
  const setCardRef = React.useCallback(
    (element: HTMLElement | null) => {
      cardRef.current = element;
      dragRef?.(element);
    },
    [dragRef],
  );
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
  const pictureIds = note.imagePreviewIds ?? [];
  const attachmentCount = note.attachmentCount ?? 0;
  const loadPictures = useNearScreen(cardRef, pictureIds.length > 0);
  const tagOrder = useTagOrder();
  const tags = sortTags(
    (note.tagIds ?? []).flatMap((id) => tagMap.get(id) ?? []),
    tagOrder,
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

  return (
    <article
      ref={setCardRef}
      data-note={note.background ?? ""}
      data-flip={drag?.isLifted ? undefined : note.id}
      aria-label={label}
      className={cn(
        "nc",
        picked && "picked",
        isOpen && "open",
        drag?.listeners && "nc-draggable",
        drag?.isPlaceholder && "nc-placeholder",
        drag?.isLifted && "nc-lifted",
      )}
      {...drag?.listeners}
    >
      <Link
        href={href}
        aria-label={label}
        aria-current={isOpen ? "page" : undefined}
        draggable={false}
        aria-keyshortcuts={
          drag?.onMoveByKey ? "Alt+ArrowUp Alt+ArrowDown" : undefined
        }
        className="nc-link absolute inset-0 z-1 rounded-[inherit] outline-none"
        onClick={(e) => {
          if (picking || e.metaKey || e.ctrlKey || e.shiftKey) {
            e.preventDefault();
            window.getSelection()?.removeAllRanges();
            onPick?.(note.id, e.shiftKey);
            return;
          }
          sessionStorage.setItem(`note-${note.id}`, JSON.stringify(note));
          if (cardRef.current) rememberCard(note.id, cardRef.current);
        }}
        onKeyDown={(e) => {
          if (
            drag?.onMoveByKey &&
            e.altKey &&
            (e.key === "ArrowUp" || e.key === "ArrowDown")
          ) {
            e.preventDefault();
            drag.onMoveByKey(note.id, e.key === "ArrowUp" ? -1 : 1);
            return;
          }
          if (e.key === " " && onPick) {
            e.preventDefault();
            onPick(note.id, e.shiftKey);
          }
        }}
      />
      {onPick && (
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
            </div>
          ))}
        </div>
      )}
      {isList && drag?.listeners && (
        <span className="nc-grip" aria-hidden>
          <GripVertical />
        </span>
      )}
      <div className="nc-in">
        {title && <div className="nc-title">{title}</div>}
        <NoteBody
          ref={bodyRef}
          blocks={blocks}
          variant="card"
          maxRows={ROW_LIMIT[layout]}
        />
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
        </div>
      )}
      {actions && <div className="nc-acts">{actions}</div>}
    </article>
  );
});

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
