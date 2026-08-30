import { stringifyDelta } from "@/features/notes/quill";
import {
  type CanonicalAttachment,
  type CanonicalNote,
  IMPORT_ALLOWED_MIME_TYPES,
  IMPORT_MAX_CONTENT_LENGTH,
  type ImportSkippedItem,
  type ParsedImport,
} from "../types";
import {
  type AttachmentRef,
  findAttachmentRefs,
  markdownToDelta,
  stripTitleHeading,
} from "./markdown-mapping";
import type { ImportAdapter } from "./types";
import type { ZipArchive } from "./zip";

const MARKDOWN_EXT = /\.(md|markdown)$/i;

const MIME_BY_EXTENSION: Record<string, string> = {
  jpg: "image/jpeg",
  jpeg: "image/jpeg",
  png: "image/png",
  webp: "image/webp",
  gif: "image/gif",
  mp3: "audio/mpeg",
  wav: "audio/wav",
  m4a: "audio/x-m4a",
  mp4: "audio/mp4",
  ogg: "audio/ogg",
  oga: "audio/ogg",
  aac: "audio/aac",
  weba: "audio/webm",
};

/** Hidden folders and macOS resource forks are never notes. */
const isIgnored = (path: string) =>
  path
    .split("/")
    .some((segment) => segment.startsWith(".") || segment === "__MACOSX");

const dirOf = (path: string) => {
  const index = path.lastIndexOf("/");
  return index === -1 ? "" : path.slice(0, index + 1);
};

const basename = (path: string) => path.split("/").pop() ?? path;

