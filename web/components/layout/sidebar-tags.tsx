"use client";

import {
  type Announcements,
  closestCenter,
  DndContext,
  type DragEndEvent,
  KeyboardSensor,
  MouseSensor,
  TouchSensor,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import {
  restrictToFirstScrollableAncestor,
  restrictToVerticalAxis,
} from "@dnd-kit/modifiers";
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import * as MenuPrimitive from "@radix-ui/react-dropdown-menu";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { ArrowDownUp, Check } from "lucide-react";
import type * as React from "react";
import { IconButton } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuTrigger,
  menuItem,
} from "@/components/ui/dropdown-menu";
import { toast } from "@/components/ui/toast";
import { Tip } from "@/components/ui/tooltip";
import {
  type PositionChange,
  planPositions,
  withPositions,
} from "@/features/ordering";
import { type TagOrder, usePreferencesStore } from "@/features/preferences";
import { REORDER_MUTATION_KEY } from "@/features/sync";
import { setTagPositions, type Tag, useTagOrder } from "@/features/tags";
import { suppressNextClick } from "@/lib/suppress-click";
import { useHoldRing } from "@/lib/use-hold-ring";
import { cn } from "@/lib/utils";

const MODIFIERS = [restrictToVerticalAxis, restrictToFirstScrollableAncestor];

/**
 * Tags in the sidebar can be dragged into the person's own order. The first
 * drag while the list is sorted by name switches it to Custom order.
 */
export function SortableTags({
  tags,
  children,
}: {
  /** In the order shown. */
  tags: Tag[];
  children: React.ReactNode;
}) {
  const queryClient = useQueryClient();
  const tagOrder = useTagOrder();
  const setTagOrder = usePreferencesStore((s) => s.setTagOrder);
  useHoldRing("[data-row^='tag:']");
  const nameOf = (id: string | number) =>
    tags.find((tag) => tag.id === id)?.name ?? "tag";

  const sensors = useSensors(
    useSensor(MouseSensor, { activationConstraint: { distance: 6 } }),
    useSensor(TouchSensor, {
      activationConstraint: { delay: 250, tolerance: 8 },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
      keyboardCodes: {
        start: ["Space"],
        cancel: ["Escape"],
        end: ["Space", "Enter"],
      },
    }),
  );

  const save = useMutation({
    mutationKey: REORDER_MUTATION_KEY,
    scope: { id: "tag-order" },
    mutationFn: (changes: Pick<PositionChange, "id" | "position">[]) =>
      setTagPositions(changes),
    onError: () => {
      toast.error("Couldn’t save the tag order");
    },
    onSettled: () => {
      if (queryClient.isMutating({ mutationKey: REORDER_MUTATION_KEY }) <= 1)
        void queryClient.invalidateQueries({ queryKey: ["tags"] });
    },
  });

  const write = (changes: Pick<PositionChange, "id" | "position">[]) => {
    void queryClient.cancelQueries({ queryKey: ["tags"] });
    queryClient.setQueryData<Tag[]>(["tags"], (cached) =>
      cached ? withPositions(cached, changes) : cached,
    );
    save.mutate(changes);
  };

  const onDragEnd = ({ active, over }: DragEndEvent) => {
    navigator.vibrate?.(10);
    suppressNextClick();
    if (!over || active.id === over.id) return;
    const from = tags.findIndex((tag) => tag.id === active.id);
    const to = tags.findIndex((tag) => tag.id === over.id);
    if (from < 0 || to < 0) return;
    const ordered = arrayMove(tags, from, to);
    const wasCustom = tagOrder === "custom";
    const changes = planPositions(ordered, String(active.id), {
      placeAll: !wasCustom,
    });
    write(changes);
    if (wasCustom) return;
    setTagOrder("custom");
    toast.success("Tags now in Custom order", {
      undo: () => {
        setTagOrder("name");
        write(changes.map(({ id, previous }) => ({ id, position: previous })));
      },
    });
  };

  const announcements: Announcements = {
    onDragStart: ({ active }) =>
      `Picked up #${nameOf(active.id)}. Use the arrow keys to move it, Space to drop it.`,
    onDragOver: ({ active, over }) =>
      over
        ? `#${nameOf(active.id)} is at position ${tags.findIndex((t) => t.id === over.id) + 1} of ${tags.length}.`
        : undefined,
    onDragEnd: ({ active, over }) =>
      over
        ? `Dropped #${nameOf(active.id)} at position ${tags.findIndex((t) => t.id === over.id) + 1} of ${tags.length}.`
        : `Dropped #${nameOf(active.id)}.`,
    onDragCancel: ({ active }) => `Moving #${nameOf(active.id)} was cancelled.`,
  };

  return (
    <DndContext
      id="sidebar-tags"
      sensors={sensors}
      collisionDetection={closestCenter}
      modifiers={MODIFIERS}
      onDragStart={() => navigator.vibrate?.(10)}
      onDragEnd={onDragEnd}
      accessibility={{
        announcements,
        screenReaderInstructions: {
          draggable:
            "To move a tag, press Space, use the arrow keys, then press Space again. Escape cancels.",
        },
      }}
    >
      <SortableContext
        items={tags.map((tag) => tag.id)}
        strategy={verticalListSortingStrategy}
      >
        {children}
      </SortableContext>
    </DndContext>
  );
}

