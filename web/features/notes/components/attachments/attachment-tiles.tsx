"use client";

import { CircleAlert, Pause, Play, X } from "lucide-react";
import * as React from "react";
import { cn } from "@/lib/utils";
import { useAttachmentBlob } from "../../hooks/use-attachment-blob";
import type { NoteAttachment } from "../../types";

export type Kind = "image" | "audio";

export interface Upload {
  key: string;
  file: File;
  kind: Kind;
  preview: string | null;
  /** 0 to 1, or null while the browser can't tell. */
  progress: number | null;
  failed: boolean;
  controller: AbortController;
}

const formatTime = (seconds: number) =>
  Number.isFinite(seconds)
    ? `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, "0")}`
    : "0:00";

function Ring({ progress, label }: { progress: number | null; label: string }) {
  return (
    <span
      className="t-ring"
      role="progressbar"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={progress == null ? undefined : Math.round(progress * 100)}
      data-unknown={progress == null || undefined}
      style={{ "--done": progress ?? 0.25 } as React.CSSProperties}
    >
      <svg viewBox="0 0 20 20" aria-hidden>
        <circle className="track" cx="10" cy="10" r="7.5" />
        <circle
          className="done"
          cx="10"
          cy="10"
          r="7.5"
          transform="rotate(-90 10 10)"
        />
      </svg>
    </span>
  );
}

interface TileProps {
  noteId: string;
  attachment: NoteAttachment;
  moving: boolean;
  onPointerDown: (e: React.PointerEvent<HTMLElement>) => void;
  onKeyDown: (e: React.KeyboardEvent) => void;
  onDelete?: () => void;
}

export function PictureTile({
  noteId,
  attachment,
  moving,
  onPointerDown,
  onKeyDown,
  onDelete,
  onOpen,
}: TileProps & { onOpen: () => void }) {
  const { blobUrl, error, retry } = useAttachmentBlob(noteId, attachment.id);
  const [isArriving] = React.useState(!blobUrl);
  const state = error ? "failed" : blobUrl ? "ready" : "loading";
  return (
    <div
      className={cn("att-tile", `st-${state}`)}
      data-flip={attachment.id}
      data-id={attachment.id}
      data-group="image"
      data-moving={moving || undefined}
      onPointerDown={onPointerDown}
    >
      <button
        type="button"
        className="t-open"
        aria-label={`${attachment.originalFilename}, open viewer`}
        disabled={state !== "ready"}
        onClick={onOpen}
        onKeyDown={onKeyDown}
      />
      {blobUrl && (
        <img
          className={cn("th", isArriving && "animate-fade-in")}
          src={blobUrl}
          alt=""
          draggable={false}
        />
      )}
      <div className="shimmer" />
      <div className="t-fail">
        <CircleAlert aria-hidden />
        <button
          type="button"
          onClick={retry}
          aria-label={`Try again, ${attachment.originalFilename}`}
        >
          Try again
        </button>
      </div>
      {onDelete && (
        <button
          type="button"
          className="t-x"
          aria-label={`Delete ${attachment.originalFilename}`}
          onClick={onDelete}
        >
          <X aria-hidden />
        </button>
      )}
    </div>
  );
}

