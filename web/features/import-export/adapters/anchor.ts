import { parseStoredContent } from "@/features/notes/quill";
import {
  type CanonicalAttachment,
  type CanonicalNote,
  IMPORT_ALLOWED_MIME_TYPES,
  type ImportSkippedItem,
  type ParsedImport,
} from "../types";
import type { ImportAdapter } from "./types";
import type { ZipArchive } from "./zip";

const MANIFEST_PATH = "manifest.json";
const SUPPORTED_VERSION = 1;

type ManifestAttachment = {
  id: string;
  type: string;
  originalFilename: string;
  mimeType: string;
  fileSize: number;
  position: number;
  archivePath: string;
};

type ManifestNote = {
  id: string;
  origin: "owned" | "shared";
  title: string;
  content: string | null;
  state: "active" | "trashed";
  isArchived: boolean;
  isPinned: boolean;
  background: string | null;
  tagIds: string[];
  createdAt: string;
  updatedAt: string;
  attachments: ManifestAttachment[];
};

type Manifest = {
  format: string;
  version: number;
  tags: { id: string; name: string; color: string | null }[];
  notes: ManifestNote[];
};

function readManifest(zip: ZipArchive): Manifest | null {
  if (!zip.has(MANIFEST_PATH)) return null;
  try {
    const parsed = JSON.parse(zip.text(MANIFEST_PATH)) as Manifest;
    return parsed.format === "anchor-export" ? parsed : null;
  } catch {
    return null;
  }
}

export const anchorAdapter: ImportAdapter = {
  id: "anchor",
  label: "Anchor backup",

  async detect(zip) {
    return readManifest(zip) !== null;
  },

  async parse(zip) {
    const manifest = readManifest(zip);
    if (!manifest) {
      throw new Error("Not a valid Anchor backup: manifest.json missing");
    }
    if (
      typeof manifest.version !== "number" ||
      manifest.version > SUPPORTED_VERSION
    ) {
      throw new Error(
        `This backup was created by a newer version of Anchor (format v${manifest.version}). Please update your server.`,
      );
    }

    const tagById = new Map(manifest.tags.map((tag) => [tag.id, tag]));
    const skipped: ImportSkippedItem[] = [];
    const notes: CanonicalNote[] = [];

    for (const note of manifest.notes) {
      const attachments: CanonicalAttachment[] = [];
      for (const attachment of note.attachments) {
        if (!zip.has(attachment.archivePath)) {
          skipped.push({
            item: attachment.originalFilename,
            reason: "Attachment file missing from backup archive",
          });
          continue;
        }
        attachments.push({
          filename: attachment.originalFilename,
          mimeType: attachment.mimeType,
          supported: IMPORT_ALLOWED_MIME_TYPES.has(attachment.mimeType),
          getBlob: () => Promise.resolve(zip.blob(attachment.archivePath)),
        });
      }

      notes.push({
        ref: `anchor:${note.id}`,
        // Shared-with-me notes become owned copies with a new identity;
        // the server also remaps foreign-owned ids as a backstop.
        id: note.origin === "shared" ? undefined : note.id,
        title: note.title,
        contentDelta: parseStoredContent(note.content),
        isPinned: note.isPinned,
        isArchived: note.isArchived,
        isTrashed: note.state === "trashed",
        background: note.background,
        tagNames: note.tagIds
          .map((id) => tagById.get(id)?.name)
          .filter((name): name is string => Boolean(name)),
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        attachments,
      });
    }

    // A full backup restore must not drop tags that have no notes.
    const tags = manifest.tags.map((tag) => ({
      name: tag.name,
      color: tag.color,
    }));

    return {
      formatId: "anchor",
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
