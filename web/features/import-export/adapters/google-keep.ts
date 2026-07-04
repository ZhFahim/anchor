import {
  type CanonicalAttachment,
  type CanonicalNote,
  IMPORT_ALLOWED_MIME_TYPES,
  type ImportSkippedItem,
  type ParsedImport,
} from "../types";
import {
  type KeepNote,
  keepColorToBackground,
  keepContentToDelta,
  keepTimestampToIso,
  resolveKeepMediaPath,
} from "./keep-mapping";
import type { ImportAdapter } from "./types";
import type { ZipArchive } from "./zip";

const KEEP_FOLDER_RE = /(^|\/)Keep\//;

function keepJsonEntries(zip: ZipArchive): string[] {
  return zip.names.filter(
    (path) => path.endsWith(".json") && KEEP_FOLDER_RE.test(path),
  );
}

function looksLikeKeepJson(zip: ZipArchive, path: string): boolean {
  try {
    const parsed = JSON.parse(zip.text(path)) as KeepNote;
    return typeof parsed.userEditedTimestampUsec === "number";
  } catch {
    return false;
  }
}

// Takeout localizes the "Keep" folder name, so fall back to sniffing any
// .json entry for a Keep-specific field.
function findNoteEntries(zip: ZipArchive): string[] {
  const inKeepFolder = keepJsonEntries(zip);
  if (inKeepFolder.length) return inKeepFolder.sort();

  return zip.names
    .filter((path) => path.endsWith(".json") && looksLikeKeepJson(zip, path))
    .sort();
}

const parentDir = (path: string) =>
  path.includes("/") ? path.slice(0, path.lastIndexOf("/") + 1) : "";

export const googleKeepAdapter: ImportAdapter = {
  id: "google-keep",
  label: "Google Keep",

  async detect(zip) {
    return findNoteEntries(zip).length > 0;
  },

  async parse(zip) {
    const noteEntries = findNoteEntries(zip);
    if (!noteEntries.length) {
      throw new Error("No Google Keep notes found in this Takeout export");
    }

    // Media files live alongside the note json files
    const noteDirs = new Set(noteEntries.map(parentDir));
    const mediaPaths = zip.names.filter(
      (path) =>
        noteDirs.has(parentDir(path)) &&
        !path.endsWith(".json") &&
        !path.endsWith(".html"),
    );

    const skipped: ImportSkippedItem[] = [];
    const notes: CanonicalNote[] = [];

    for (const entryPath of noteEntries) {
      let keepNote: KeepNote;
      try {
        keepNote = JSON.parse(zip.text(entryPath)) as KeepNote;
      } catch {
        skipped.push({ item: entryPath, reason: "Unreadable note file" });
        continue;
      }

      const displayName =
        keepNote.title?.trim() || basenameForDisplay(entryPath);

      if (keepNote.isTrashed) {
        skipped.push({ item: displayName, reason: "Trashed in Google Keep" });
        continue;
      }

      const attachments: CanonicalAttachment[] = [];
      for (const ref of keepNote.attachments ?? []) {
        const resolved = resolveKeepMediaPath(ref.filePath, mediaPaths);
        if (!resolved) {
          skipped.push({
            item: ref.filePath,
            reason: "Attachment file not found in export",
          });
          continue;
        }
        const supported = IMPORT_ALLOWED_MIME_TYPES.has(ref.mimetype);
        if (!supported) {
          skipped.push({
            item: ref.filePath,
            reason: `Unsupported file type (${ref.mimetype})`,
          });
        }
        attachments.push({
          filename: resolved.split("/").pop() ?? ref.filePath,
          mimeType: ref.mimetype,
          supported,
          getBlob: () => Promise.resolve(zip.blob(resolved)),
        });
      }

      notes.push({
        ref: `keep:${entryPath}`,
        title: keepNote.title ?? "",
        contentDelta: keepContentToDelta(keepNote),
        isPinned: keepNote.isPinned === true,
        isArchived: keepNote.isArchived === true,
        isTrashed: false,
        background: keepColorToBackground(keepNote.color),
        tagNames: (keepNote.labels ?? [])
          .map((label) => label.name)
          .filter(Boolean),
        createdAt: keepTimestampToIso(keepNote.createdTimestampUsec),
        updatedAt: keepTimestampToIso(keepNote.userEditedTimestampUsec),
        attachments,
      });
    }

    // Keep labels have no color
    const tags = [...new Set(notes.flatMap((note) => note.tagNames))].map(
      (name) => ({ name, color: null }),
    );

    return {
      formatId: "google-keep",
      formatLabel: this.label,
      notes,
      tags,
      attachmentCount: notes.reduce(
        (sum, note) => sum + note.attachments.filter((a) => a.supported).length,
        0,
      ),
      skipped,
    } satisfies ParsedImport;
  },
};

const basenameForDisplay = (path: string) =>
  (path.split("/").pop() ?? path).replace(/\.json$/, "");