function decodePath(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

function stemOf(path: string): string {
  return decodePath(basename(path)).replace(MARKDOWN_EXT, "").trim();
}

function mimeOf(path: string): string | undefined {
  const extension = path.split(".").pop()?.toLowerCase() ?? "";
  return MIME_BY_EXTENSION[extension];
}

/** Resolves a link target against the folder its markdown file sits in. */
export function resolveRelative(fromDir: string, target: string): string {
  const base = target.startsWith("/") ? "" : fromDir;
  const out: string[] = [];
  for (const segment of `${base}${target.replace(/^\//, "")}`.split("/")) {
    if (!segment || segment === ".") continue;
    if (segment === "..") {
      out.pop();
      continue;
    }
    out.push(segment);
  }
  return out.join("/");
}

/** Leading folders every note shares; those carry no information as tags. */
export function commonRootSegments(paths: string[]): string[] {
  const dirs = paths.map((path) => dirOf(path).split("/").filter(Boolean));
  if (!dirs.length) return [];

  const common = [...dirs[0]];
  for (const segments of dirs.slice(1)) {
    let i = 0;
    while (i < common.length && common[i] === segments[i]) i++;
    common.length = i;
  }
  return common;
}

function markdownEntries(zip: ZipArchive): string[] {
  return zip.names
    .filter((path) => MARKDOWN_EXT.test(path) && !isIgnored(path))
    .sort();
}

/** An Obsidian embed names a file, not a path, so match on the basename. */
function resolveByBasename(zip: ZipArchive, name: string): string | undefined {
  const wanted = name.toLowerCase();
  return zip.names.find(
    (path) => !isIgnored(path) && basename(path).toLowerCase() === wanted,
  );
}

type ExtractedBody = {
  body: string;
  attachments: CanonicalAttachment[];
  skipped: ImportSkippedItem[];
};

/**
 * Finds the file a reference points at, falling back to the note's parent
 * folders and then to the filename alone.
 */
function resolveRef(
  ref: AttachmentRef,
  fromDir: string,
  zip: ZipArchive,
): string | undefined {
  const direct = resolveRelative(fromDir, ref.target);
  if (zip.has(direct)) return direct;

  const segments = fromDir.split("/").filter(Boolean);
  for (let depth = segments.length - 1; depth >= 0; depth--) {
    const candidate = resolveRelative(
      `${segments.slice(0, depth).join("/")}/`,
      ref.target,
    );
    if (zip.has(candidate)) return candidate;
  }

  return resolveByBasename(zip, basename(ref.target));
}

/**
 * Turns supported local file references into attachments; anything
 * unresolved stays visible as text.
 */
function extractAttachments(
  body: string,
  fromDir: string,
  zip: ZipArchive,
): ExtractedBody {
  const refs = findAttachmentRefs(body);
  if (!refs.length) return { body, attachments: [], skipped: [] };

  const lines = body.split(/\r\n|\r|\n/);
  const attachments: CanonicalAttachment[] = [];
  const skipped: ImportSkippedItem[] = [];
  const seen = new Set<string>();
  const touched = new Set<number>();

  for (const ref of refs) {
    const resolved = resolveRef(ref, fromDir, zip);
    const mimeType = resolved ? mimeOf(resolved) : undefined;

    if (!resolved) {
      // A plain link to some other file is not necessarily an attachment
      if (ref.kind === "image") {
        skipped.push({
          item: ref.target,
          reason: "Attachment file not found",
        });
      }
      continue;
    }

    const usable =
      mimeType &&
      IMPORT_ALLOWED_MIME_TYPES.has(mimeType) &&
      (ref.kind === "image" || mimeType.startsWith("audio/"));

    if (!usable) {
      if (ref.kind === "image") {
        skipped.push({
          item: basename(resolved),
          reason: `Unsupported file type (${basename(resolved).split(".").pop()})`,
        });
      }
      continue;
    }

    lines[ref.line] = lines[ref.line].replace(ref.raw, "");
    touched.add(ref.line);

    if (seen.has(resolved)) continue;
    seen.add(resolved);
    attachments.push({
      filename: basename(resolved),
      mimeType: mimeType as string,
      supported: true,
      getBlob: () => Promise.resolve(zip.blob(resolved)),
    });
  }

  const kept = lines.filter(
    (line, index) => !(touched.has(index) && !line.trim()),
  );
  while (kept.length && !kept[kept.length - 1].trim()) kept.pop();

  return { body: kept.join("\n"), attachments, skipped };
}

export const markdownAdapter: ImportAdapter = {
  id: "markdown",
  label: "Markdown files",

  async detect(zip) {
    return markdownEntries(zip).length > 0;
  },

  async parse(zip) {
    const entries = markdownEntries(zip);
    if (!entries.length) {
      throw new Error("No Markdown files found");
    }

    const root = commonRootSegments(entries);
    const notes: CanonicalNote[] = [];
    const skipped: ImportSkippedItem[] = [];

    for (const path of entries) {
      const raw = zip.text(path).replace(/^﻿/, "");
      const stem = stemOf(path);
      const displayName = stem || basename(path);

      if (!raw.trim()) {
        skipped.push({ item: displayName, reason: "Empty file" });
        continue;
      }

      const extracted = extractAttachments(
        stripTitleHeading(raw, stem),
        dirOf(path),
        zip,
      );
      skipped.push(...extracted.skipped);

      const contentDelta = markdownToDelta(extracted.body);
      if (stringifyDelta(contentDelta).length > IMPORT_MAX_CONTENT_LENGTH) {
        skipped.push({
          item: displayName,
          reason: "Note is too large (over 1 MB of formatted content)",
        });
        continue;
      }

      const segments = dirOf(path)
        .split("/")
        .filter(Boolean)
        .slice(root.length);
      const isArchived = segments[0] === "Archived";
      if (isArchived || segments[0] === "Shared") segments.shift();

      notes.push({
        ref: `markdown:${path}`,
        title: /^untitled$/i.test(stem) ? "" : stem,
        contentDelta,
        isPinned: false,
        isArchived,
        isTrashed: false,
        background: null,
        tagNames: [],
        folderTags: segments,
        attachments: extracted.attachments,
      });
    }

    const tagNames = [
      ...new Set(notes.flatMap((note) => note.folderTags ?? [])),
    ];

    return {
      formatId: "markdown",
      formatLabel: this.label,
      notes,
      tags: tagNames.map((name) => ({ name, color: null })),
      attachmentCount: notes.reduce(
        (sum, note) => sum + note.attachments.length,
        0,
      ),
      skipped,
      hasFolders: tagNames.length > 0,
    } satisfies ParsedImport;
  },
};
