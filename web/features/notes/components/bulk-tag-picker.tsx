"use client";

import { useQueryClient } from "@tanstack/react-query";
import * as React from "react";
import {
  Popover,
  PopoverAnchor,
  PopoverContent,
} from "@/components/ui/popover";
import { toast } from "@/components/ui/toast";
import {
  createTag,
  nextTagColor,
  type Tag,
  type TagCheckState,
  TagPicker,
  useTags,
} from "@/features/tags";
import { eachLimited } from "@/lib/each";
import { useLastShown } from "@/lib/hooks/use-last-shown";
import { bulkAddTagsToNotes, saveNote } from "../api";
import type { Note } from "../types";

const tagIdsOf = (n: Note) => n.tagIds ?? [];
const noteCount = (n: number) => `${n} ${n === 1 ? "note" : "notes"}`;
const sameTags = (a: string[], b: string[]) =>
  a.length === b.length && a.every((id) => b.includes(id));

interface TaggingSession {
  tagsAtStart: Map<string, string[]>;
  /** Each note's tags as saved so far. */
  tagsNow: Map<string, string[]>;
  saving: number;
  isClosed: boolean;
}

interface BulkTagPickerProps {
  anchor: HTMLElement | null;
  notes: Note[];
  onClose: () => void;
}

export function BulkTagPicker({ anchor, notes, onClose }: BulkTagPickerProps) {
  const queryClient = useQueryClient();
  const {
    data: tags = [],
    isLoading,
    isLoadingError,
    isFetching,
    refetch,
  } = useTags();
  const shownAnchor = useLastShown(anchor, !!anchor);
  const isClosedOutside = React.useRef(false);
  const anchorRef = React.useMemo(
    () => ({
      current: {
        getBoundingClientRect: () => {
          if (!shownAnchor) return new DOMRect();
          const button = shownAnchor.getBoundingClientRect();
          const bar = (
            shownAnchor.closest("[data-slot=selection-bar]") ?? shownAnchor
          ).getBoundingClientRect();
          return new DOMRect(button.x, bar.y, button.width, bar.height);
        },
      },
    }),
    [shownAnchor],
  );

  const updateCachedNotes = (change: Map<string, string[]>) => {
    queryClient.setQueriesData<Note[]>({ queryKey: ["notes"] }, (list) =>
      Array.isArray(list)
        ? list.map((note) => {
            const ids = change.get(note.id);
            return ids ? { ...note, tagIds: ids } : note;
          })
        : list,
    );
  };

  const session = React.useRef<TaggingSession | null>(null);

  const refresh = () => {
    queryClient.invalidateQueries({ queryKey: ["notes"] });
    queryClient.invalidateQueries({ queryKey: ["tags"] });
  };

  const send = async (
    tagId: string,
    ids: string[],
    add: boolean,
    before: Map<string, string[]>,
  ) => {
    if (add) {
      await bulkAddTagsToNotes(ids, [tagId]);
      return;
    }
    let failed = 0;
    await eachLimited(ids, async (id) => {
      const result = await saveNote(id, {
        tagIds: (before.get(id) ?? []).filter((t) => t !== tagId),
      });
      if (result.status !== "saved") failed++;
    });
    if (failed) throw new Error("some notes didn't change");
  };

  const apply = (tag: Tag, add: boolean, ids: string[]) => {
    const before = new Map(notes.map((n) => [n.id, tagIdsOf(n)]));
    session.current ??= {
      tagsAtStart: before,
      tagsNow: new Map(before),
      saving: 0,
      isClosed: false,
    };
    const tagging = session.current;
    tagging.saving++;
    const after = new Map(
      ids.map((id) => {
        const current = before.get(id) ?? [];
        return [
          id,
          add
            ? [...new Set([...current, tag.id])]
            : current.filter((t) => t !== tag.id),
        ];
      }),
    );
    updateCachedNotes(after);
    send(tag.id, ids, add, before)
      .then(
        () => {
          for (const [id, tagIds] of after) tagging.tagsNow.set(id, tagIds);
        },
        () => {
          updateCachedNotes(
            new Map(ids.map((id) => [id, tagging.tagsNow.get(id) ?? []])),
          );
          toast.error("Couldn’t update tags", {
            retry: () => apply(tag, add, ids),
          });
        },
      )
      .finally(() => {
        tagging.saving--;
        if (tagging.isClosed && !tagging.saving) showSummary(tagging);
        refresh();
      });
  };

  const state = (tagId: string): TagCheckState => {
    const count = notes.filter((n) => tagIdsOf(n).includes(tagId)).length;
    return count === notes.length && count > 0 ? true : count ? "mixed" : false;
  };

  const toggle = (tag: Tag) => {
    const allHaveTag = notes.every((n) => tagIdsOf(n).includes(tag.id));
    const ids = notes
      .filter((n) => allHaveTag || !tagIdsOf(n).includes(tag.id))
      .map((n) => n.id);
    apply(tag, !allHaveTag, ids);
  };

  const undoAll = (start: Map<string, string[]>) => {
    updateCachedNotes(start);
    eachLimited([...start.keys()], async (id) => {
      const result = await saveNote(id, { tagIds: start.get(id) ?? [] });
      if (result.status !== "saved") throw new Error("not saved");
    }).then(refresh, () => {
      refresh();
      toast.error("Couldn’t undo that");
    });
  };

  const showSummary = ({ tagsAtStart, tagsNow }: TaggingSession) => {
    const hasChanged = [...tagsNow].some(
      ([id, tagIds]) => !sameTags(tagIds, tagsAtStart.get(id) ?? []),
    );
    if (hasChanged)
      toast.success(`Tags updated on ${noteCount(tagsAtStart.size)}`, {
        undo: () => undoAll(tagsAtStart),
      });
  };
  const endSession = () => {
    const tagging = session.current;
    session.current = null;
    if (!tagging) return;
    tagging.isClosed = true;
    if (!tagging.saving) showSummary(tagging);
  };
  const endSessionRef = React.useRef(endSession);
  endSessionRef.current = endSession;

  const isOpen = !!anchor;
  React.useEffect(() => {
    if (!isOpen) endSessionRef.current();
  }, [isOpen]);
  React.useEffect(() => () => endSessionRef.current(), []);

  const hasNotes = notes.length > 0;
  React.useEffect(() => {
    if (isOpen && !hasNotes) onClose();
  }, [isOpen, hasNotes, onClose]);

  return (
    <Popover open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <PopoverAnchor virtualRef={anchorRef} />
      <PopoverContent
        side="top"
        align="center"
        className="p-0"
        // The anchor button acts as the trigger.
        onInteractOutside={(e) => {
          if (shownAnchor?.contains(e.target as Node)) e.preventDefault();
          else isClosedOutside.current = true;
        }}
        onCloseAutoFocus={(e) => {
          e.preventDefault();
          if (!isClosedOutside.current) shownAnchor?.focus();
          isClosedOutside.current = false;
        }}
      >
        <TagPicker
          tags={tags}
          loading={isLoading}
          loadFailed={isLoadingError}
          isRetrying={isFetching}
          onRetry={() => void refetch()}
          bulk={notes.length}
          state={state}
          onToggle={toggle}
          onCreate={async (name) => {
            try {
              const tag = await createTag({
                name,
                color: nextTagColor(tags.length),
              });
              queryClient.setQueryData<Tag[]>(["tags"], (list = []) => [
                ...list,
                tag,
              ]);
              apply(
                tag,
                true,
                notes.map((n) => n.id),
              );
              return tag;
            } catch {
              toast.error(`Couldn’t create #${name}`);
              return undefined;
            }
          }}
        />
      </PopoverContent>
    </Popover>
  );
}
