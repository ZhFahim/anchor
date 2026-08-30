"use client";

import {
  AlertTriangle,
  CheckCircle2,
  ChevronDown,
  FileArchive,
  FileText,
  Loader2,
  type LucideIcon,
  Paperclip,
  Tag as TagIcon,
  Upload,
} from "lucide-react";
import { useCallback, useRef, useState } from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
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
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";
import type { PickedFile } from "../adapters/zip";
import type { ImportOptions } from "../hooks/use-import";
import { useImport } from "../hooks/use-import";
import { fromDataTransfer, fromFileList } from "../picked-files";

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
    options,
    setOption,
    previewTagCount,
    selectFiles,
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
          <DialogDescription>
            Restore an Anchor backup, migrate from Google Keep, or import
            Markdown files from Obsidian, Nextcloud Notes and the like.
          </DialogDescription>
        </DialogHeader>

        {step === "pick" && (
          <PickStep
            isDetecting={isDetecting}
            error={pickError}
            onFiles={selectFiles}
          />
        )}
        {step === "preview" && parsed && (
          <PreviewStep
            parsed={parsed}
            options={options}
            tagCount={previewTagCount}
            onOptionChange={setOption}
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
  onFiles,
}: {
  isDetecting: boolean;
  error: string | null;
  onFiles: (files: PickedFile[]) => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [isDragging, setIsDragging] = useState(false);

  const submit = useCallback(
    (picked: PickedFile[]) => {
      if (picked.length) onFiles(picked);
    },
    [onFiles],
  );

  const handleDrop = useCallback(
    (event: React.DragEvent) => {
      event.preventDefault();
      setIsDragging(false);
      // Entries must be read before the first await or the browser clears them
      fromDataTransfer(event.dataTransfer).then(submit);
    },
    [submit],
  );

  return (
    <div className="min-w-0 space-y-3">
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
        onDrop={handleDrop}
        onClick={() => inputRef.current?.click()}
      >
        {isDetecting ? (
          <Loader2 className="h-8 w-8 animate-spin" />
        ) : (
          <FileArchive className="h-8 w-8" />
        )}
        <span className="text-center">
          {isDetecting
            ? "Reading files..."
            : "Drop a zip or a folder here, or click to choose files"}
        </span>
        <input
          ref={inputRef}
          type="file"
          multiple
          accept=".zip,application/zip,.md,.markdown,text/markdown,image/*,audio/*"
          className="hidden"
          onChange={(e) => submit(fromFileList(e.target.files))}
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
  options,
  tagCount,
  onOptionChange,
  onConfirm,
  onCancel,
}: {
  parsed: NonNullable<ReturnType<typeof useImport>["parsed"]>;
  options: ImportOptions;
  tagCount: number;
  onOptionChange: ReturnType<typeof useImport>["setOption"];
  onConfirm: () => void;
  onCancel: () => void;
}) {
  return (
    <div className="min-w-0 space-y-4">
      <div className="flex items-center gap-2 text-sm text-muted-foreground">
        <FileArchive className="h-4 w-4 shrink-0" />
        <span>Detected format</span>
        <Badge variant="secondary">{parsed.formatLabel}</Badge>
      </div>
      <div className="grid grid-cols-3 gap-2">
        <PreviewStat
          icon={FileText}
          value={parsed.notes.length}
          singular="note"
          plural="notes"
        />
        <PreviewStat
          icon={TagIcon}
          value={tagCount}
          singular="tag"
          plural="tags"
        />
        <PreviewStat
          icon={Paperclip}
          value={parsed.attachmentCount}
          singular="attachment"
          plural="attachments"
        />
      </div>
      {parsed.skipped.length > 0 && (
        <SkippedList
          title={`${parsed.skipped.length} ${parsed.skipped.length === 1 ? "item" : "items"} will be skipped`}
          items={parsed.skipped}
        />
      )}
      {/* Only Anchor backups carry note ids, so only they can skip existing notes */}
      {parsed.formatId === "anchor" && (
        <ImportOption
          id="skip-existing-notes"
          label="Skip notes that already exist"
          checked={options.skipExisting}
          onChange={(value) => onOptionChange("skipExisting", value)}
        />
      )}
      {parsed.formatId === "markdown" && parsed.hasFolders && (
        <ImportOption
          id="folder-tags"
          label="Use folder names as tags"
          hint="Nextcloud categories and Obsidian folders become tags"
          checked={options.folderTags}
          onChange={(value) => onOptionChange("folderTags", value)}
        />
      )}
      <DialogFooter>
        <Button variant="outline" onClick={onCancel}>
          Cancel
        </Button>
        <Button onClick={onConfirm}>
          <Upload className="h-4 w-4 mr-2" />
          Import {parsed.notes.length}{" "}
          {parsed.notes.length === 1 ? "note" : "notes"}
        </Button>
      </DialogFooter>
    </div>
  );
}

function ImportOption({
  id,
  label,
  hint,
  checked,
  onChange,
}: {
  id: string;
  label: string;
  hint?: string;
  checked: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <div className="flex items-start gap-2">
      <Checkbox
        id={id}
        checked={checked}
        className="mt-0.5"
        onCheckedChange={(value) => onChange(value === true)}
      />
      <div className="space-y-0.5">
        <Label
          htmlFor={id}
          className="text-sm font-normal leading-snug cursor-pointer"
        >
          {label}
        </Label>
        {hint && <p className="text-xs text-muted-foreground">{hint}</p>}
      </div>
    </div>
  );
}

function PreviewStat({
  icon: Icon,
  value,
  singular,
  plural,
}: {
  icon: LucideIcon;
  value: number;
  singular: string;
  plural: string;
}) {
  return (
    <div className="flex flex-col items-center gap-0.5 rounded-lg border border-border/60 bg-muted/30 p-3">
      <Icon className="h-4 w-4 text-muted-foreground" />
      <span className="text-xl font-semibold leading-tight">{value}</span>
      <span className="text-xs text-muted-foreground">
        {value === 1 ? singular : plural}
      </span>
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
    <div className="min-w-0 space-y-4">
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
    <div className="min-w-0 space-y-4">
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
      {report.restoredTrashed && (
        <p className="text-xs text-muted-foreground">
          Restored trashed notes start a fresh 30-day trash window.
        </p>
      )}
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
    <Collapsible className="min-w-0 rounded-lg border border-amber-500/30 bg-amber-500/5 px-3 py-2">
      <CollapsibleTrigger className="group flex w-full items-center gap-2 text-sm text-amber-600 dark:text-amber-400 transition-opacity hover:opacity-80">
        <AlertTriangle className="h-4 w-4 shrink-0" />
        <span className="min-w-0 flex-1 text-left">{title}</span>
        <ChevronDown className="h-4 w-4 shrink-0 transition-transform group-data-[state=open]:rotate-180" />
      </CollapsibleTrigger>
      <CollapsibleContent>
        <ul className="mt-2 max-h-40 min-w-0 space-y-2 overflow-y-auto text-xs text-muted-foreground">
          {items.map((entry, index) => (
            <li key={`${entry.item}-${index}`} className="min-w-0">
              <p
                className="truncate font-medium text-foreground/80"
                title={entry.item}
              >
                {entry.item}
              </p>
              <p className="truncate" title={entry.reason}>
                {entry.reason}
              </p>
            </li>
          ))}
        </ul>
      </CollapsibleContent>
    </Collapsible>
  );
}