/** Spread `handle` on the row's link: it gets keyboard focus for moving. */
export function useSortableTag(id: string, disabled: boolean) {
  const {
    setNodeRef,
    setActivatorNodeRef,
    listeners,
    attributes,
    transform,
    transition,
    isDragging,
  } = useSortable({ id, disabled });
  return {
    isDragging,
    ref: setNodeRef,
    style: {
      transform: CSS.Translate.toString(transform),
      transition,
    } as React.CSSProperties,
    listeners,
    handle: {
      ref: setActivatorNodeRef,
      "aria-roledescription": attributes["aria-roledescription"],
      "aria-describedby": attributes["aria-describedby"],
    },
  };
}

/** Gives one row its drag props. */
export function SortableTagRow({
  id,
  disabled,
  children,
}: {
  id: string;
  disabled: boolean;
  children: (sortable: ReturnType<typeof useSortableTag>) => React.ReactNode;
}) {
  return children(useSortableTag(id, disabled));
}

/** The Tags heading's menu: Custom order or by name. */
export function TagOrderMenu({
  onOpenChange,
}: {
  onOpenChange?: (open: boolean) => void;
}) {
  const tagOrder = useTagOrder();
  const setTagOrder = usePreferencesStore((s) => s.setTagOrder);
  return (
    <DropdownMenu onOpenChange={onOpenChange}>
      <Tip label="Sort tags">
        <DropdownMenuTrigger asChild>
          <IconButton size="sm" label="Sort tags">
            <ArrowDownUp />
          </IconButton>
        </DropdownMenuTrigger>
      </Tip>
      <DropdownMenuContent className="w-52" align="end">
        <DropdownMenuLabel>Sort tags</DropdownMenuLabel>
        <MenuPrimitive.RadioGroup
          value={tagOrder}
          onValueChange={(value) => setTagOrder(value as TagOrder)}
        >
          {(
            [
              ["custom", "Custom"],
              ["name", "Name A–Z"],
            ] as const
          ).map(([value, label]) => (
            <MenuPrimitive.RadioItem
              key={value}
              value={value}
              className={cn(menuItem, "data-[state=checked]:font-semibold")}
            >
              {label}
              <MenuPrimitive.ItemIndicator className="ml-auto inline-flex">
                <Check aria-hidden className="size-4 text-accent-strong" />
              </MenuPrimitive.ItemIndicator>
            </MenuPrimitive.RadioItem>
          ))}
        </MenuPrimitive.RadioGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
