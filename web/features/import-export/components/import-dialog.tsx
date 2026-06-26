"use client";

import {
  AlertTriangle,
  CheckCircle2,
  ChevronDown,
  FileArchive,
  Loader2,
  Upload,
} from "lucide-react";
import { useCallback, useRef, useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";
import { useImport } from "../hooks/use-import";

interface ImportDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function ImportDialog({ open, onOpenChange }: ImportDialogProps) {
  const {
    step,
    parsed,
    isDetecting,
    pickError,
    runError,
    progress,
    report,
    isRunning,
    selectFile,
    start,
    retry,
    reset,
  } = useImport();

  const handleOpenChange = (next: boolean) => {
    // Don't allow closing mid-import
    if (!next && isRunning) return;
    if (!next) reset();
    onOpenChange(next);
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Import notes</DialogTitle>
          <DialogDescription>Restore an Anchor backup (zip).</DialogDescription>
        </DialogHeader>

        {step === "pick" && (
          <PickStep
            isDetecting={isDetecting}
            error={pickError}
            onFile={selectFile}
          />
        )}
        {step === "preview" && parsed && (
          <PreviewStep
            parsed={parsed}
            onConfirm={start}
            onCancel={() => handleOpenChange(false)}
          />
        )}
        {step === "running" && (
          <RunningStep progress={progress} error={runError} onRetry={retry} />
        )}
        {step === "report" && report && (
          <ReportStep report={report} onClose={() => handleOpenChange(false)} />
        )}
      </DialogContent>
    </Dialog>
  );
}

function PickStep({
  isDetecting,
  error,
  onFile,
}: {
  isDetecting: boolean;
  error: string | null;
  onFile: (file: File) => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);

  const handleFiles = useCallback(
    (files: FileList | null) => {
      const file = files?.[0];
      if (file) onFile(file);
    },
    [onFile],
  );

  return (
    <div className="space-y-3">
      <div
        className={cn(
          "border-2 border-dashed rounded-lg p-8 flex flex-col items-center gap-3 cursor-pointer",
          "text-muted-foreground text-sm transition-colors duration-150",
          isDragging
            ? "border-primary bg-primary/5 text-primary"
            : "border-border/60 hover:border-border hover:bg-muted/30",
        )}
        onDragOver={(e) => {
          e.preventDefault();
          setIsDragging(true);
        }}
        onDragLeave={() => setIsDragging(false)}
        onDrop={(e) => {
          e.preventDefault();
          setIsDragging(false);
          handleFiles(e.dataTransfer.files);
        }}
        onClick={() => inputRef.current?.click()}
      >
        {isDetecting ? (
          <Loader2 className="h-8 w-8 animate-spin" />
        ) : (
          <FileArchive className="h-8 w-8" />
        )}
        <span className="text-center">
          {isDetecting
            ? "Reading file..."
            : "Drop a zip file here, or click to browse"}
        </span>
        <input
          ref={inputRef}
          type="file"
          accept=".zip,application/zip"
          className="hidden"
          onChange={(e) => handleFiles(e.target.files)}
        />
      </div>
      {error && (
        <p className="text-sm text-destructive flex items-start gap-2">
          <AlertTriangle className="h-4 w-4 mt-0.5 shrink-0" />
          {error}
        </p>
      )}
    </div>
  );
}

function PreviewStep({
  parsed,
  onConfirm,
  onCancel,
}: {
  parsed: NonNullable<ReturnType<typeof useImport>["parsed"]>;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <Badge variant="secondary">{parsed.formatLabel}</Badge>
      </div>
      <div className="text-sm space-y-1">
        <p>
          <span className="font-medium">{parsed.notes.length}</span>{" "}
          {parsed.notes.length === 1 ? "note" : "notes"}
          {parsed.tags.length > 0 && (
            <>
              {" "}
              · <span className="font-medium">{parsed.tags.length}</span>{" "}
              {parsed.tags.length === 1 ? "tag" : "tags"}
            </>
          )}
          {parsed.attachmentCount > 0 && (
            <>
              {" "}
              · <span className="font-medium">{parsed.attachmentCount}</span>{" "}
              {parsed.attachmentCount === 1 ? "attachment" : "attachments"}
            </>
          )}
        </p>
      </div>
      {parsed.skipped.length > 0 && (
        <SkippedList
          title={`${parsed.skipped.length} ${parsed.skipped.length === 1 ? "item" : "items"} will be skipped`}
          items={parsed.skipped}
        />
      )}
      <DialogFooter>
        <Button variant="outline" onClick={onCancel}>
          Cancel
        </Button>
        <Button onClick={onConfirm}>
          <Upload className="h-4 w-4 mr-2" />
          Import
        </Button>
      </DialogFooter>
    </div>
  );
}

function RunningStep({
  progress,
  error,
  onRetry,
}: {
  progress: {
    phase: "notes" | "attachments";
    done: number;
    total: number;
  } | null;
  error: string | null;
  onRetry: () => void;
}) {
  const percent =
    progress && progress.total > 0
      ? Math.round((progress.done / progress.total) * 100)
      : 0;
  const label =
    progress?.phase === "attachments"
      ? `Uploading attachments ${progress.done}/${progress.total}`
      : `Importing notes ${progress?.done ?? 0}/${progress?.total ?? 0}`;

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <span className="flex items-center gap-2">
            {!error && <Loader2 className="h-4 w-4 animate-spin" />}
            {label}
          </span>
          <span>{percent}%</span>
        </div>
        <div className="h-2 w-full rounded-full bg-muted overflow-hidden">
          <div
            className="h-full rounded-full bg-primary transition-all duration-300"
            style={{ width: `${percent}%` }}
          />
        </div>
      </div>
      {error && (
        <div className="space-y-3">
          <p className="text-sm text-destructive flex items-start gap-2">
            <AlertTriangle className="h-4 w-4 mt-0.5 shrink-0" />
            {error}
          </p>
          <DialogFooter>
            <Button onClick={onRetry}>Retry</Button>
          </DialogFooter>
        </div>
      )}
      {!error && (
        <p className="text-xs text-muted-foreground">
          Keep this dialog open until the import finishes.
        </p>
      )}
    </div>
  );
}

