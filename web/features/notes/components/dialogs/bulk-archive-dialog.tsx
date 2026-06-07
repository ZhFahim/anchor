"use client";

import { Archive } from "lucide-react";
import { ConfirmationDialog } from "@/components/ui/confirmation-dialog";

interface BulkArchiveDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
  count: number;
  isPending?: boolean;
}

export function BulkArchiveDialog({
  open,
  onOpenChange,
  onConfirm,
  count,
  isPending = false,
}: BulkArchiveDialogProps) {
  return (
    <ConfirmationDialog
      open={open}
      onOpenChange={onOpenChange}
      onConfirm={onConfirm}
      title={
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
            <Archive className="h-5 w-5 text-primary" />
          </div>
          Archive Notes
        </div>
      }
      description={`Are you sure you want to archive ${count} note${count > 1 ? "s" : ""}? You can unarchive them later.`}
      confirmLabel="Archive"
      variant="default"
      isPending={isPending}
    />
  );
}
