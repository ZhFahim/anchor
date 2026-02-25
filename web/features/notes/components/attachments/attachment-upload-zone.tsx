"use client";

import { useRef, useState, useCallback } from "react";
import { Paperclip } from "lucide-react";
import { cn } from "@/lib/utils";
import { ACCEPTED_TYPES_STRING, isAcceptedAttachmentType } from "../../constants";

interface AttachmentUploadZoneProps {
  onFiles: (files: File[]) => void;
}

export function AttachmentUploadZone({ onFiles }: AttachmentUploadZoneProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);

  const handleFiles = useCallback(
    (fileList: FileList | null) => {
      if (!fileList) return;
      const files = Array.from(fileList).filter(isAcceptedAttachmentType);
      if (files.length > 0) onFiles(files);
    },
    [onFiles]
  );

  const onDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const onDragLeave = () => setIsDragging(false);

  const onDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    handleFiles(e.dataTransfer.files);
  };

  return (
    <div
      className={cn(
        "border-2 border-dashed rounded-lg p-4 mb-4 flex items-center gap-3 cursor-pointer",
        "text-muted-foreground text-sm transition-colors duration-150",
        isDragging
          ? "border-primary bg-primary/5 text-primary"
          : "border-border/60 hover:border-border hover:bg-muted/30"
      )}
      onDragOver={onDragOver}
      onDragLeave={onDragLeave}
      onDrop={onDrop}
      onClick={() => inputRef.current?.click()}
    >
      <Paperclip className="h-4 w-4 flex-shrink-0" />
      <span>Attach images or audio — drag & drop or click to browse</span>
      <input
        ref={inputRef}
        type="file"
        accept={ACCEPTED_TYPES_STRING}
        multiple
        className="hidden"
        onChange={(e) => handleFiles(e.target.files)}
      />
    </div>
  );
}