function ReportStep({
  report,
  onClose,
}: {
  report: NonNullable<ReturnType<typeof useImport>["report"]>;
  onClose: () => void;
}) {
  const summary: string[] = [];
  if (report.created) summary.push(`${report.created} imported`);
  if (report.remapped) summary.push(`${report.remapped} imported as copies`);
  if (report.skipped) summary.push(`${report.skipped} already existed`);
  if (report.failed) summary.push(`${report.failed} failed`);
  if (report.attachmentsUploaded)
    summary.push(`${report.attachmentsUploaded} attachments uploaded`);
  if (report.attachmentsFailed)
    summary.push(`${report.attachmentsFailed} attachments failed`);

  return (
    <div className="space-y-4">
      <p className="text-sm flex items-start gap-2">
        {report.failed || report.attachmentsFailed ? (
          <AlertTriangle className="h-4 w-4 mt-0.5 text-amber-500 shrink-0" />
        ) : (
          <CheckCircle2 className="h-4 w-4 mt-0.5 text-green-500 shrink-0" />
        )}
        {summary.join(" · ") || "Nothing to import"}
      </p>
      {report.issues.length > 0 && (
        <SkippedList
          title={`${report.issues.length} ${report.issues.length === 1 ? "item needs" : "items need"} attention`}
          items={report.issues}
        />
      )}
      <p className="text-xs text-muted-foreground">
        Restored trashed notes start a fresh 30-day trash window. On mobile
        devices, sign out and back in to see imported notes.
      </p>
      <DialogFooter>
        <Button onClick={onClose}>Done</Button>
      </DialogFooter>
    </div>
  );
}

function SkippedList({
  title,
  items,
}: {
  title: string;
  items: { item: string; reason: string }[];
}) {
  return (
    <Collapsible>
      <CollapsibleTrigger className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors">
        <ChevronDown className="h-4 w-4" />
        {title}
      </CollapsibleTrigger>
      <CollapsibleContent>
        <ul className="mt-2 max-h-40 overflow-y-auto space-y-1 text-xs text-muted-foreground">
          {items.map((entry, index) => (
            <li key={`${entry.item}-${index}`} className="truncate">
              <span className="font-medium">{entry.item}</span> — {entry.reason}
            </li>
          ))}
        </ul>
      </CollapsibleContent>
    </Collapsible>
  );
}
