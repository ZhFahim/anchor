"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Mic, Plus } from "lucide-react";
import * as React from "react";
import { createPortal } from "react-dom";
import { create } from "zustand";
import { toast } from "@/components/ui/toast";
import { eachLimited } from "@/lib/each";
import { useRovingFocus } from "@/lib/hooks/use-roving-focus";
import { useFlip } from "@/lib/use-flip";
import {
  deleteAttachment,
  getNoteAttachments,
  reorderAttachments,
  uploadAttachment,
} from "../../api";
import {
  ACCEPTED_TYPES_STRING,
  isAcceptedAttachmentType,
  MAX_ATTACHMENT_SIZE,
} from "../../constants";
import { blobUrlFor, releaseBlobUrl } from "../../hooks/use-attachment-blob";
import type { NoteAttachment } from "../../types";
import {
  type Kind,
  PictureTile,
  type Upload,
  UploadTile,
  VoiceCard,
} from "./attachment-tiles";
import { Viewer } from "./attachment-viewer";

const usePendingDeletes = create<{
  ids: ReadonlySet<string>;
  mark: (id: string, pending: boolean) => void;
}>((set) => ({
  ids: new Set(),
  mark: (id, pending) =>
    set((s) => {
      const ids = new Set(s.ids);
      if (pending) ids.add(id);
      else ids.delete(id);
      return { ids };
    }),
}));

interface Drag {
  id: string;
  kind: Kind;
  from: number;
  /** Before the item at this index in its group. */
  index: number;
  picture: string | null;
}

let uploadSerial = 0;

/** “a-very-long-na….png” */
export function shortFileName(name: string, max = 20) {
  if (name.length <= max) return name;
  const dot = name.lastIndexOf(".");
  const extension = dot > 0 && name.length - dot <= 6 ? name.slice(dot) : "";
  return `${name.slice(0, max - extension.length - 1)}…${extension}`;
}

/** “a.pdf”, “a.pdf and b.mov”, “a.pdf, b.mov and 2 more”. */
function names(files: File[]) {
  const fileNames = files.map((f) => shortFileName(f.name));
  if (fileNames.length <= 2) return fileNames.join(" and ");
  return `${fileNames[0]}, ${fileNames[1]} and ${fileNames.length - 2} more`;
}

/** Moves `id` before index `to` among shown files of its kind; null if it stays put. */
export function moveAttachment(
  list: NoteAttachment[],
  hidden: ReadonlySet<string>,
  id: string,
  to: number,
) {
  const shownOf = (kind: Kind) =>
    list.filter((a) => a.type === kind && !hidden.has(a.id));
  const moving = list.find((a) => a.id === id);
  if (!moving) return null;
  const group = shownOf(moving.type);
  const from = group.findIndex((a) => a.id === id);
  if (from < 0 || to < 0 || to > group.length || to === from || to === from + 1)
    return null;
  group.splice(from, 1);
  const place = to > from ? to - 1 : to;
  group.splice(place, 0, moving);
  return {
    list: [
      ...(moving.type === "image" ? group : shownOf("image")),
      ...(moving.type === "audio" ? group : shownOf("audio")),
      ...list.filter((a) => hidden.has(a.id)),
    ],
    place,
    size: group.length,
  };
}

let unfinishedBatches = 0;
const askBeforeClosing = (event: BeforeUnloadEvent) => event.preventDefault();

function warnBeforeClosing() {
  if (unfinishedBatches++ === 0)
    window.addEventListener("beforeunload", askBeforeClosing);
  return () => {
    if (--unfinishedBatches === 0)
      window.removeEventListener("beforeunload", askBeforeClosing);
  };
}

function focusInside(tile: Element) {
  for (const el of tile.querySelectorAll<HTMLElement>(
    "button, [tabindex='0']",
  )) {
    el.focus();
    if (document.activeElement === el) return true;
  }
  return false;
}

export interface AttachmentStripHandle {
  pick: () => void;
  add: (files: File[]) => void;
}

