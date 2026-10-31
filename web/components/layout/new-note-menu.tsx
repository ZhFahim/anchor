"use client";

import { ChevronDown, ListChecks } from "lucide-react";
import { useRouter } from "next/navigation";
import { useRef } from "react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { rememberNewNoteButton } from "@/lib/morph";
import { cn } from "@/lib/utils";

/** The secondary action of New note; choosing a type never changes the default. */
export function NewNoteMenu({
  checklistHref,
  className,
  onNavigate,
  onClose,
}: {
  checklistHref: string;
  className?: string;
  onNavigate?: () => void;
  onClose?: () => void;
}) {
  const router = useRouter();
  const trigger = useRef<HTMLButtonElement>(null);
  const navigating = useRef(false);
  return (
    <DropdownMenu
      onOpenChange={(open) => {
        if (open) navigating.current = false;
      }}
    >
      <DropdownMenuTrigger asChild>
        <button
          ref={trigger}
          type="button"
          aria-label="Choose note type"
          className={cn(
            "grid w-8.5 shrink-0 cursor-pointer place-items-center border-l border-card/20 bg-foreground text-card transition-colors hover:bg-foreground/85 data-[state=open]:bg-foreground/85 [&>svg]:size-3.5",
            className,
          )}
        >
          <ChevronDown aria-hidden />
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent
        align="end"
        onCloseAutoFocus={(event) => {
          if (navigating.current) event.preventDefault();
          onClose?.();
        }}
      >
        <DropdownMenuItem
          onSelect={() => {
            navigating.current = true;
            const primary =
              trigger.current?.parentElement?.querySelector<HTMLElement>(
                "[data-new-note]",
              );
            rememberNewNoteButton(primary ?? trigger.current);
            onNavigate?.();
            router.push(checklistHref);
          }}
        >
          <ListChecks aria-hidden />
          New checklist
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
