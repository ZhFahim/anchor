"use client";

import {
  ChevronDown,
  CircleAlert,
  CircleCheck,
  FileArchive,
  Folder,
  LoaderCircle,
  RotateCw,
  TriangleAlert,
  Upload,
} from "lucide-react";
import * as React from "react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Dialog,
  DialogBody,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { FieldDescription, FieldError } from "@/components/ui/field";
import { cn, plural } from "@/lib/utils";
import type { PickedFile } from "../adapters/zip";
import { type ImportReport, useImport } from "../hooks/use-import";
import {
  fromDataTransfer,
  fromFileList,
  MAX_PICKED_FILES,
} from "../picked-files";
import type { ImportSkippedItem } from "../types";

interface ImportDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

/** “takeout.zip”, “Obsidian vault” (a folder), or “12 files”. */
function pickedName(files: PickedFile[]) {
  if (files.length === 1) return files[0].file.name;
  const roots = new Set(files.map((f) => f.path.split("/")[0]));
  return roots.size === 1 && files[0].path.includes("/")
    ? [...roots][0]
    : plural(files.length, "file");
}

export function ImportDialog({ open, onOpenChange }: ImportDialogProps) {
  const importer = useImport();
  const [name, setName] = React.useState("");
  const [isFolder, setIsFolder] = React.useState(false);
  const [isTruncated, setIsTruncated] = React.useState(false);

  const close = (next: boolean) => {
    if (!next && importer.isRunning) return;
    if (!next) importer.reset();
    onOpenChange(next);
  };

  const pick = (files: PickedFile[], isDropTruncated = false) => {
    if (!files.length) return;
    setName(pickedName(files));
    setIsFolder(files.length > 1 && files[0].path.includes("/"));
    setIsTruncated(isDropTruncated);
    importer.selectFiles(files);
  };

  const { step, parsed, progress, report } = importer;
  const stopped = step === "running" && !!importer.runError;

  return (
    <Dialog open={open} onOpenChange={close}>
      <DialogContent
        size="md"
        showClose={!importer.isRunning}
        onEscapeKeyDown={(e) => importer.isRunning && e.preventDefault()}
      >
        <DialogHeader>
          <DialogTitle>Import notes</DialogTitle>
          <DialogDescription>
            Import from an Anchor backup, a Google Keep export, or Markdown
            files.
          </DialogDescription>
        </DialogHeader>
        <DialogBody className="gap-3">
          {step === "pick" && (
            <DropArea
              reading={importer.isDetecting}
              name={name}
              error={importer.pickError}
              onFiles={pick}
            />
          )}

          {step === "preview" && parsed && (
            <>
              <div className="flex items-center gap-3 rounded-xl bg-muted px-3.5 py-3 [&>svg]:size-5.5 [&>svg]:text-muted-foreground">
                {isFolder ? (
                  <Folder aria-hidden />
                ) : (
                  <FileArchive aria-hidden />
                )}
                <div className="grid flex-1 leading-[1.35]">
                  <b className="truncate font-semibold text-ui">{name}</b>
                  <small className="text-muted-foreground text-small">
                    {parsed.formatLabel}
                  </small>
                </div>
                <Button variant="quiet" size="sm" onClick={importer.reset}>
                  Change
                </Button>
              </div>
              <div className="grid grid-cols-3 gap-2">
                <Stat count={parsed.notes.length} one="note" />
                <Stat count={importer.previewTagCount} one="tag" />
                <Stat count={parsed.attachmentCount} one="attachment" />
              </div>
              {isTruncated && (
                <FieldDescription>
                  {`Only the first ${MAX_PICKED_FILES.toLocaleString("en-US")} files were read.`}
                </FieldDescription>
              )}
              {parsed.skipped.length > 0 && (
                <Issues
                  title={`${plural(parsed.skipped.length, "item")} will be skipped`}
                  items={parsed.skipped}
                />
              )}
              {parsed.formatId === "anchor" && (
                <CheckRow
                  checked={importer.options.skipExisting}
                  onChange={(v) => importer.setOption("skipExisting", v)}
                  label="Skip notes that already exist"
                  hint="Otherwise they are imported as copies."
                />
              )}
              {parsed.formatId === "markdown" && parsed.hasFolders && (
                <CheckRow
                  checked={importer.options.folderTags}
                  onChange={(v) => importer.setOption("folderTags", v)}
                  label="Use folder names as tags"
                  hint="Nextcloud categories and Obsidian folders become tags."
                />
              )}
            </>
          )}

          {step === "running" && (
            <div className="grid gap-2">
              <div className="flex justify-between font-medium text-control tabular-nums">
                <span>
                  {progress?.phase === "attachments"
                    ? `Uploading attachments ${progress.done} of ${progress.total}`
                    : `Importing notes ${progress?.done ?? 0} of ${progress?.total ?? parsed?.notes.length ?? 0}`}
                </span>
                <span>
                  {progress?.total
                    ? Math.round((progress.done / progress.total) * 100)
                    : 0}
                  %
                </span>
              </div>
              <div
                role="progressbar"
                aria-label="Import"
                aria-valuemin={0}
                aria-valuemax={progress?.total ?? 0}
                aria-valuenow={progress?.done ?? 0}
                className="h-1.5 overflow-hidden rounded-xs bg-muted"
              >
                <div
                  className={cn(
                    "h-full rounded-xs bg-accent-strong transition-[width] duration-(--duration-slow) ease-standard",
                    stopped && "bg-muted-foreground",
                  )}
                  style={{
                    width: `${progress?.total ? (progress.done / progress.total) * 100 : 0}%`,
                  }}
                />
              </div>
              {stopped ? (
                <FieldError>{importer.runError}</FieldError>
              ) : (
                <FieldDescription>
                  Keep this tab open until the import finishes.
                </FieldDescription>
              )}
            </div>
          )}

          {step === "report" && report && <Report report={report} />}
        </DialogBody>
        <DialogFooter>
          {step === "pick" && (
            <Button variant="quiet" onClick={() => close(false)}>
              Cancel
            </Button>
          )}
          {step === "preview" && parsed && (
            <>
              <Button variant="quiet" onClick={() => close(false)}>
                Cancel
              </Button>
              <Button onClick={importer.start} disabled={!parsed.notes.length}>
                <Upload aria-hidden />
                Import {plural(parsed.notes.length, "note")}
              </Button>
            </>
          )}
          {stopped && (
            <>
              <Button variant="quiet" onClick={() => close(false)}>
                Close
              </Button>
              <Button onClick={importer.retry}>
                <RotateCw aria-hidden />
                Try again
              </Button>
            </>
          )}
          {step === "report" && (
            <Button onClick={() => close(false)}>Done</Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function DropArea({
  reading,
  name,
  error,
  onFiles,
}: {
  reading: boolean;
  name: string;
  error: string | null;
  onFiles: (files: PickedFile[], isTruncated?: boolean) => void;
}) {
  const inputRef = React.useRef<HTMLInputElement>(null);
  const [dragOver, setDragOver] = React.useState(false);
  const errorId = React.useId();
  const isMountedRef = React.useRef(false);
  React.useEffect(() => {
    isMountedRef.current = true;
    return () => {
      isMountedRef.current = false;
    };
  }, []);
  return (
    <>
      {/* biome-ignore lint/a11y/useSemanticElements: a drop area that also opens the file picker */}
      <div
        role="button"
        tabIndex={0}
        aria-busy={reading || undefined}
        aria-describedby={error ? errorId : undefined}
        onClick={() => !reading && inputRef.current?.click()}
        onKeyDown={(e) => {
          if ((e.key === "Enter" || e.key === " ") && !reading) {
            e.preventDefault();
            inputRef.current?.click();
          }
        }}
        onDragOver={(e) => {
          e.preventDefault();
          setDragOver(true);
        }}
        onDragLeave={() => setDragOver(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragOver(false);
          // Entries must be read before the first await, or the browser clears them.
          void fromDataTransfer(e.dataTransfer).then(
            ({ files, isTruncated }) => {
              // A large folder can still be walking after the dialog closed
              if (isMountedRef.current) onFiles(files, isTruncated);
            },
          );
        }}
        className={cn(
          "grid cursor-pointer justify-items-center gap-2 rounded-2xl border-[1.5px] border-muted-foreground/55 border-dashed px-5 py-8 text-center transition-colors duration-(--duration-hover) hover:bg-foreground/3 hover:not-focus-visible:border-accent-strong hover:[&>svg]:text-accent-strong [&>svg]:size-7.5 [&>svg]:text-muted-foreground [&>svg]:transition-colors [&>svg]:duration-(--duration-hover)",
          dragOver &&
            "border-accent-strong bg-accent/7 [&>svg]:text-accent-strong",
          error &&
            "border-destructive hover:not-focus-visible:border-destructive",
          reading &&
            "cursor-progress border-muted-foreground/30 border-solid bg-foreground/3 hover:not-focus-visible:border-muted-foreground/30 hover:[&>svg]:text-muted-foreground [&>svg]:size-6.5",
        )}
      >
        {reading ? (
          <>
            <LoaderCircle aria-hidden className="animate-spin" />
            <b className="font-semibold text-lead">Reading {name}…</b>
            <span className="text-meta text-muted-foreground">
              Large exports can take a few seconds.
            </span>
          </>
        ) : (
          <>
            <FileArchive aria-hidden />
            <b className="font-semibold text-lead">
              Drop a zip or a folder here
            </b>
            <span className="text-meta text-muted-foreground">
              or click to choose files
            </span>
            <span className="mt-1 flex flex-wrap justify-center gap-1.5">
              <Badge className="bg-foreground/5">Anchor backup</Badge>
              <Badge className="bg-foreground/5">Google Keep</Badge>
              <Badge className="bg-foreground/5">Markdown</Badge>
            </span>
          </>
        )}
        <input
          ref={inputRef}
          type="file"
          multiple
          hidden
          accept=".zip,application/zip,.md,.markdown,text/markdown,image/*,audio/*"
          onChange={(e) => {
            const files = fromFileList(e.target.files);
            e.target.value = "";
            onFiles(files);
          }}
        />
      </div>
      {error && <FieldError id={errorId}>{error}</FieldError>}
    </>
  );
}

function Stat({ count, one }: { count: number; one: string }) {
  return (
    <div className="grid gap-0.5 rounded-xl px-3.5 py-3 shadow-[inset_0_0_0_1px_color-mix(in_srgb,var(--border)_70%,transparent)]">
      <b className="text-page tabular-nums">{count}</b>
      <span className="text-muted-foreground text-small">
        {count === 1 ? one : `${one}s`}
      </span>
    </div>
  );
}

function CheckRow({
  checked,
  onChange,
  label,
  hint,
}: {
  checked: boolean;
  onChange: (value: boolean) => void;
  label: string;
  hint: string;
}) {
  const id = React.useId();
  return (
    <div className="flex items-start gap-2.5 text-ui">
      <Checkbox
        id={id}
        checked={checked}
        onCheckedChange={(v) => onChange(v === true)}
        className="mt-px"
      />
      <label htmlFor={id} className="cursor-pointer">
        {label}
        <small className="mt-0.5 block text-muted-foreground text-small">
          {hint}
        </small>
      </label>
    </div>
  );
}

function Issues({
  title,
  items,
  open,
}: {
  title: string;
  items: ImportSkippedItem[];
  open?: boolean;
}) {
  return (
    <details
      open={open}
      className="group rounded-lg bg-warn text-meta text-warn-foreground"
    >
      <summary className="flex cursor-pointer list-none items-center gap-2 px-3 py-2.5 font-semibold [&::-webkit-details-marker]:hidden [&>svg]:size-3.75">
        <TriangleAlert aria-hidden />
        {title}
        <ChevronDown
          aria-hidden
          className="ml-auto transition-transform duration-(--duration-fade) group-open:rotate-180"
        />
      </summary>
      <ul className="m-0 grid max-h-44 gap-1 overflow-auto pr-3 pb-2.5 pl-8">
        {items.map((entry, i) => (
          <li key={i} className="wrap-break-word">
            <b className="font-semibold">{entry.item}</b>: {entry.reason}
          </li>
        ))}
      </ul>
    </details>
  );
}

function Report({ report }: { report: ImportReport }) {
  const issueCount = report.issues.length;
  const imported = report.created + report.remapped;
  const pills = [
    [report.created, "imported"],
    [report.remapped, "imported as copies"],
    [report.skipped, "already there"],
    [report.failed, "failed"],
    [report.attachmentsUploaded, "attachments uploaded"],
    [report.attachmentsFailed, "attachments failed"],
  ].filter(([count]) => count) as [number, string][];
  return (
    <>
      <div className="flex items-center gap-2.5 font-semibold text-lead [&>svg]:size-5.5">
        {issueCount ? (
          <TriangleAlert aria-hidden className="text-warn-foreground" />
        ) : imported || report.skipped ? (
          <CircleCheck aria-hidden className="text-added-ink" />
        ) : (
          <CircleAlert aria-hidden className="text-muted-foreground" />
        )}
        {imported || report.skipped
          ? `${plural(imported, "note")} imported${issueCount ? `, ${issueCount} need${issueCount === 1 ? "s" : ""} attention` : ""}`
          : "Nothing was imported"}
      </div>
      {pills.length > 1 && (
        <ul className="m-0 flex list-none flex-wrap gap-1.5 p-0">
          {pills.map(([count, label]) => (
            <li
              key={label}
              className="rounded-pill bg-muted px-2.5 py-1 text-meta text-muted-foreground"
            >
              <b className="font-semibold text-foreground tabular-nums">
                {count}
              </b>{" "}
              {label}
            </li>
          ))}
        </ul>
      )}
      {issueCount > 0 && (
        <Issues
          title={`${plural(issueCount, "item")} need${issueCount === 1 ? "s" : ""} attention`}
          items={report.issues}
          open
        />
      )}
      {report.restoredTrashed && (
        <FieldDescription>
          Notes restored to the trash get a fresh 30 days there.
        </FieldDescription>
      )}
    </>
  );
}