interface AttachmentStripProps {
  ref?: React.Ref<AttachmentStripHandle>;
  noteId?: string;
  canEdit: boolean;
  isOwner: boolean;
  currentUserId: string | null;
  onEnsureNoteId?: () => Promise<string | null>;
  dropping?: boolean;
  onHasFiles?: (has: boolean) => void;
}

export function AttachmentStrip({
  ref,
  noteId,
  canEdit,
  isOwner,
  currentUserId,
  onEnsureNoteId,
  dropping,
  onHasFiles,
}: AttachmentStripProps) {
  const queryClient = useQueryClient();
  const roving = useRovingFocus<HTMLDivElement>({
    itemSelector: 'button, [role="slider"]:not([aria-disabled="true"])',
  });
  const strip = roving.ref;
  const ensureNoteId = async () => {
    try {
      return noteId ?? (await onEnsureNoteId?.()) ?? null;
    } catch {
      return null;
    }
  };
  const input = React.useRef<HTMLInputElement>(null);
  const flip = useFlip(strip);
  const pending = usePendingDeletes((s) => s.ids);
  const mark = usePendingDeletes((s) => s.mark);
  const [uploads, setUploads] = React.useState<Upload[]>([]);
  const [viewing, setViewing] = React.useState<string | null>(null);
  const [announcement, setAnnouncement] = React.useState("");
  const [drag, setDrag] = React.useState<Drag | null>(null);
  const dragRef = React.useRef<Drag | null>(null);
  const pointer = React.useRef({ x: 0, y: 0 });
  const justDragged = React.useRef(false);
  const refocus = React.useRef<string | null>(null);
  const focusAfterDelete = React.useRef<string[] | null>(null);
  const focusAfterViewer = React.useRef<string[]>([]);
  const isMounted = React.useRef(false);

  const { data: attachments = [] } = useQuery({
    queryKey: ["attachments", noteId],
    queryFn: () => getNoteAttachments(noteId as string),
    enabled: !!noteId,
  });
  const shown = attachments.filter((a) => !pending.has(a.id));
  const pictures = shown.filter((a) => a.type === "image");
  const voice = shown.filter((a) => a.type === "audio");
  const hasFiles = shown.length + uploads.length > 0;
  React.useEffect(() => onHasFiles?.(hasFiles), [hasFiles, onHasFiles]);
  const canDelete = (a: NoteAttachment) =>
    canEdit &&
    (isOwner || (!!currentUserId && a.uploadedByUserId === currentUserId));

  // Uploads keep going after unmount; only their previews are revoked.
  const uploadsRef = React.useRef(uploads);
  uploadsRef.current = uploads;
  React.useEffect(() => {
    isMounted.current = true;
    return () => {
      isMounted.current = false;
      for (const u of uploadsRef.current) if (u.preview) releaseBlobUrl(u.file);
    };
  }, []);

  const patch = (key: string, change: Partial<Upload>) =>
    setUploads((list) =>
      list.map((u) => (u.key === key ? { ...u, ...change } : u)),
    );

  // Released once its tile has faded out.
  const letGo = (upload: Upload) => {
    if (upload.preview)
      window.setTimeout(() => releaseBlobUrl(upload.file), 2000);
  };

  const removeUpload = (upload: Upload) => {
    flip.prepare();
    setUploads((list) => list.filter((x) => x.key !== upload.key));
    letGo(upload);
  };

  const send = async (
    id: string,
    upload: Upload,
  ): Promise<"added" | "failed" | "canceled"> => {
    const { signal } = upload.controller;
    if (signal.aborted) return "canceled";
    try {
      const saved = await uploadAttachment(id, upload.file, {
        signal,
        onProgress: (done) => patch(upload.key, { progress: done }),
      });
      queryClient.setQueryData(["attachment-file", id, saved.id], upload.file);
      flip.prepare();
      queryClient.setQueryData<NoteAttachment[]>(
        ["attachments", id],
        (list = []) => [saved, ...list.filter((a) => a.id !== saved.id)],
      );
      setUploads((list) => list.filter((x) => x.key !== upload.key));
      letGo(upload);
      return "added";
    } catch {
      if (signal.aborted) return "canceled";
      patch(upload.key, { failed: true, progress: null });
      return "failed";
    }
  };

  const add = async (files: File[]) => {
    if (!canEdit || !files.length) return;
    const rejected = files.filter(
      (f) => !isAcceptedAttachmentType(f) || f.size > MAX_ATTACHMENT_SIZE,
    );
    const accepted = files.filter((f) => !rejected.includes(f));
    if (rejected.length)
      toast.error(
        `Can’t add ${names(rejected)}. Pick pictures or audio up to 50 MB.`,
      );
    if (!accepted.length) return;

    const fresh: Upload[] = accepted.map((file) => {
      const kind: Kind = file.type.startsWith("image/") ? "image" : "audio";
      return {
        key: `u${++uploadSerial}`,
        file,
        kind,
        preview: kind === "image" ? blobUrlFor(file) : null,
        progress: null,
        failed: false,
        controller: new AbortController(),
      };
    });
    flip.prepare();
    setUploads((list) => [...fresh, ...list]);

    const stopWarning = warnBeforeClosing();
    try {
      const id = await ensureNoteId();
      if (!id) {
        for (const u of fresh) patch(u.key, { failed: true });
        setAnnouncement("Couldn’t save the note, so the files weren’t added.");
        return;
      }
      const tried: { upload: Upload; isAdded: boolean }[] = [];
      await eachLimited(
        fresh,
        async (upload) => {
          const outcome = await send(id, upload);
          if (outcome !== "canceled")
            tried.push({ upload, isAdded: outcome === "added" });
        },
        3,
      );
      queryClient.invalidateQueries({ queryKey: ["notes"] });

      const added = tried.filter((t) => t.isAdded).length;
      const failed = tried.length - added;
      if (tried.length > 1) {
        if (failed)
          toast.error(`Couldn’t upload ${failed} of ${tried.length} files`);
        else if (!rejected.length) toast.success(`${added} files added`);
      } else if (tried.length === 1) {
        const { name } = tried[0].upload.file;
        if (isMounted.current)
          setAnnouncement(failed ? `Couldn’t upload ${name}` : `${name} added`);
        else if (failed) toast.error(`Couldn’t upload ${shortFileName(name)}`);
      }
    } finally {
      stopWarning();
    }
  };

  const retryUpload = async (upload: Upload) => {
    const again = {
      ...upload,
      failed: false,
      progress: null,
      controller: new AbortController(),
    };
    setUploads((list) => list.map((x) => (x.key === upload.key ? again : x)));
    const stopWarning = warnBeforeClosing();
    try {
      const id = await ensureNoteId();
      if (!id) return patch(upload.key, { failed: true });
      const outcome = await send(id, again);
      if (outcome === "canceled") return;
      if (outcome === "added")
        queryClient.invalidateQueries({ queryKey: ["notes"] });
      setAnnouncement(
        outcome === "added"
          ? `${upload.file.name} added`
          : `Couldn’t upload ${upload.file.name}`,
      );
    } finally {
      stopWarning();
    }
  };

  const cancelUpload = (upload: Upload) => {
    upload.controller.abort();
    removeUpload(upload);
  };

  React.useImperativeHandle(ref, () => ({
    pick: () => input.current?.click(),
    add: (files) => void add(files),
  }));

  const remove = (attachment: NoteAttachment) => {
    const id = noteId;
    if (!id) return;
    flip.prepare();
    mark(attachment.id, true);
    const name = shortFileName(attachment.originalFilename);
    toast.success(`${name} deleted`, {
      undo: () => {
        flip.prepare();
        mark(attachment.id, false);
      },
      onClose: () => {
        deleteAttachment(id, attachment.id).then(
          () => {
            queryClient.setQueryData<NoteAttachment[]>(
              ["attachments", id],
              (list) => list?.filter((x) => x.id !== attachment.id),
            );
            queryClient.invalidateQueries({ queryKey: ["notes"] });
            mark(attachment.id, false);
          },
          () => {
            mark(attachment.id, false);
            toast.error(`Couldn’t delete ${name}`);
          },
        );
      },
    });
  };

  // Tiles fading out are inert copies.
  const tileOf = (id: string) =>
    strip.current?.querySelector(`[data-id="${id}"]:not([inert])`);

  const neighborsOf = (id: string) => {
    const ids = [
      ...(strip.current?.querySelectorAll<HTMLElement>(
        "[data-id]:not([inert])",
      ) ?? []),
    ].map((tile) => tile.dataset.id as string);
    const at = ids.indexOf(id);
    return at < 0 ? [] : [...ids.slice(at + 1), ...ids.slice(0, at).reverse()];
  };

  const focusFirstOf = (ids: string[]) => {
    for (const id of ids) {
      const tile = tileOf(id);
      if (tile && focusInside(tile)) return true;
    }
    // With no files left the strip is gone, and its Add tile with it.
    const add =
      strip.current?.querySelector<HTMLElement>(".att-add") ??
      document.querySelector<HTMLElement>(
        'button[aria-label="Add a picture or audio"]',
      );
    add?.focus();
    return !!add && document.activeElement === add;
  };

  // biome-ignore lint/correctness/useExhaustiveDependencies: runs when a tile is hidden
  React.useEffect(() => {
    const ids = focusAfterDelete.current;
    if (!ids) return;
    focusAfterDelete.current = null;
    focusFirstOf(ids);
  }, [pending]);

  const deleteTile = (attachment: NoteAttachment) => {
    if (noteId) focusAfterDelete.current = neighborsOf(attachment.id);
    remove(attachment);
  };

  const focusFromViewer = (id: string) => {
    const open = tileOf(id)?.querySelector<HTMLElement>(".t-open");
    const nearby = focusAfterViewer.current;
    focusAfterViewer.current = [];
    if (open) {
      open.focus();
      return true;
    }
    return focusFirstOf(nearby);
  };

  const reorderKey = ["reorder-attachments", noteId];
  // Orders go up in sequence; the server must end on the latest one.
  const lastOrderSent = React.useRef<Promise<unknown>>(Promise.resolve());
  const reorder = useMutation({
    mutationKey: reorderKey,
    mutationFn: ({ ids }: { ids: string[]; before: NoteAttachment[] }) => {
      const sending = lastOrderSent.current.then(() =>
        reorderAttachments(noteId as string, ids),
      );
      lastOrderSent.current = sending.catch(() => {});
      return sending;
    },
    onError: (_error, { before }) => {
      queryClient.setQueryData(["attachments", noteId], before);
      toast.error("Couldn’t move the file");
    },
    // Only the last move refetches, or an earlier answer puts a tile back.
    onSettled: () => {
      if (queryClient.isMutating({ mutationKey: reorderKey }) === 1)
        return queryClient.invalidateQueries({
          queryKey: ["attachments", noteId],
        });
    },
  });

  /** Can be ahead of what's drawn. */
  const latestAttachments = () =>
    queryClient.getQueryData<NoteAttachment[]>(["attachments", noteId]) ?? [];

  const move = (id: string, to: number) => {
    if (!noteId) return;
    const before = latestAttachments();
    const moved = moveAttachment(
      before,
      usePendingDeletes.getState().ids,
      id,
      to,
    );
    if (!moved) return;
    flip.prepare();
    // Without revert: a refetch cut short mustn't undo this move.
    void queryClient.cancelQueries(
      { queryKey: ["attachments", noteId] },
      { revert: false },
    );
    queryClient.setQueryData(["attachments", noteId], moved.list);
    reorder.mutate({ ids: moved.list.map((a) => a.id), before });
    setAnnouncement(`Moved to ${moved.place + 1} of ${moved.size}`);
  };

  const nudge = (e: React.KeyboardEvent, kind: Kind, id: string) => {
    if (
      !canEdit ||
      !e.altKey ||
      (e.key !== "ArrowLeft" && e.key !== "ArrowRight")
    )
      return;
    e.preventDefault();
    const hidden = usePendingDeletes.getState().ids;
    const group = latestAttachments().filter(
      (a) => a.type === kind && !hidden.has(a.id),
    );
    const index = group.findIndex((a) => a.id === id);
    const to = e.key === "ArrowLeft" ? index - 1 : index + 2;
    if (index < 0 || to < 0 || to > group.length) return;
    refocus.current = id;
    move(id, to);
  };

  // biome-ignore lint/correctness/useExhaustiveDependencies: runs when the order changes
  React.useEffect(() => {
    const id = refocus.current;
    if (!id) return;
    refocus.current = null;
    const el = strip.current?.querySelector<HTMLElement>(
      `[data-id="${id}"] .t-open, [data-id="${id}"] .play`,
    );
    if (el && document.activeElement !== el) el.focus();
  }, [attachments]);

  const slot = (kind: Kind, x: number) => {
    const tiles = strip.current?.querySelectorAll<HTMLElement>(
      `[data-group="${kind}"]:not([data-upload], [inert])`,
    );
    if (!tiles) return 0;
    for (const [i, tile] of [...tiles].entries()) {
      const rect = tile.getBoundingClientRect();
      if (x < rect.left + rect.width / 2) return i;
    }
    return tiles.length;
  };

  const placeGhost = (el: HTMLElement | null) => {
    if (el)
      el.style.transform = `translate(${pointer.current.x - 23}px, ${pointer.current.y - 23}px)`;
  };
  const ghost = React.useRef<HTMLDivElement | null>(null);

  const startDrag = (
    e: React.PointerEvent<HTMLElement>,
    attachment: NoteAttachment,
    kind: Kind,
    index: number,
  ) => {
    if (!canEdit || !noteId || e.button !== 0) return;
    if ((e.target as HTMLElement).closest(".t-x, .a-bar, .t-fail, .a-fail"))
      return;
    const tile = e.currentTarget;
    const start = { x: e.clientX, y: e.clientY };
    const touch = e.pointerType !== "mouse";
    pointer.current = start;
    let live = false;

    const begin = () => {
      live = true;
      const started: Drag = {
        id: attachment.id,
        kind,
        from: index,
        index: index,
        picture: tile.querySelector("img")?.getAttribute("src") ?? null,
      };
      dragRef.current = started;
      setDrag(started);
    };
    const timer = touch ? window.setTimeout(begin, 450) : 0;

    const onMove = (ev: PointerEvent) => {
      pointer.current = { x: ev.clientX, y: ev.clientY };
      if (!live) {
        const distance = Math.hypot(ev.clientX - start.x, ev.clientY - start.y);
        if (touch) {
          if (distance > 8) end(false);
          return;
        }
        if (distance < 5) return;
        begin();
      }
      placeGhost(ghost.current);
      const at = slot(kind, ev.clientX);
      const current = dragRef.current;
      if (current && current.index !== at) {
        dragRef.current = { ...current, index: at };
        setDrag(dragRef.current);
      }
      const box = strip.current?.getBoundingClientRect();
      if (box && strip.current) {
        if (ev.clientX < box.left + 40) strip.current.scrollLeft -= 10;
        else if (ev.clientX > box.right - 40) strip.current.scrollLeft += 10;
      }
    };
    const hold = (ev: TouchEvent) => {
      if (live) ev.preventDefault();
    };
    const onKey = (ev: KeyboardEvent) => {
      if (ev.key === "Escape") end(false);
    };
    const end = (commit: boolean) => {
      window.clearTimeout(timer);
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
      window.removeEventListener("pointercancel", onCancel);
      window.removeEventListener("keydown", onKey, true);
      document.removeEventListener("touchmove", hold);
      const finished = dragRef.current;
      dragRef.current = null;
      if (!live) return;
      justDragged.current = true;
      window.setTimeout(() => {
        justDragged.current = false;
      });
      setDrag(null);
      if (commit && finished) move(finished.id, finished.index);
    };
    const onUp = () => end(true);
    const onCancel = () => end(false);
    window.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", onUp);
    window.addEventListener("pointercancel", onCancel);
    window.addEventListener("keydown", onKey, true);
    document.addEventListener("touchmove", hold, { passive: false });
  };

  const line = (kind: Kind, i: number) =>
    drag &&
    drag.kind === kind &&
    drag.index === i &&
    i !== drag.from &&
    i !== drag.from + 1 ? (
      <span className="st-line" aria-hidden />
    ) : null;

  const imageUploads = uploads.filter((u) => u.kind === "image");
  const audioUploads = uploads.filter((u) => u.kind === "audio");
  const visible = shown.length + uploads.length > 0;

  return (
    <>
      <input
        ref={input}
        type="file"
        multiple
        hidden
        accept={ACCEPTED_TYPES_STRING}
        onChange={(e) => {
          const files = [...(e.target.files ?? [])];
          e.target.value = "";
          void add(files);
        }}
      />
      {visible && (
        <div className="st-wrap">
          <div
            ref={strip}
            className="strip"
            role="toolbar"
            aria-label="Attachments"
            onFocus={roving.onFocus}
            onKeyDown={roving.onKeyDown}
          >
            {imageUploads.map((upload) => (
              <UploadTile
                key={upload.key}
                upload={upload}
                onRetry={() => void retryUpload(upload)}
                onCancel={() => cancelUpload(upload)}
              />
            ))}
            {pictures.map((attachment, i) => (
              <React.Fragment key={attachment.id}>
                {line("image", i)}
                <PictureTile
                  noteId={noteId as string}
                  attachment={attachment}
                  moving={drag?.id === attachment.id}
                  onPointerDown={(e) => startDrag(e, attachment, "image", i)}
                  onOpen={() =>
                    !justDragged.current && setViewing(attachment.id)
                  }
                  onKeyDown={(e) => nudge(e, "image", attachment.id)}
                  onDelete={
                    canDelete(attachment)
                      ? () => deleteTile(attachment)
                      : undefined
                  }
                />
              </React.Fragment>
            ))}
            {line("image", pictures.length)}
            {audioUploads.map((upload) => (
              <UploadTile
                key={upload.key}
                upload={upload}
                onRetry={() => void retryUpload(upload)}
                onCancel={() => cancelUpload(upload)}
              />
            ))}
            {voice.map((attachment, i) => (
              <React.Fragment key={attachment.id}>
                {line("audio", i)}
                <VoiceCard
                  noteId={noteId as string}
                  attachment={attachment}
                  moving={drag?.id === attachment.id}
                  onPointerDown={(e) => startDrag(e, attachment, "audio", i)}
                  onKeyDown={(e) => nudge(e, "audio", attachment.id)}
                  onDelete={
                    canDelete(attachment)
                      ? () => deleteTile(attachment)
                      : undefined
                  }
                />
              </React.Fragment>
            ))}
            {line("audio", voice.length)}
            {canEdit && (
              <button
                type="button"
                className="att-add"
                data-flip="add"
                data-drop={dropping || undefined}
                onClick={() => input.current?.click()}
              >
                <Plus aria-hidden />
                Add
              </button>
            )}
          </div>
        </div>
      )}
      <div className="sr-only" aria-live="polite">
        {announcement}
      </div>
      {drag &&
        createPortal(
          <div
            ref={(el) => {
              ghost.current = el;
              placeGhost(el);
            }}
            className="st-ghost"
          >
            {drag.picture ? (
              <img src={drag.picture} alt="" />
            ) : (
              <Mic aria-hidden />
            )}
          </div>,
          document.body,
        )}
      {noteId && (
        <Viewer
          noteId={noteId}
          pictures={pictures}
          id={viewing}
          onShow={setViewing}
          canDelete={canDelete}
          onDelete={(a) => {
            focusAfterViewer.current = neighborsOf(a.id);
            setViewing(null);
            remove(a);
          }}
          onReturnFocus={focusFromViewer}
        />
      )}
    </>
  );
}
