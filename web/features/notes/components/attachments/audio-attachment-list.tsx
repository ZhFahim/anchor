"use client";

import type { NoteAttachment } from "../../types";
import { AudioAttachmentPlayer } from "./audio-attachment-player";

interface AudioAttachmentListProps {
  noteId: string;
  attachments: NoteAttachment[];
  canDelete: boolean;
  onDelete: (id: string) => void;
}

export function AudioAttachmentList({
  noteId,
  attachments,
  canDelete,
  onDelete,
}: AudioAttachmentListProps) {
  return (
    <div className="mb-4">
      <p className="text-xs text-muted-foreground font-medium mb-2 uppercase tracking-wide">Audio</p>
      <div className="flex flex-col gap-2">
        {attachments.map((attachment) => (
          <AudioAttachmentPlayer
            key={attachment.id}
            noteId={noteId}
            attachment={attachment}
            canDelete={canDelete}
            onDelete={onDelete}
          />
        ))}
      </div>
    </div>
  );
}
