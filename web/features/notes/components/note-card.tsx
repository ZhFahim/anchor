"use client";

import { Check, ImageOff, Paperclip, Users } from "lucide-react";
import Link from "next/link";
import { useLocale, useTranslations } from "next-intl";
import * as React from "react";
import { Avatar } from "@/components/ui/avatar";
import { Skeleton } from "@/components/ui/skeleton";
import { Tip } from "@/components/ui/tooltip";
import { MoreChip, TagChip } from "@/features/tags/components/tag-chip";
import type { TagLabel } from "@/features/tags/types";
import { sortTagsByName } from "@/features/tags/utils";
import type { Translate } from "@/i18n/translate";
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
}

const ROW_LIMIT: Record<CardLayout, number> = { list: 2, grid: 4, masonry: 6 };

const dateFormatsByLocale = new Map<
  string,
  { day: Intl.DateTimeFormat; dayAndYear: Intl.DateTimeFormat }
>();

function dateFormatsOf(locale: string) {
  let formats = dateFormatsByLocale.get(locale);
  if (!formats) {
    formats = {
      day: new Intl.DateTimeFormat(locale, { month: "short", day: "numeric" }),
      dayAndYear: new Intl.DateTimeFormat(locale, {
        month: "short",
        day: "numeric",
        year: "numeric",
      }),
    };
    dateFormatsByLocale.set(locale, formats);
  }
  return formats;
}

/** “Today”, “Yesterday”, “Sep 22”, or “Sep 22, 2025” in another year. */
export function formatCardDate(
  iso: string,
  t: Translate,
  locale: string,
  now = new Date(),
): string {
  const date = new Date(iso);
  const startOfDay = (d: Date) =>
    new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  const daysAgo = Math.round((startOfDay(now) - startOfDay(date)) / 86400000);
  if (daysAgo === 0) return t("notesDateToday");
  if (daysAgo === 1) return t("notesDateYesterday");
  const formats = dateFormatsOf(locale);
  return (
    date.getFullYear() === now.getFullYear() ? formats.day : formats.dayAndYear
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
}: NoteCardProps) {
  const t = useTranslations();
  const locale = useLocale();
  const blocks = cardBlocks(note);
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
  const label = title || t("commonUntitled");
  const isList = layout === "list";
  const pictureIds = note.imagePreviewIds ?? [];
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
  const sharedWithLabel = t("shareSharedWithCount", { count: shareCount });
  const footer = (
    <div className="nc-foot">
      {note.reminder && (
        <ReminderChip noteId={note.id} reminder={note.reminder} size="sm" />
      )}
      {note.sharedBy && (
        <Tip
          label={t("shareSharedBy", {
            name: note.sharedBy.name.split(" ")[0],
          })}
        >
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
              aria-label={t("shareSharedWithOpen", { count: shareCount })}
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
          title={t("notesAttachmentCount", { count: attachmentCount })}
        >
          <Paperclip aria-hidden />
          {attachmentCount}
        </span>
      )}
      <span className={cn("nc-date", dateLabel && "nc-status")}>
        {dateLabel ?? formatCardDate(note.updatedAt, t, locale)}
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
      ref={cardRef}
      data-note={note.background ?? ""}
      data-flip={note.id}
      aria-label={label}
      className={cn("nc", picked && "picked")}
    >
      <Link
        href={`/notes/${note.id}`}
        aria-label={label}
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
          aria-label={t("notesSelectNote", { title: label })}
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
                <span className="more">
                  {t("notesMoreAttachments", { count: hiddenCount })}
                </span>
              )}
            </div>
          ))}
        </div>
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
            <span className="more">
              {t("notesMoreAttachments", { count: attachmentCount - 1 })}
            </span>
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
  const t = useTranslations();
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
        title={t("notesPictureLoadFailed")}
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
