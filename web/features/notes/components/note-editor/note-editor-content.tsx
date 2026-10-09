"use client";

import {
  Bell,
  BellRing,
  ImagePlus,
  List,
  ListChecks,
  Paperclip,
  Plus,
  Repeat,
} from "lucide-react";
import type { RefObject } from "react";
import * as React from "react";
import { createPortal } from "react-dom";
import { Avatar } from "@/components/ui/avatar";
import { LoadFailedRow } from "@/components/ui/empty-state";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { Tip } from "@/components/ui/tooltip";
import { type Tag, TagChip, TagPicker } from "@/features/tags";
import { useRovingFocus } from "@/lib/hooks/use-roving-focus";
import { useFlip } from "@/lib/use-flip";
import { cn } from "@/lib/utils";
import { deltaToFullPlainText, isContentBlank } from "../../quill";
import { isReminderPast, reminderLabel } from "../../reminder";
import type { NoteReminder, ReminderRecurrence } from "../../types";
import { AttachmentStrip, type AttachmentStripHandle } from "../attachments";
import { RichTextEditor, type RichTextEditorHandle } from "../editor";
import { formatCardDate } from "../note-card";
import { useRingOnce } from "../reminder-chip";
import { ReminderPopoverContent } from "../reminder-picker";
import { NoteOutline } from "./note-outline";

export interface Person {
  id: string;
  name: string;
  profileImage?: string | null;
}

interface NoteEditorContentProps {
  noteId?: string;
  isNew: boolean;
  readOnly: boolean;
  tagsLocked: boolean;
  canSetReminder: boolean;
  readOnlyBar?: React.ReactNode;
  title: string;
  content: string;
  updatedAt?: string;
  sharedBy?: Person | null;
  sharedWith: Person[];
  tagIds: string[];
  allTags: Tag[];
  tagsLoading: boolean;
  tagsLoadFailed: boolean;
  tagsRetrying: boolean;
  onRetryTags: () => void;
  reminder: NoteReminder | null;
  canUpload: boolean;
  isOwner: boolean;
  currentUserId: string | null;
  titleInputRef?: RefObject<HTMLInputElement | null>;
  contentEditorRef?: RefObject<RichTextEditorHandle | null>;
  onEnsureNoteIdForAttachmentUpload?: () => Promise<string | null>;
  onTitleChange: (title: string) => void;
  onContentChange: (content: string) => void;
  onTagsChange: (tagIds: string[]) => void;
  onCreateTag: (name: string) => Promise<Tag | undefined>;
  onReminder: (
    reminder: { remindAt: string; recurrence: ReminderRecurrence } | null,
  ) => void;
  onReadOnlyAttempt?: () => void;
}

/** “Sam”, “Sam and Maya”, “Sam, Maya and 2 others”. */
function sharedLine(people: Person[]) {
  const firstNames = people.map((person) => person.name.split(" ")[0]);
  if (firstNames.length <= 2) return firstNames.join(" and ");
  if (firstNames.length === 3)
    return `${firstNames[0]}, ${firstNames[1]} and ${firstNames[2]}`;
  return `${firstNames[0]}, ${firstNames[1]} and ${firstNames.length - 2} others`;
}