export function VoiceCard({
  noteId,
  attachment,
  moving,
  onPointerDown,
  onKeyDown,
  onDelete,
}: TileProps) {
  const { blobUrl, error, retry } = useAttachmentBlob(noteId, attachment.id);
  const audio = React.useRef<HTMLAudioElement>(null);
  const bar = React.useRef<HTMLDivElement>(null);
  const [playing, setPlaying] = React.useState(false);
  const [position, setPosition] = React.useState(0);
  const [duration, setDuration] = React.useState(0);
  const state = error ? "failed" : blobUrl ? "ready" : "loading";
  const played = duration ? Math.min(1, position / duration) : 0;
  const name = attachment.originalFilename;

  const seek = (seconds: number) => {
    const el = audio.current;
    if (!el || !duration) return;
    el.currentTime = Math.max(0, Math.min(duration, seconds));
    setPosition(el.currentTime);
  };
  const seekTo = (x: number) => {
    const rect = bar.current?.getBoundingClientRect();
    if (rect) seek(((x - rect.left) / rect.width) * duration);
  };
  const measure = (el: HTMLAudioElement) =>
    setDuration(Number.isFinite(el.duration) ? el.duration : 0);

  return (
    <div
      className={cn("att-audio", `st-${state}`, playing && "playing")}
      data-flip={attachment.id}
      data-id={attachment.id}
      data-group="audio"
      data-moving={moving || undefined}
      style={{ "--p": `${played * 100}%` } as React.CSSProperties}
      onPointerDown={onPointerDown}
    >
      {blobUrl && (
        <audio
          ref={audio}
          src={blobUrl}
          preload="metadata"
          onLoadedMetadata={(e) => measure(e.currentTarget)}
          onDurationChange={(e) => measure(e.currentTarget)}
          onTimeUpdate={(e) => setPosition(e.currentTarget.currentTime)}
          onPlay={(e) => {
            for (const other of document.querySelectorAll("audio"))
              if (other !== e.currentTarget) other.pause();
            setPlaying(true);
          }}
          onPause={() => setPlaying(false)}
          onEnded={() => setPlaying(false)}
        />
      )}
      <div className="aa-top">
        <button
          type="button"
          className="play"
          aria-label={`${playing ? "Pause" : "Play"} ${name}`}
          disabled={state !== "ready"}
          onClick={() =>
            playing ? audio.current?.pause() : void audio.current?.play()
          }
          onKeyDown={onKeyDown}
        >
          {playing ? <Pause aria-hidden /> : <Play aria-hidden />}
        </button>
        <div className="aa-meta">
          <span className="aa-name" title={name}>
            {name}
          </span>
          <span className="a-time">
            {formatTime(position)}
            {duration ? ` / ${formatTime(duration)}` : ""}
          </span>
          <span className="a-fail">
            Couldn’t load
            <button
              type="button"
              onClick={retry}
              aria-label={`Try again, ${name}`}
            >
              Try again
            </button>
          </span>
        </div>
      </div>
      <div
        ref={bar}
        className="a-bar"
        role="slider"
        tabIndex={state === "ready" ? 0 : -1}
        aria-disabled={state !== "ready" || undefined}
        aria-label={`${name} position`}
        aria-valuemin={0}
        aria-valuemax={Math.round(duration)}
        aria-valuenow={Math.round(position)}
        aria-valuetext={`${formatTime(position)} of ${formatTime(duration)}`}
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId);
          seekTo(e.clientX);
        }}
        onPointerMove={(e) =>
          e.currentTarget.hasPointerCapture(e.pointerId) && seekTo(e.clientX)
        }
        // Left and Right move along the attachments row.
        onKeyDown={(e) => {
          const step = { ArrowUp: 5, ArrowDown: -5 }[e.key];
          if (e.key === "Home") seek(0);
          else if (e.key === "End") seek(duration);
          else if (step && !e.altKey) seek(position + step);
          else return;
          e.preventDefault();
        }}
      >
        <span className="a-fill" />
        <span className="a-knob" />
      </div>
      {onDelete && (
        <button
          type="button"
          className="t-x"
          aria-label={`Delete ${name}`}
          onClick={onDelete}
        >
          <X aria-hidden />
        </button>
      )}
    </div>
  );
}

export function UploadTile({
  upload,
  onRetry,
  onCancel,
}: {
  upload: Upload;
  onRetry: () => void;
  onCancel: () => void;
}) {
  const name = upload.file.name;
  const cancelButton = (
    <button
      type="button"
      className="t-x"
      aria-label={upload.failed ? `Remove ${name}` : `Cancel ${name}`}
      onClick={onCancel}
    >
      <X aria-hidden />
    </button>
  );
  if (upload.kind === "audio")
    return (
      <div
        className={cn(
          "att-audio",
          upload.failed ? "st-failed" : "st-uploading",
        )}
        data-flip={upload.key}
        data-group="audio"
        data-upload
        style={
          { "--p": `${(upload.progress ?? 0) * 100}%` } as React.CSSProperties
        }
      >
        <div className="aa-top">
          <span className="play" aria-hidden>
            <Play />
          </span>
          <div className="aa-meta">
            <span className="aa-name">{name}</span>
            <span className="a-time">Uploading…</span>
          </div>
        </div>
        <div
          className="a-bar"
          data-unknown={upload.progress == null || undefined}
        >
          <span className="a-fill" />
        </div>
        <span className="a-fail">
          Couldn’t upload
          <button
            type="button"
            onClick={onRetry}
            aria-label={`Try again, ${name}`}
          >
            Try again
          </button>
        </span>
        {cancelButton}
      </div>
    );
  return (
    <div
      className={cn("att-tile", upload.failed ? "st-failed" : "st-uploading")}
      data-flip={upload.key}
      data-group="image"
      data-upload
    >
      {upload.preview && (
        <img className="th" src={upload.preview} alt="" draggable={false} />
      )}
      <Ring progress={upload.progress} label={`Uploading ${name}`} />
      <div className="t-fail">
        <CircleAlert aria-hidden />
        <button
          type="button"
          onClick={onRetry}
          aria-label={`Try again, ${name}`}
        >
          Try again
        </button>
      </div>
      {cancelButton}
    </div>
  );
}
