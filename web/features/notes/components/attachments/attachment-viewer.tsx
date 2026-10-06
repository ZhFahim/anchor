"use client";

import * as DialogPrimitive from "@radix-ui/react-dialog";
import {
  ChevronLeft,
  ChevronRight,
  CircleAlert,
  Download,
  Trash2,
  X,
} from "lucide-react";
import * as React from "react";
import { toastHostRef } from "@/components/ui/toast";
import { useAttachmentBlob } from "../../hooks/use-attachment-blob";
import type { NoteAttachment } from "../../types";

export function Viewer({
  noteId,
  pictures,
  id,
  onShow,
  canDelete,
  onDelete,
  onReturnFocus,
}: {
  noteId: string;
  pictures: NoteAttachment[];
  id: string | null;
  onShow: (id: string | null) => void;
  canDelete: (a: NoteAttachment) => boolean;
  onDelete: (a: NoteAttachment) => void;
  /** True when it put focus back in the strip. */
  onReturnFocus: (pictureId: string) => boolean;
}) {
  // The last picture stays while the viewer fades out.
  const [last, setLast] = React.useState(id);
  if (id && id !== last) setLast(id);
  const index = pictures.findIndex((x) => x.id === (id ?? last));
  const picture = pictures[index];
  const { blobUrl, error, retry } = useAttachmentBlob(
    noteId,
    picture?.id ?? "",
  );
  const swipe = React.useRef<{ x: number; y: number } | null>(null);

  const go = (step: number) => {
    if (pictures.length < 2) return;
    const next = pictures[(index + step + pictures.length) % pictures.length];
    onShow(next.id);
  };

  const download = () => {
    if (!blobUrl || !picture) return;
    const link = document.createElement("a");
    link.href = blobUrl;
    link.download = picture.originalFilename;
    link.click();
  };

  return (
    <DialogPrimitive.Root
      open={!!id && !!picture}
      onOpenChange={(open) => !open && onShow(null)}
    >
      <DialogPrimitive.Portal>
        {picture && (
          <DialogPrimitive.Content
            ref={toastHostRef}
            className="viewer"
            aria-describedby={undefined}
            onCloseAutoFocus={(e) => {
              if (onReturnFocus(picture.id)) e.preventDefault();
            }}
            onKeyDown={(e) => {
              if (e.key === "ArrowLeft") go(-1);
              else if (e.key === "ArrowRight") go(1);
            }}
          >
            <div className="vw-top">
              <div>
                <DialogPrimitive.Title className="vw-name">
                  {picture.originalFilename}
                </DialogPrimitive.Title>
                <div className="vw-count">
                  {index + 1} of {pictures.length}
                </div>
              </div>
              <div className="vw-actions">
                <button
                  type="button"
                  aria-label="Download"
                  onClick={download}
                  disabled={!blobUrl}
                >
                  <Download aria-hidden />
                  <span className="vw-lbl">Download</span>
                </button>
                {canDelete(picture) && (
                  <button
                    type="button"
                    aria-label="Delete"
                    onClick={() => onDelete(picture)}
                  >
                    <Trash2 aria-hidden />
                    <span className="vw-lbl">Delete</span>
                  </button>
                )}
                <DialogPrimitive.Close className="vw-x" aria-label="Close">
                  <X aria-hidden />
                </DialogPrimitive.Close>
              </div>
            </div>
            <div
              className="vw-stage"
              onPointerDown={(e) => {
                if (e.pointerType !== "mouse")
                  swipe.current = { x: e.clientX, y: e.clientY };
              }}
              onPointerUp={(e) => {
                const start = swipe.current;
                swipe.current = null;
                if (!start) return;
                const dx = e.clientX - start.x;
                if (
                  Math.abs(dx) > 50 &&
                  Math.abs(dx) > Math.abs(e.clientY - start.y)
                )
                  go(dx < 0 ? 1 : -1);
              }}
            >
              <button
                type="button"
                className="vw-nav"
                aria-label="Previous picture"
                disabled={pictures.length < 2}
                onClick={() => go(-1)}
              >
                <ChevronLeft aria-hidden />
              </button>
              <div className="vw-img">
                {error ? (
                  <div className="vw-fail">
                    <CircleAlert aria-hidden />
                    Couldn’t load the picture
                    <button type="button" onClick={retry}>
                      Try again
                    </button>
                  </div>
                ) : blobUrl ? (
                  <img
                    key={picture.id}
                    src={blobUrl}
                    alt={picture.originalFilename}
                  />
                ) : (
                  <div className="vw-wait" />
                )}
              </div>
              <button
                type="button"
                className="vw-nav"
                aria-label="Next picture"
                disabled={pictures.length < 2}
                onClick={() => go(1)}
              >
                <ChevronRight aria-hidden />
              </button>
            </div>
            <div className="vw-hint">
              <span className="dk">← → to move · Esc to close</span>
              <span className="ph">Swipe to move</span>
            </div>
          </DialogPrimitive.Content>
        )}
      </DialogPrimitive.Portal>
    </DialogPrimitive.Root>
  );
}