export function NoteEditorContent(props: NoteEditorContentProps) {
  const root = React.useRef<HTMLDivElement>(null);
  const strip = React.useRef<AttachmentStripHandle>(null);
  const dropping = useFileDrop(root, props.canUpload, (files) =>
    strip.current?.add(files),
  );
  const words = React.useMemo(
    () =>
      deltaToFullPlainText(props.content).trim().split(/\s+/).filter(Boolean)
        .length,
    [props.content],
  );
  const edited = props.updatedAt ? formatCardDate(props.updatedAt) : null;
  const people = props.sharedBy ? [] : props.sharedWith;
  const [hasFiles, setHasFiles] = React.useState(false);
  const startersRoving = useRovingFocus<HTMLDivElement>();

  const starters = !props.readOnly &&
    !hasFiles &&
    isContentBlank(props.content) && (
      <div
        ref={startersRoving.ref}
        className="em-start"
        role="toolbar"
        aria-label="Start with"
        onFocus={startersRoving.onFocus}
        onKeyDown={startersRoving.onKeyDown}
      >
        <button
          type="button"
          onClick={() =>
            props.contentEditorRef?.current?.startList?.("unchecked")
          }
        >
          <ListChecks aria-hidden />
          Checklist
        </button>
        <button
          type="button"
          onClick={() => props.contentEditorRef?.current?.startList?.("bullet")}
        >
          <List aria-hidden />
          List
        </button>
        {props.canUpload && (
          <button type="button" onClick={() => strip.current?.pick()}>
            <ImagePlus aria-hidden />
            Picture or audio
          </button>
        )}
        <span className="hint">
          or type <kbd>/</kbd> for more
        </span>
      </div>
    );

  return (
    <div ref={root} className="note-in">
      {props.readOnlyBar}
      {props.readOnly ? (
        <h1 className="n-title">{props.title || "Untitled"}</h1>
      ) : (
        <input
          ref={props.titleInputRef}
          className="n-title"
          value={props.title}
          aria-label="Title"
          placeholder="Title"
          spellCheck={false}
          onChange={(e) => props.onTitleChange(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              e.preventDefault();
              props.contentEditorRef?.current?.setSelection(0, 0);
            }
          }}
        />
      )}
      {!props.isNew && (edited || props.sharedBy || people.length > 0) && (
        <div className="meta">
          {edited && (
            <span>
              Edited{" "}
              {edited === "Today" || edited === "Yesterday"
                ? edited.toLowerCase()
                : edited}
            </span>
          )}
          {edited && <span aria-hidden>·</span>}
          <span>
            {words} {words === 1 ? "word" : "words"}
          </span>
          {props.sharedBy && (
            <>
              <span aria-hidden>·</span>
              <span className="who">
                <Avatar
                  id={props.sharedBy.id}
                  name={props.sharedBy.name}
                  src={props.sharedBy.profileImage}
                  size="xs"
                />
                Shared by {props.sharedBy.name.split(" ")[0]}
              </span>
            </>
          )}
          {people.length > 0 && (
            <>
              <span aria-hidden>·</span>
              <span className="who">
                <span className="flex -space-x-1.5">
                  {people.slice(0, 3).map((person) => (
                    <Avatar
                      key={person.id}
                      id={person.id}
                      name={person.name}
                      src={person.profileImage}
                      size="xs"
                      ring
                    />
                  ))}
                </span>
                Shared with {sharedLine(people)}
              </span>
            </>
          )}
        </div>
      )}
      <TagRow {...props} />
      <AttachmentStrip
        ref={strip}
        noteId={props.noteId}
        canEdit={props.canUpload}
        isOwner={props.isOwner}
        currentUserId={props.currentUserId}
        onEnsureNoteId={props.onEnsureNoteIdForAttachmentUpload}
        dropping={!!dropping}
        onHasFiles={setHasFiles}
      />
      <div
        className={cn("ed-body", props.readOnly && "mt-4.5")}
        onKeyDownCapture={(e) => {
          const typing =
            (e.key.length === 1 ||
              e.key === "Enter" ||
              e.key === "Backspace") &&
            !e.metaKey &&
            !e.ctrlKey &&
            !e.altKey;
          const pasting =
            (e.metaKey || e.ctrlKey) &&
            !e.altKey &&
            e.key.toLowerCase() === "v";
          if (
            props.readOnly &&
            (typing || pasting) &&
            (e.target as HTMLElement).closest(".ql-editor") &&
            !(e.key === "Enter" && (e.target as HTMLElement).closest("a"))
          ) {
            e.preventDefault();
            props.onReadOnlyAttempt?.();
          }
        }}
        onPasteCapture={(e) => {
          if (
            props.readOnly &&
            (e.target as HTMLElement).closest(".ql-editor")
          ) {
            e.preventDefault();
            props.onReadOnlyAttempt?.();
          }
        }}
        onClickCapture={(e) => {
          if (props.readOnly && (e.target as HTMLElement).closest(".ql-ui"))
            props.onReadOnlyAttempt?.();
        }}
      >
        <RichTextEditor
          ref={props.contentEditorRef}
          value={props.content}
          onChange={props.onContentChange}
          placeholder={props.isNew ? "Start writing" : "Write something"}
          readOnly={props.readOnly}
          onAddAttachment={
            props.canUpload ? () => strip.current?.pick() : undefined
          }
          below={starters}
        />
      </div>
      <NoteOutline root={root} />
      {dropping &&
        createPortal(
          <div className="drop-ov" aria-hidden>
            <span className="drop-label">
              <Paperclip />
              Drop to attach
            </span>
          </div>,
          dropping,
        )}
    </div>
  );
}

