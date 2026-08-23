"use client";

import { Download, ImageIcon, Paperclip, X } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogTitle,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import { useAttachmentBlob } from "../hooks";

// Full-size preview popup shown when an image thumbnail is clicked
function ImageLightbox({
  open,
  onOpenChange,
  blobUrl,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  blobUrl: string | null;
}) {
  const handleDownload = () => {
    if (!blobUrl) return;
    const link = document.createElement("a");
    link.href = blobUrl;
    link.download = "";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    // Stop clicks anywhere in the dialog (incl. the overlay) from bubbling
    // through the React tree to the thumbnail/card click handlers below.
    <div onClick={(e) => e.stopPropagation()}>
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent
          showCloseButton={false}
          className={cn(
            "max-w-[95vw] sm:max-w-[95vw] w-full min-w-0 p-0 gap-0 overflow-hidden",
            "bg-background/95 backdrop-blur-sm border-border/50",
          )}
        >
          <div className="flex items-center justify-between px-4 py-3 border-b border-border/50">
            <DialogTitle className="text-sm font-medium">
              Attachment
            </DialogTitle>
            <DialogClose className="p-1.5 rounded-md hover:bg-foreground/10 transition-colors">
              <X className="h-4 w-4" />
            </DialogClose>
          </div>

          <div className="flex items-center justify-center p-4 bg-black/5 min-w-0">
            {blobUrl && (
              <img
                src={blobUrl}
                alt=""
                className="max-w-[95vw] max-h-[85vh] object-contain rounded min-w-0"
              />
            )}
          </div>

          <div className="flex items-center justify-end gap-2 px-4 py-3 border-t border-border/50">
            <Button variant="outline" size="sm" onClick={handleDownload}>
              <Download className="h-4 w-4 mr-2" />
              Download
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

// Small thumbnail for list view
export function ListImageThumbnail({
  noteId,
  attachmentId,
  count,
}: {
  noteId: string;
  attachmentId: string;
  count: number;
}) {
  const { blobUrl, isLoading } = useAttachmentBlob(noteId, attachmentId);
  const [lightboxOpen, setLightboxOpen] = useState(false);

  return (
    <div className="flex-shrink-0 relative">
      <div
        className={cn(
          "w-14 h-14 rounded-lg overflow-hidden bg-muted",
          blobUrl && "cursor-pointer",
        )}
        onClick={(e) => {
          if (!blobUrl) return;
          e.stopPropagation();
          setLightboxOpen(true);
        }}
      >
        {isLoading ? (
          <div className="w-full h-full animate-pulse bg-muted-foreground/10" />
        ) : blobUrl ? (
          <img src={blobUrl} alt="" className="w-full h-full object-cover" />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <ImageIcon className="h-4 w-4 text-muted-foreground/40" />
          </div>
        )}
      </div>
      {count > 1 && (
        <div className="absolute -bottom-1 -right-1 flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-background border border-border text-xs text-muted-foreground">
          <Paperclip className="h-2.5 w-2.5" />
          <span>{count}</span>
        </div>
      )}
      <ImageLightbox
        open={lightboxOpen}
        onOpenChange={setLightboxOpen}
        blobUrl={blobUrl}
      />
    </div>
  );
}

interface NoteCardImagesProps {
  noteId: string;
  imageIds: string[];
  totalAttachments: number;
}

export function NoteCardImages({
  noteId,
  imageIds,
  totalAttachments,
}: NoteCardImagesProps) {
  const count = imageIds.length;
  const extraCount = totalAttachments - count;

  if (count === 0) return null;

  // Single image - full width
  if (count === 1) {
    return (
      <div className="-mx-6 -mt-6 mb-3">
        <ImageThumbnail
          noteId={noteId}
          attachmentId={imageIds[0]}
          className="aspect-[16/9]"
        />
      </div>
    );
  }

  // Two images - side by side
  if (count === 2) {
    return (
      <div className="-mx-6 -mt-6 mb-3 grid grid-cols-2 gap-px bg-border/50">
        {imageIds.map((id) => (
          <ImageThumbnail
            key={id}
            noteId={noteId}
            attachmentId={id}
            className="aspect-square"
          />
        ))}
      </div>
    );
  }

  // Three images - 1 on top, 2 on bottom
  if (count === 3) {
    return (
      <div className="-mx-6 -mt-6 mb-3 flex flex-col gap-px bg-border/50">
        <ImageThumbnail
          noteId={noteId}
          attachmentId={imageIds[0]}
          className="aspect-[2/1]"
        />
        <div className="grid grid-cols-2 gap-px">
          {imageIds.slice(1, 3).map((id) => (
            <ImageThumbnail
              key={id}
              noteId={noteId}
              attachmentId={id}
              className="aspect-square"
            />
          ))}
        </div>
      </div>
    );
  }

  // Four+ images - 2x2 grid
  return (
    <div className="-mx-6 -mt-6 mb-3 grid grid-cols-2 gap-px bg-border/50">
      {imageIds.slice(0, 4).map((id, index) => (
        <ImageThumbnail
          key={id}
          noteId={noteId}
          attachmentId={id}
          className="aspect-square"
          overlay={index === 3 && extraCount > 0 ? `+${extraCount}` : undefined}
        />
      ))}
    </div>
  );
}

function ImageThumbnail({
  noteId,
  attachmentId,
  className,
  overlay,
}: {
  noteId: string;
  attachmentId: string;
  className?: string;
  overlay?: string;
}) {
  const { blobUrl, isLoading, error } = useAttachmentBlob(noteId, attachmentId);
  const [lightboxOpen, setLightboxOpen] = useState(false);

  return (
    <div
      className={cn(
        "relative bg-muted overflow-hidden",
        blobUrl && "cursor-pointer",
        className,
      )}
      onClick={(e) => {
        if (!blobUrl) return;
        e.stopPropagation();
        setLightboxOpen(true);
      }}
    >
      {isLoading ? (
        <div className="w-full h-full animate-pulse bg-muted-foreground/10" />
      ) : error ? (
        <div className="w-full h-full flex items-center justify-center bg-muted-foreground/5">
          <ImageIcon className="h-4 w-4 text-muted-foreground/40" />
        </div>
      ) : (
        blobUrl && (
          <img src={blobUrl} alt="" className="w-full h-full object-cover" />
        )
      )}

      {/* Overlay for extra count */}
      {overlay && (
        <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
          <span className="text-white font-semibold text-sm">{overlay}</span>
        </div>
      )}

      <ImageLightbox
        open={lightboxOpen}
        onOpenChange={setLightboxOpen}
        blobUrl={blobUrl}
      />
    </div>
  );
}
