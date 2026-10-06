"use client";

import { useQueryClient } from "@tanstack/react-query";
import { HTTPError } from "ky";
import { useCallback, useRef, useState } from "react";
import { detectFormat } from "../adapters";
import { ImportFileError } from "../adapters/types";
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

function serverUnreachable(error: unknown) {
  if (!(error instanceof HTTPError)) return true;
  const status = error.response.status;
  return status >= 500 || status === 408 || status === 429;
}

function isRefused(error: unknown): error is HTTPError {
  if (!(error instanceof HTTPError)) return false;
  const status = error.response.status;
  return status === 400 || status === 413;
}

function attachmentUploads(
  parsed: ParsedImport,
  results: ImportNoteResult[],
): AttachmentUpload[] {
  const noteByRef = new Map(parsed.notes.map((note) => [note.ref, note]));
  const uploads: AttachmentUpload[] = [];
  for (const result of results) {
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

  return uploads;
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

  const batchIndexRef = useRef(0);
  const resultsRef = useRef<ImportNoteResult[]>([]);
  const uploadsRef = useRef<AttachmentUpload[] | null>(null);
  const waitingUploadsRef = useRef<number[]>([]);
  const uploadedRef = useRef(0);
  const attachmentFailuresRef = useRef<ImportSkippedItem[]>([]);
  const isRunningRef = useRef(false);
  const pickIdRef = useRef(0);

  const refreshLists = useCallback(() => {
    queryClient.invalidateQueries({ queryKey: ["notes"] });
    queryClient.invalidateQueries({ queryKey: ["tags"] });
  }, [queryClient]);

  const reset = useCallback(() => {
    if (step === "running" && resultsRef.current.length) refreshLists();
    pickIdRef.current++;
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
    uploadsRef.current = null;
    waitingUploadsRef.current = [];
    uploadedRef.current = 0;
    attachmentFailuresRef.current = [];
    isRunningRef.current = false;
  }, [step, refreshLists]);

  const selectFiles = useCallback(async (files: PickedFile[]) => {
    const pickId = ++pickIdRef.current;
    const isAbandoned = () => pickId !== pickIdRef.current;
    setPickError(null);
    setIsDetecting(true);
    try {
      const detected = await detectFormat(files);
      if (isAbandoned()) return;
      if (!detected) {
        setPickError(
          "Nothing to import here. Drop an Anchor backup, a Google Takeout zip, or a folder of Markdown (.md) files.",
        );
        return;
      }
      const result = await detected.adapter.parse(detected.zip);
      if (isAbandoned()) return;
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
      if (isAbandoned()) return;
      setPickError(
        error instanceof ImportFileError
          ? error.message
          : "Couldn’t read this file.",
      );
    } finally {
      if (!isAbandoned()) setIsDetecting(false);
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
            reason: "Couldn’t import this note",
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
      refreshLists();
    },
    [refreshLists],
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
    const results = resultsRef.current;
    const sentRefs = new Set(results.map((result) => result.ref));
    const showNoteProgress = () =>
      setProgress({ phase: "notes", done: results.length, total: totalNotes });

    const send = async (notes: CanonicalNote[]) => {
      // Only send colors for tags these notes actually reference
      const tags = [
        ...new Set(notes.flatMap((note) => effectiveTagNames(note, options))),
      ].map((name) => ({ name, color: colorByName.get(name) ?? null }));
      const response = await importNotes(
        notes.map((note) =>
          toImportNoteItem(note, effectiveTagNames(note, options)),
        ),
        tags,
        options.skipExisting,
      );
      results.push(...response.results);
    };

    try {
      for (let i = batchIndexRef.current; i < batches.length; i++) {
        showNoteProgress();
        const batch = batches[i].filter((note) => !sentRefs.has(note.ref));
        try {
          await send(batch);
        } catch (error) {
          if (!isRefused(error)) throw error;
          for (const note of batch) {
            try {
              await send([note]);
            } catch (noteError) {
              if (!isRefused(noteError)) throw noteError;
              results.push({
                ref: note.ref,
                status: "failed",
                error: noteError.message,
              });
            }
            showNoteProgress();
          }
        }
        batchIndexRef.current = i + 1;
      }
      setProgress({ phase: "notes", done: totalNotes, total: totalNotes });
    } catch (error) {
      isRunningRef.current = false;
      const done = results.length;
      const stoppedAt = `The import stopped at ${done} of ${totalNotes} notes; the notes before that are saved.`;
      if (serverUnreachable(error))
        setRunError(
          `Couldn’t reach the server. ${done ? stoppedAt : "Check your connection, then try again."}`,
        );
      else
        setRunError(
          done
            ? `Couldn’t import your notes. ${stoppedAt}`
            : "Couldn’t import your notes.",
        );
      return;
    }

    if (!uploadsRef.current) {
      uploadsRef.current = attachmentUploads(parsed, resultsRef.current);
      waitingUploadsRef.current = uploadsRef.current.map((_, index) => index);
    }
    const uploads = uploadsRef.current;
    const failures = attachmentFailuresRef.current;
    const showProgress = () =>
      setProgress({
        phase: "attachments",
        done: uploadedRef.current + failures.length,
        total: uploads.length,
      });
    showProgress();

    let stopped = false;
    const worker = async () => {
      while (!stopped) {
        const index = waitingUploadsRef.current.shift();
        if (index === undefined) return;
        const upload = uploads[index];
        let blob: Blob;
        try {
          blob = await upload.getBlob();
        } catch {
          failures.push({
            item: upload.filename,
            reason: "Couldn’t read the file",
          });
          showProgress();
          continue;
        }
        try {
          await importAttachment(
            upload.noteId,
            blob,
            upload.filename,
            upload.mimeType,
            upload.position,
          );
          uploadedRef.current++;
        } catch (error) {
          if (serverUnreachable(error)) {
            waitingUploadsRef.current.unshift(index);
            stopped = true;
            return;
          }
          failures.push({
            item: upload.filename,
            reason: "Couldn’t upload the attachment",
          });
        }
        showProgress();
      }
    };
    await Promise.all(
      Array.from(
        { length: Math.min(ATTACHMENT_UPLOAD_CONCURRENCY, uploads.length) },
        worker,
      ),
    );

    isRunningRef.current = false;
    if (stopped) {
      const done = uploadedRef.current + failures.length;
      setRunError(
        `Couldn’t reach the server. The import stopped at ${done} of ${uploads.length} attachments; the notes and the attachments before that are saved.`,
      );
      return;
    }
    finishRun(parsed, uploadedRef.current, failures);
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