/** Returns the note while files are over it. */
function useFileDrop(
  root: React.RefObject<HTMLElement | null>,
  enabled: boolean,
  onFiles: (files: File[]) => void,
) {
  const [overNote, setOverNote] = React.useState<HTMLElement | null>(null);
  const onFilesRef = React.useRef(onFiles);
  onFilesRef.current = onFiles;

  React.useEffect(() => {
    const note = root.current?.closest<HTMLElement>(".note");
    if (!note || !enabled) return;
    let depth = 0;
    const carriesFiles = (e: DragEvent) =>
      !!e.dataTransfer?.types.includes("Files");
    const enter = (e: DragEvent) => {
      if (!carriesFiles(e)) return;
      depth++;
      setOverNote(note);
    };
    const leave = (e: DragEvent) => {
      if (!carriesFiles(e)) return;
      if (--depth <= 0) {
        depth = 0;
        setOverNote(null);
      }
    };
    const dragover = (e: DragEvent) => {
      if (!carriesFiles(e)) return;
      e.preventDefault();
      if (e.dataTransfer) e.dataTransfer.dropEffect = "copy";
    };
    // Caught before Quill sees it, or the file lands in the text.
    const drop = (e: DragEvent) => {
      if (!carriesFiles(e)) return;
      e.preventDefault();
      e.stopPropagation();
      depth = 0;
      setOverNote(null);
      onFilesRef.current([...(e.dataTransfer?.files ?? [])]);
    };
    note.addEventListener("dragenter", enter, true);
    note.addEventListener("dragleave", leave, true);
    note.addEventListener("dragover", dragover, true);
    note.addEventListener("drop", drop, true);
    return () => {
      note.removeEventListener("dragenter", enter, true);
      note.removeEventListener("dragleave", leave, true);
      note.removeEventListener("dragover", dragover, true);
      note.removeEventListener("drop", drop, true);
      setOverNote(null);
    };
  }, [root, enabled]);

  return overNote;
}

