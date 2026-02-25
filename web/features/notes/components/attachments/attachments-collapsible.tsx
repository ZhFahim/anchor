"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useState, useCallback } from "react";
import { toast } from "sonner";
import { Paperclip, ChevronDown, Plus } from "lucide-react";
import { cn } from "@/lib/utils";
import { ConfirmationDialog } from "@/components/ui/confirmation-dialog";
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible";
import {
  getNoteAttachments,
  uploadAttachment,
  deleteAttachment,
  reorderAttachments,
} from "../../api";
import type { NoteAttachment } from "../../types";
import { useAttachmentBlob } from "../../hooks";
import { AttachmentUploadZone } from "./attachment-upload-zone";
import { ImageAttachmentGrid } from "./image-attachment-grid";
import { AudioAttachmentList } from "./audio-attachment-list";

interface AttachmentsCollapsibleProps {
  noteId: string;
  canUpload: boolean;
  canDelete: boolean;
}

export function AttachmentsCollapsible({
  noteId,
  canUpload,
  canDelete,
}: AttachmentsCollapsibleProps) {
  const queryClient = useQueryClient();
  const [isOpen, setIsOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<NoteAttachment | null>(null);

  const { data: attachments = [] } = useQuery({
    queryKey: ["attachments", noteId],
    queryFn: () => getNoteAttachments(noteId),
    enabled: !!noteId,
  });

  const deleteMutation = useMutation({
    mutationFn: ({ attachmentId }: { attachmentId: string }) =>
      deleteAttachment(noteId, attachmentId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["attachments", noteId] });
      queryClient.invalidateQueries({ queryKey: ["notes"] });
      setDeleteTarget(null);
      toast.success("Attachment deleted");
    },
    onError: () => {
      setDeleteTarget(null);
      toast.error("Failed to delete attachment");
    },
  });

  const reorderMutation = useMutation({
    mutationFn: (orderedIds: string[]) => reorderAttachments(noteId, orderedIds),
    onMutate: async (orderedIds) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: ["attachments", noteId] });

      // Snapshot the previous value
      const previousAttachments = queryClient.getQueryData<NoteAttachment[]>(["attachments", noteId]);

      // Optimistically update to the new order
      if (previousAttachments) {
        const reordered = orderedIds
          .map((id) => previousAttachments.find((a) => a.id === id))
          .filter((a): a is NoteAttachment => a !== undefined);
        queryClient.setQueryData(["attachments", noteId], reordered);
      }

      return { previousAttachments };
    },
    onError: (_err, _orderedIds, context) => {
      // Roll back to the previous value on error
      if (context?.previousAttachments) {
        queryClient.setQueryData(["attachments", noteId], context.previousAttachments);
      }
      toast.error("Failed to reorder attachments");
    },
    onSettled: () => {
      // Sync with server state after mutation settles
      queryClient.invalidateQueries({ queryKey: ["attachments", noteId] });
    },
  });

  const handleDeleteRequest = useCallback(
    (id: string) => {
      const attachment = attachments.find((a) => a.id === id);
      if (attachment) {
        setDeleteTarget(attachment);
      }
    },
    [attachments]
  );

  const handleDeleteConfirm = useCallback(() => {
    if (deleteTarget) {
      deleteMutation.mutate({ attachmentId: deleteTarget.id });
    }
  }, [deleteTarget, deleteMutation]);

  const handleFiles = useCallback(
    async (files: File[]) => {
      if (files.length === 0) return;

      const invalidate = () => {
        queryClient.invalidateQueries({ queryKey: ["attachments", noteId] });
        queryClient.invalidateQueries({ queryKey: ["notes"] });
      };

      const count = files.length;
      const loadingMessage =
        count === 1 ? `Uploading ${files[0].name}...` : `Uploading ${count} files...`;

      toast.promise(
        (async () => {
          const results = await Promise.allSettled(
            files.map((file) => uploadAttachment(noteId, file))
          );
          const succeeded = results.filter((r) => r.status === "fulfilled").length;
          const failed = results.filter((r) => r.status === "rejected").length;

          invalidate();

          if (failed > 0) {
            const firstError = results.find((r) => r.status === "rejected");
            const message =
              failed === count
                ? firstError?.status === "rejected"
                  ? firstError.reason instanceof Error
                    ? firstError.reason.message
                    : "Upload failed"
                  : "Upload failed"
                : `${succeeded} of ${count} uploaded (${failed} failed)`;
            throw new Error(message);
          }

          return count === 1
            ? `${files[0].name} uploaded`
            : `${count} files uploaded`;
        })(),
        {
          loading: loadingMessage,
          success: (msg) => msg,
          error: (err) => (err instanceof Error ? err.message : "Upload failed"),
        }
      );
    },
    [noteId, queryClient]
  );

  const imageAttachments = attachments.filter((a) => a.type === "image");
  const audioAttachments = attachments.filter((a) => a.type === "audio");
  const hasAttachments = attachments.length > 0;
  const previewImages = imageAttachments.slice(0, 4);
  const remainingCount = attachments.length - previewImages.length;

  // Don't render anything if no attachments and can't upload
  if (!hasAttachments && !canUpload) return null;

  return (
    <>
      <Collapsible open={isOpen} onOpenChange={setIsOpen}>
        <CollapsibleTrigger asChild>
          <button
            className={cn(
              "w-full flex items-center gap-3 py-2.5 px-3 rounded-md transition-colors",
              "hover:bg-muted/50 group text-left",
              !hasAttachments && "mx-0 justify-center border-2 border-dashed border-border/50 hover:border-border/80 py-3"
            )}
          >
            {hasAttachments ? (
              <>
                <Paperclip className="h-4 w-4 text-muted-foreground/70 flex-shrink-0" />

                {/* Thumbnail previews */}
                <div className="flex items-center gap-1 flex-shrink-0">
                  {previewImages.map((attachment) => (
                    <ThumbnailPreview
                      key={attachment.id}
                      noteId={noteId}
                      attachment={attachment}
                    />
                  ))}
                </div>

                {/* Count text */}
                <span className="text-sm text-muted-foreground/80">
                  {attachments.length} {attachments.length === 1 ? "attachment" : "attachments"}
                  {remainingCount > 0 && previewImages.length > 0 && (
                    <span className="text-muted-foreground/50"> (+{remainingCount} more)</span>
                  )}
                </span>

                <ChevronDown
                  className={cn(
                    "h-4 w-4 text-muted-foreground/60 ml-auto transition-transform duration-200",
                    isOpen && "rotate-180"
                  )}
                />
              </>
            ) : (
              <>
                <Plus className="h-4 w-4 text-muted-foreground/70" />
                <span className="text-sm text-muted-foreground/70">Add attachments</span>
              </>
            )}
          </button>
        </CollapsibleTrigger>

        <CollapsibleContent forceMount className={cn("pt-3", !isOpen && "hidden")}>
          {canUpload && <AttachmentUploadZone onFiles={handleFiles} />}

          {imageAttachments.length > 0 && (
            <ImageAttachmentGrid
              noteId={noteId}
              attachments={imageAttachments}
              canDelete={canDelete}
              canReorder={canUpload}
              onDelete={handleDeleteRequest}
              onReorder={(orderedImageIds) => {
                const fullOrderedIds = [
                  ...orderedImageIds,
                  ...audioAttachments.map((a) => a.id),
                ];
                reorderMutation.mutate(fullOrderedIds);
              }}
            />
          )}

          {audioAttachments.length > 0 && (
            <AudioAttachmentList
              noteId={noteId}
              attachments={audioAttachments}
              canDelete={canDelete}
              onDelete={handleDeleteRequest}
            />
          )}
        </CollapsibleContent>
      </Collapsible>

      <ConfirmationDialog
        open={deleteTarget !== null}
        onOpenChange={(open) => !open && setDeleteTarget(null)}
        onConfirm={handleDeleteConfirm}
        title="Delete attachment?"
        description={
          <>
            This will permanently delete{" "}
            <span className="font-medium">
              {deleteTarget?.originalFilename}
            </span>
            . This action cannot be undone.
          </>
        }
        confirmLabel="Delete"
        variant="destructive"
        isPending={deleteMutation.isPending}
      />
    </>
  );
}

// Small thumbnail preview for collapsed state
function ThumbnailPreview({
  noteId,
  attachment,
}: {
  noteId: string;
  attachment: NoteAttachment;
}) {
  const { blobUrl, isLoading } = useAttachmentBlob(noteId, attachment.id);

  return (
    <div className="w-8 h-8 rounded overflow-hidden bg-muted flex-shrink-0">
      {isLoading ? (
        <div className="w-full h-full animate-pulse bg-muted-foreground/10" />
      ) : blobUrl ? (
        <img
          src={blobUrl}
          alt=""
          className="w-full h-full object-cover"
        />
      ) : (
        <div className="w-full h-full bg-muted-foreground/10" />
      )}
    </div>
  );
}
