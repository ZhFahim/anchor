"use client";

import { useRef, useState, useEffect, useCallback } from "react";
import { Play, Pause, Trash2, AlertCircle, RefreshCw, Volume2 } from "lucide-react";
import { useAttachmentBlob } from "../../hooks";
import type { NoteAttachment } from "../../types";
import { cn } from "@/lib/utils";

interface AudioAttachmentPlayerProps {
  noteId: string;
  attachment: NoteAttachment;
  canDelete: boolean;
  onDelete: (id: string) => void;
}

function formatTime(seconds: number): string {
  if (!isFinite(seconds) || isNaN(seconds)) return "0:00";
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, "0")}`;
}

export function AudioAttachmentPlayer({
  noteId,
  attachment,
  canDelete,
  onDelete,
}: AudioAttachmentPlayerProps) {
  const { blobUrl, isLoading, error, retry } = useAttachmentBlob(
    noteId,
    attachment.id
  );
  const audioRef = useRef<HTMLAudioElement>(null);
  const progressRef = useRef<HTMLDivElement>(null);

  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);

  const togglePlay = useCallback(() => {
    const audio = audioRef.current;
    if (!audio) return;

    if (isPlaying) {
      audio.pause();
    } else {
      audio.play();
    }
  }, [isPlaying]);

  const handleProgressClick = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      const audio = audioRef.current;
      const progressBar = progressRef.current;
      if (!audio || !progressBar || !duration) return;

      const rect = progressBar.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const percentage = clickX / rect.width;
      audio.currentTime = percentage * duration;
    },
    [duration]
  );

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const handlePlay = () => setIsPlaying(true);
    const handlePause = () => setIsPlaying(false);
    const handleEnded = () => {
      setIsPlaying(false);
      setCurrentTime(0);
    };
    const handleTimeUpdate = () => setCurrentTime(audio.currentTime);
    const handleLoadedMetadata = () => setDuration(audio.duration);

    audio.addEventListener("play", handlePlay);
    audio.addEventListener("pause", handlePause);
    audio.addEventListener("ended", handleEnded);
    audio.addEventListener("timeupdate", handleTimeUpdate);
    audio.addEventListener("loadedmetadata", handleLoadedMetadata);

    return () => {
      audio.removeEventListener("play", handlePlay);
      audio.removeEventListener("pause", handlePause);
      audio.removeEventListener("ended", handleEnded);
      audio.removeEventListener("timeupdate", handleTimeUpdate);
      audio.removeEventListener("loadedmetadata", handleLoadedMetadata);
    };
  }, [blobUrl]);

  const progress = duration > 0 ? (currentTime / duration) * 100 : 0;

  const truncatedName =
    attachment.originalFilename.length > 35
      ? attachment.originalFilename.slice(0, 32) + "..."
      : attachment.originalFilename;

  if (isLoading) {
    return (
      <div className="flex items-center gap-3 p-3 rounded-lg border border-border/40 bg-muted/30">
        <div className="w-9 h-9 rounded-full bg-muted flex items-center justify-center flex-shrink-0">
          <div className="w-4 h-4 rounded-full border-2 border-muted-foreground/30 border-t-muted-foreground animate-spin" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium truncate text-muted-foreground">
            Loading audio...
          </p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center gap-3 p-3 rounded-lg border border-destructive/30 bg-destructive/5">
        <div className="w-9 h-9 rounded-full bg-destructive/10 flex items-center justify-center flex-shrink-0">
          <AlertCircle className="h-4 w-4 text-destructive" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium truncate">{truncatedName}</p>
          <button
            onClick={retry}
            className="flex items-center gap-1 text-xs text-primary hover:underline mt-0.5"
          >
            <RefreshCw className="h-3 w-3" />
            Retry loading
          </button>
        </div>
        {canDelete && (
          <button
            onClick={() => onDelete(attachment.id)}
            className="p-1.5 rounded text-muted-foreground hover:text-destructive hover:bg-destructive/10 transition-colors flex-shrink-0"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        )}
      </div>
    );
  }

  return (
    <div className="flex items-center gap-3 p-3 rounded-lg border border-border/40 bg-muted/30 group">
      {/* Hidden audio element */}
      <audio ref={audioRef} src={blobUrl!} preload="metadata" />

      {/* Play/Pause button */}
      <button
        onClick={togglePlay}
        className={cn(
          "w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0 transition-colors",
          isPlaying
            ? "bg-primary text-primary-foreground"
            : "bg-primary/10 text-primary hover:bg-primary/20"
        )}
      >
        {isPlaying ? (
          <Pause className="h-4 w-4" />
        ) : (
          <Play className="h-4 w-4 ml-0.5" />
        )}
      </button>

      {/* Track info and progress */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-1.5">
          <Volume2 className="h-3 w-3 text-muted-foreground/60 flex-shrink-0" />
          <p
            className="text-sm font-medium truncate flex-1"
            title={attachment.originalFilename}
          >
            {truncatedName}
          </p>
          <span className="text-xs text-muted-foreground tabular-nums flex-shrink-0">
            {formatTime(currentTime)} / {formatTime(duration)}
          </span>
        </div>

        {/* Progress bar */}
        <div
          ref={progressRef}
          onClick={handleProgressClick}
          className="h-1.5 bg-muted rounded-full cursor-pointer group/progress"
        >
          <div
            className={cn(
              "h-full rounded-full transition-all relative",
              isPlaying ? "bg-primary" : "bg-primary/60"
            )}
            style={{ width: `${progress}%` }}
          >
            {/* Scrubber dot - visible on hover */}
            <div
              className={cn(
                "absolute right-0 top-1/2 -translate-y-1/2 w-3 h-3 rounded-full bg-primary shadow-sm",
                "opacity-0 group-hover/progress:opacity-100 transition-opacity",
                isPlaying && "opacity-100"
              )}
            />
          </div>
        </div>
      </div>

      {/* Delete button */}
      {canDelete && (
        <button
          onClick={() => onDelete(attachment.id)}
          className={cn(
            "p-1.5 rounded-full flex-shrink-0",
            "bg-black/50 hover:bg-red-500 text-white",
            "opacity-0 group-hover:opacity-100 transition-all duration-200",
            "hover:scale-110"
          )}
        >
          <Trash2 className="h-3.5 w-3.5" />
        </button>
      )}
    </div>
  );
}