function TagRow(props: NoteEditorContentProps) {
  const roving = useRovingFocus<HTMLDivElement>();
  const row = roving.ref;
  const flip = useFlip(row, { pop: true });
  const [reminderOpen, setReminderOpen] = React.useState(false);
  const tags = props.tagIds.flatMap(
    (id) => props.allTags.find((t) => t.id === id) ?? [],
  );
  const late = !!props.reminder && isReminderPast(props.reminder);
  const ringBell = useRingOnce(
    props.noteId ?? "new",
    late && props.canSetReminder,
  );
  const tagsFailed = props.tagsLoadFailed && props.tagIds.length > 0;
  if (props.tagsLocked && !tags.length && !tagsFailed) return null;

  const toggle = (tag: Tag) => {
    flip.prepare();
    props.onTagsChange(
      props.tagIds.includes(tag.id)
        ? props.tagIds.filter((x) => x !== tag.id)
        : [...props.tagIds, tag.id],
    );
  };

  const removeTag = (tag: Tag) => {
    const removeButton = row.current?.querySelector<HTMLElement>(
      `[data-flip="${CSS.escape(tag.id)}"] button`,
    );
    if (removeButton && row.current) {
      const buttons = [...row.current.querySelectorAll<HTMLElement>("button")];
      buttons[buttons.indexOf(removeButton) + 1]?.focus();
    }
    toggle(tag);
  };

  return (
    <div
      ref={row}
      className="n-tags"
      role="toolbar"
      aria-label="Tags"
      onFocus={roving.onFocus}
      onKeyDown={roving.onKeyDown}
    >
      {tagsFailed && (
        <LoadFailedRow
          message="Couldn’t load tags."
          onRetry={props.onRetryTags}
          isRetrying={props.tagsRetrying}
          className="w-full"
        />
      )}
      {tags.map((tag) => (
        <span
          key={tag.id}
          data-flip={tag.id}
          className="inline-flex min-w-0 max-w-full"
        >
          <TagChip
            name={tag.name}
            color={tag.color}
            onRemove={props.tagsLocked ? undefined : () => removeTag(tag)}
            removeLabel={`Remove tag ${tag.name}`}
          />
        </span>
      ))}
      {props.reminder && props.canSetReminder && (
        <Popover open={reminderOpen} onOpenChange={setReminderOpen}>
          <Tip label="Change the reminder">
            <PopoverTrigger asChild>
              <button
                type="button"
                data-flip="rem"
                className={cn(
                  "inline-flex h-chip cursor-pointer items-center gap-1.25 whitespace-nowrap rounded-pill border-0 pr-2 pl-2.25 font-medium text-chip max-md:h-7.5 [&_svg]:size-3",
                  late
                    ? "bg-[color-mix(in_srgb,var(--late)_var(--mix-late),var(--note-surface))] text-late"
                    : "bg-note-surface text-foreground shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--note-border)_55%,transparent)] hover:shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--note-muted)_45%,transparent)] [&_svg]:text-note-muted",
                  ringBell &&
                    "[&_svg]:origin-[50%_15%] [&_svg]:animate-bell-ring",
                )}
              >
                {late ? (
                  <BellRing aria-hidden />
                ) : props.reminder.recurrence !== "none" ? (
                  <Repeat aria-hidden />
                ) : (
                  <Bell aria-hidden />
                )}
                {late && <span className="sr-only">Late: </span>}
                {reminderLabel(props.reminder)}
              </button>
            </PopoverTrigger>
          </Tip>
          <ReminderPopoverContent
            align="start"
            reminder={props.reminder}
            onReminder={props.onReminder}
            onClose={() => setReminderOpen(false)}
          />
        </Popover>
      )}
      {!props.tagsLocked && (
        <Popover>
          <PopoverTrigger asChild>
            <button
              type="button"
              data-flip="add"
              className="inline-flex h-chip cursor-pointer items-center gap-1.5 rounded-pill border-0 bg-transparent px-2.5 text-small text-note-muted hover:bg-note-surface hover:text-foreground max-md:h-7.5 [&_svg]:size-3.5"
            >
              <Plus aria-hidden />
              Add tag
            </button>
          </PopoverTrigger>
          <PopoverContent align="start" className="p-0">
            <TagPicker
              tags={props.allTags}
              loading={props.tagsLoading}
              loadFailed={props.tagsLoadFailed}
              isRetrying={props.tagsRetrying}
              onRetry={props.onRetryTags}
              state={(id) => props.tagIds.includes(id)}
              onToggle={toggle}
              onCreate={async (name) => {
                const created = await props.onCreateTag(name);
                if (created) {
                  flip.prepare();
                  props.onTagsChange([...props.tagIds, created.id]);
                }
                return created;
              }}
            />
          </PopoverContent>
        </Popover>
      )}
    </div>
  );
}
