"use client";

import { useState } from "react";
import { Trash2, X, AlertCircle, RefreshCw, Download } from "lucide-react";
import { Dialog, DialogContent, DialogTitle, DialogClose } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { useAttachmentBlob } from "../../hooks";
import type { NoteAttachment } from "../../types";
import { cn } from "@/lib/utils";

interface ImageAttachmentItemProps {
  noteId: string;
  attachment: NoteAttachment;
  canDelete: boolean;
  onDelete: (id: string) => void;
}

export function ImageAttachmentItem({
  noteId,
  attachment,
  canDelete,
  onDelete,
}: ImageAttachmentItemProps) {
  const { blobUrl, isLoading, error, retry } = useAttachmentBlob(
    noteId,
    attachment.id
  );
  const [lightboxOpen, setLightboxOpen] = useState(false);

  const handleDownload = () => {
    if (!blobUrl) return;
    const link = document.createElement("a");
    link.href = blobUrl;
    link.download = attachment.originalFilename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const truncatedName =
    attachment.originalFilename.length > 40
      ? attachment.originalFilename.slice(0, 37) + "..."
      : attachment.originalFilename;

  return (
    <>
      {/* Thumbnail */}
      <div
        className="relative group aspect-square rounded-lg overflow-hidden bg-muted cursor-pointer"
        onClick={() => blobUrl && setLightboxOpen(true)}
      >
        {isLoading ? (
          <div className="w-full h-full flex items-center justify-center">
            <div className="w-6 h-6 rounded-full border-2 border-muted-foreground/30 border-t-muted-foreground animate-spin" />
          </div>
        ) : error ? (
          <div className="w-full h-full flex flex-col items-center justify-center gap-2 p-2">
            <AlertCircle className="h-5 w-5 text-destructive" />
            <span className="text-xs text-muted-foreground text-center">
              Failed to load
            </span>
            <button
              onClick={(e) => {
                e.stopPropagation();
                retry();
              }}
              className="flex items-center gap-1 text-xs text-primary hover:underline"
            >
              <RefreshCw className="h-3 w-3" />
              Retry
            </button>
          </div>
        ) : (
          <img
            src={blobUrl!}
            alt={attachment.originalFilename}
            className={cn(
              "w-full h-full object-cover transition-transform duration-200",
              "group-hover:scale-105"
            )}
          />
        )}

        {/* Hover overlay */}
        {blobUrl && (
          <>
            {/* Gradient overlay */}
            <div
              className={cn(
                "absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent",
                "opacity-0 group-hover:opacity-100 transition-opacity duration-200"
              )}
            />

            {/* Delete button - top right */}
            {canDelete && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onDelete(attachment.id);
                }}
                className={cn(
                  "absolute top-2 right-2 p-1.5 rounded-full",
                  "bg-black/50 hover:bg-red-500 text-white",
                  "opacity-0 group-hover:opacity-100 transition-all duration-200",
                  "hover:scale-110"
                )}
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
            )}
          </>
        )}
      </div>

      {/* Lightbox */}
      <Dialog open={lightboxOpen} onOpenChange={setLightboxOpen}>
        <DialogContent
          showCloseButton={false}
          className={cn(
            "max-w-5xl w-full p-0 gap-0 overflow-hidden",
            "bg-background/95 backdrop-blur-sm border-border/50"
          )}
        >
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-border/50">
            <DialogTitle
              className="text-sm font-medium truncate pr-4"
              title={attachment.originalFilename}
            >
              {truncatedName}
            </DialogTitle>
            <DialogClose className="p-1.5 rounded-md hover:bg-foreground/10 transition-colors">
              <X className="h-4 w-4" />
            </DialogClose>
          </div>

          {/* Image */}
          <div className="flex items-center justify-center p-4 bg-black/5">
            {blobUrl && (
              <img
                src={blobUrl}
                alt={attachment.originalFilename}
                className="max-w-full max-h-[70vh] object-contain rounded"
              />
            )}
          </div>

          {/* Footer */}
          <div className="flex items-center justify-end gap-2 px-4 py-3 border-t border-border/50">
            <Button variant="outline" size="sm" onClick={handleDownload}>
              <Download className="h-4 w-4 mr-2" />
              Download
            </Button>
            {canDelete && (
              <Button
                variant="destructive"
                size="sm"
                onClick={() => {
                  setLightboxOpen(false);
                  onDelete(attachment.id);
                }}
              >
                <Trash2 className="h-4 w-4 mr-2" />
                Delete
              </Button>
            )}
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}
