"use client";

import { Copy, ExternalLink, Pencil, Unlink } from "lucide-react";
import { useLayoutEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import type { LinkRange, QuillInstance } from "@/features/notes";
import { cn } from "@/lib/utils";

interface LinkBubbleProps {
  getQuill: () => QuillInstance | null;
  link: LinkRange;
  containerEl: HTMLElement | null;
  onOpen: (url: string) => void;
  onCopy: (url: string) => void;
  onEdit: (link: LinkRange) => void;
  onRemove: (link: LinkRange) => void;
}

export function LinkBubble({
  getQuill,
  link,
  containerEl,
  onOpen,
  onCopy,
  onEdit,
  onRemove,
}: LinkBubbleProps) {
  const ref = useRef<HTMLDivElement>(null);
  const [position, setPosition] = useState<{
    top: number;
    left: number;
  } | null>(null);

  useLayoutEffect(() => {
    if (!containerEl) return;
    const quill = getQuill();
    if (!quill) return;
    const bounds = quill.getBounds(link.start, link.length);
    const bubble = ref.current;
    if (!bounds || !bubble) return;

    const containerRect = containerEl.getBoundingClientRect();
    const bubbleWidth = bubble.offsetWidth;
    const margin = 8;

    let top = bounds.top - bubble.offsetHeight - margin;
    if (top < 0) top = bounds.bottom + margin;

    let left = bounds.left + bounds.width / 2 - bubbleWidth / 2;
    const maxLeft = containerRect.width - bubbleWidth - margin;
    if (left < margin) left = margin;
    if (left > maxLeft) left = Math.max(margin, maxLeft);

    setPosition({ top, left });
  }, [getQuill, link.start, link.length, containerEl]);

  return (
    <div
      ref={ref}
      className={cn(
        "absolute z-40 flex items-center gap-1 rounded-full border border-border/40 bg-popover px-2 py-1 shadow-lg backdrop-blur-sm",
        position ? "opacity-100" : "opacity-0 pointer-events-none",
      )}
      style={position ?? { top: -9999, left: -9999 }}
    >
      <a
        href={link.url}
        onClick={(e) => {
          e.preventDefault();
          onOpen(link.url);
        }}
        className="max-w-55 truncate px-2 text-xs text-muted-foreground hover:text-foreground"
        title={link.url}
      >
        {link.url}
      </a>
      <BubbleAction
        icon={<ExternalLink className="h-3.5 w-3.5" />}
        label="Open"
        onClick={() => onOpen(link.url)}
      />
      <BubbleAction
        icon={<Copy className="h-3.5 w-3.5" />}
        label="Copy"
        onClick={() => onCopy(link.url)}
      />
      <BubbleAction
        icon={<Pencil className="h-3.5 w-3.5" />}
        label="Edit"
        onClick={() => onEdit(link)}
      />
      <BubbleAction
        icon={<Unlink className="h-3.5 w-3.5" />}
        label="Remove"
        onClick={() => onRemove(link)}
        destructive
      />
    </div>
  );
}

function BubbleAction({
  icon,
  label,
  onClick,
  destructive,
}: {
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
  destructive?: boolean;
}) {
  return (
    <Button
      type="button"
      variant="ghost"
      size="sm"
      className={cn(
        "h-7 w-7 rounded-full p-0",
        destructive
          ? "text-destructive hover:text-destructive"
          : "text-muted-foreground",
      )}
      title={label}
      // Don't steal focus from the editor.
      onMouseDown={(e) => e.preventDefault()}
      onClick={onClick}
    >
      {icon}
    </Button>
  );
}
