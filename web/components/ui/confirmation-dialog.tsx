"use client";

import { useTranslations } from "next-intl";
import type { ReactNode } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useLastShown } from "@/lib/hooks/use-last-shown";

interface ConfirmationDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
  title: ReactNode;
  description: ReactNode;
  confirmLabel: string;
  busyLabel?: string;
  cancelLabel?: string;
  variant?: "destructive" | "primary";
  isPending?: boolean;
  fallbackFocus?: () => HTMLElement | null | undefined;
}

export function ConfirmationDialog({
  open,
  onOpenChange,
  onConfirm,
  title,
  description,
  confirmLabel,
  busyLabel,
  cancelLabel,
  variant = "destructive",
  isPending = false,
  fallbackFocus,
}: ConfirmationDialogProps) {
  const t = useTranslations();
  const shownTitle = useLastShown(title, open);
  const shownDescription = useLastShown(description, open);
  const shownConfirmLabel = useLastShown(confirmLabel, open);
  return (
    <Dialog
      open={open}
      onOpenChange={(next) => !isPending && onOpenChange(next)}
    >
      <DialogContent
        alert
        showClose={false}
        fallbackFocus={fallbackFocus}
        onEscapeKeyDown={(e) => isPending && e.preventDefault()}
      >
        <DialogHeader>
          <DialogTitle className="pr-0">{shownTitle}</DialogTitle>
          <DialogDescription asChild>
            <div>{shownDescription}</div>
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            variant="quiet"
            onClick={() => onOpenChange(false)}
            disabled={isPending}
          >
            {cancelLabel ?? t("commonCancel")}
          </Button>
          <Button
            variant={variant}
            onClick={onConfirm}
            busy={
              isPending &&
              (busyLabel ?? t("uiBusy", { action: shownConfirmLabel }))
            }
          >
            {shownConfirmLabel}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
