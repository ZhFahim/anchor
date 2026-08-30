"use client";

import { useQueryClient } from "@tanstack/react-query";
import { useCallback, useRef, useState } from "react";
import { detectFormat } from "../adapters";
import type { PickedFile } from "../adapters/zip";
import {
  IMPORT_BATCH_SIZE,
  importAttachment,
  importNotes,
  toImportNoteItem,
} from "../api";
import type {
  CanonicalNote,
  ImportNoteResult,
  ImportSkippedItem,
  ParsedImport,
} from "../types";

const ATTACHMENT_UPLOAD_CONCURRENCY = 2;

export type ImportStep = "pick" | "preview" | "running" | "report";

export type ImportOptions = {
  /** Anchor backups only: keep the notes already in the account */
  skipExisting: boolean;
  /** Markdown only: file the notes under the folders they came from */
  folderTags: boolean;
};

const DEFAULT_OPTIONS: ImportOptions = {
  skipExisting: false,
  folderTags: false,
};

export type ImportProgress = {
  phase: "notes" | "attachments";
  done: number;
  total: number;
};

export type ImportReport = {
  created: number;
  skipped: number;
  remapped: number;
  failed: number;
  attachmentsUploaded: number;
  attachmentsFailed: number;
  issues: ImportSkippedItem[];
  /** True when a note that was in the trash came back */
  restoredTrashed: boolean;
};

type AttachmentUpload = {
  noteId: string;
  noteRef: string;
  filename: string;
  mimeType: string;
  position: number;
  getBlob: () => Promise<Blob>;
};

function effectiveTagNames(
  note: CanonicalNote,
  options: ImportOptions,
): string[] {
  if (!options.folderTags || !note.folderTags?.length) return note.tagNames;
  return [...new Set([...note.tagNames, ...note.folderTags])];
}

