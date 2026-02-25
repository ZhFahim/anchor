"use client";

import { ImageIcon, Paperclip } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAttachmentBlob } from "../hooks";

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

  return (
    <div className="flex-shrink-0 relative">
      <div className="w-14 h-14 rounded-lg overflow-hidden bg-muted">
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

  return (
    <div className={cn("relative bg-muted overflow-hidden", className)}>
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
    </div>
  );
}