function chunk<T>(items: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

export function useImport() {
  const queryClient = useQueryClient();

  const [step, setStep] = useState<ImportStep>("pick");
  const [parsed, setParsed] = useState<ParsedImport | null>(null);
  const [isDetecting, setIsDetecting] = useState(false);
  const [pickError, setPickError] = useState<string | null>(null);
  const [runError, setRunError] = useState<string | null>(null);
  const [progress, setProgress] = useState<ImportProgress | null>(null);
  const [report, setReport] = useState<ImportReport | null>(null);
  const [options, setOptions] = useState<ImportOptions>(DEFAULT_OPTIONS);

  // Retry resumes from the last unprocessed batch
  const batchIndexRef = useRef(0);
  const resultsRef = useRef<ImportNoteResult[]>([]);
  const isRunningRef = useRef(false);

  const reset = useCallback(() => {
    setStep("pick");
    setParsed(null);
    setIsDetecting(false);
    setPickError(null);
    setRunError(null);
    setProgress(null);
    setReport(null);
    setOptions(DEFAULT_OPTIONS);
    batchIndexRef.current = 0;
    resultsRef.current = [];
    isRunningRef.current = false;
  }, []);

  const selectFiles = useCallback(async (files: PickedFile[]) => {
    setPickError(null);
    setIsDetecting(true);
    try {
      const detected = await detectFormat(files);
      if (!detected) {
        setPickError(
          "Nothing importable here. Drop an Anchor backup zip, a Google Takeout zip, or a folder of Markdown (.md) files.",
        );
        return;
      }
      const result = await detected.adapter.parse(detected.zip);
      if (!result.notes.length) {
        setPickError("No importable notes found in this file.");
        return;
      }
      setParsed(result);
      setOptions({
        ...DEFAULT_OPTIONS,
        folderTags: result.hasFolders === true,
      });
      setStep("preview");
    } catch (error) {
      setPickError(
        error instanceof Error ? error.message : "Failed to read file",
      );
    } finally {
      setIsDetecting(false);
    }
  }, []);

  const finishRun = useCallback(
    (
      current: ParsedImport,
      attachmentsUploaded: number,
      attachmentFailures: ImportSkippedItem[],
    ) => {
      const results = resultsRef.current;
      const count = (status: ImportNoteResult["status"]) =>
        results.filter((result) => result.status === status).length;

      const noteByRef = new Map(current.notes.map((note) => [note.ref, note]));
      // Refs are internal ids; report the note by its title
      const labelOf = (ref: string) => {
        const note = noteByRef.get(ref);
        return note?.title.trim() || note?.ref.split("/").pop() || ref;
      };

      const issues: ImportSkippedItem[] = [
        ...current.skipped,
        ...results
          .filter((result) => result.status === "failed")
          .map((result) => ({
            item: labelOf(result.ref),
            reason: result.error ?? "Failed to import",
          })),
        ...results
          .filter((result) => result.warning)
          .map((result) => ({
            item: labelOf(result.ref),
            reason: result.warning ?? "",
          })),
        ...attachmentFailures,
      ];

      setReport({
        created: count("created"),
        skipped: count("skipped"),
        remapped: count("remapped"),
        failed: count("failed"),
        attachmentsUploaded,
        attachmentsFailed: attachmentFailures.length,
        issues,
        restoredTrashed: results.some(
          (result) =>
            (result.status === "created" || result.status === "remapped") &&
            noteByRef.get(result.ref)?.isTrashed === true,
        ),
      });
      setStep("report");

      queryClient.invalidateQueries({ queryKey: ["notes"] });
      queryClient.invalidateQueries({ queryKey: ["tags"] });
    },
    [queryClient],
  );

  const run = useCallback(async () => {
    if (!parsed || isRunningRef.current) return;
    isRunningRef.current = true;
    setRunError(null);
    setStep("running");

    const batches = chunk(parsed.notes, IMPORT_BATCH_SIZE);
    const totalNotes = parsed.notes.length;
    const colorByName = new Map(
      parsed.tags.map((tag) => [tag.name, tag.color]),
    );

    try {
      for (let i = batchIndexRef.current; i < batches.length; i++) {
        setProgress({
          phase: "notes",
          done: i * IMPORT_BATCH_SIZE,
          total: totalNotes,
        });
        // Only send colors for tags this batch's notes actually reference
        const batchTags = [
          ...new Set(
            batches[i].flatMap((note) => effectiveTagNames(note, options)),
          ),
        ].map((name) => ({ name, color: colorByName.get(name) ?? null }));
        const response = await importNotes(
          batches[i].map((note) =>
            toImportNoteItem(note, effectiveTagNames(note, options)),
          ),
          batchTags,
          options.skipExisting,
        );
        resultsRef.current.push(...response.results);
        batchIndexRef.current = i + 1;
      }
      setProgress({ phase: "notes", done: totalNotes, total: totalNotes });
    } catch (error) {
      isRunningRef.current = false;
      setRunError(
        error instanceof Error
          ? error.message
          : "Import failed. Check your connection and retry.",
      );
      return;
    }

    // Upload attachments for notes that were just created
    const noteByRef = new Map(parsed.notes.map((note) => [note.ref, note]));
    const uploads: AttachmentUpload[] = [];
    for (const result of resultsRef.current) {
      if (
        (result.status !== "created" && result.status !== "remapped") ||
        !result.noteId
      ) {
        continue;
      }
      const note = noteByRef.get(result.ref);
      if (!note) continue;
      note.attachments
        .filter((attachment) => attachment.supported)
        .forEach((attachment, index) => {
          uploads.push({
            noteId: result.noteId as string,
            noteRef: result.ref,
            filename: attachment.filename,
            mimeType: attachment.mimeType,
            position: index,
            getBlob: attachment.getBlob,
          });
        });
    }

    let uploaded = 0;
    const attachmentFailures: ImportSkippedItem[] = [];
    setProgress({ phase: "attachments", done: 0, total: uploads.length });

    let nextIndex = 0;
    const worker = async () => {
      for (;;) {
        const index = nextIndex++;
        if (index >= uploads.length) return;
        const upload = uploads[index];
        try {
          const blob = await upload.getBlob();
          await importAttachment(
            upload.noteId,
            blob,
            upload.filename,
            upload.mimeType,
            upload.position,
          );
          uploaded++;
        } catch {
          attachmentFailures.push({
            item: upload.filename,
            reason: "Failed to upload attachment",
          });
        }
        setProgress({
          phase: "attachments",
          done: uploaded + attachmentFailures.length,
          total: uploads.length,
        });
      }
    };
    await Promise.all(
      Array.from(
        { length: Math.min(ATTACHMENT_UPLOAD_CONCURRENCY, uploads.length) },
        worker,
      ),
    );

    isRunningRef.current = false;
    finishRun(parsed, uploaded, attachmentFailures);
  }, [parsed, finishRun, options]);

  const setOption = useCallback(
    <K extends keyof ImportOptions>(key: K, value: ImportOptions[K]) => {
      setOptions((current) => ({ ...current, [key]: value }));
    },
    [],
  );

  // The folder toggle changes which tags get sent
  const previewTagCount = parsed
    ? new Set(parsed.notes.flatMap((note) => effectiveTagNames(note, options)))
        .size || parsed.tags.length
    : 0;

  return {
    step,
    parsed,
    isDetecting,
    pickError,
    runError,
    progress,
    report,
    isRunning: step === "running" && !runError,
    options,
    setOption,
    previewTagCount,
    selectFiles,
    start: run,
    retry: run,
    reset,
  };
}
