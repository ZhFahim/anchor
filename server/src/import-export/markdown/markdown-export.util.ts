import * as path from 'path';
import { ExportManifestNote, ExportManifestV1 } from '../export-manifest.util';
import { deltaToMarkdown } from './delta-to-markdown';
import { parseDeltaOps } from './delta-lines';
import {
  FilenameAllocator,
  encodeRelativePath,
  sanitizeFilenameStem,
} from './note-filename';

export type MarkdownExportAttachment = {
  attachmentId: string;
  archivePath: string;
};

export type MarkdownExportEntry = {
  /** Path inside the zip, e.g. "Archived/Groceries (2).md" */
  path: string;
  markdown: string;
  updatedAt: string;
  attachments: MarkdownExportAttachment[];
};

export type MarkdownExportPlan = {
  entries: MarkdownExportEntry[];
  warnings: string[];
};

/** Folder a note is filed under inside the export. */
export function noteFolder(note: ExportManifestNote): string {
  if (note.origin === 'shared') return 'Shared/';
  return note.isArchived ? 'Archived/' : '';
}

function attachmentReference(
  type: string,
  filename: string,
  relativePath: string,
): string {
  const link = `[${filename}](${encodeRelativePath(relativePath)})`;
  return type === 'image' ? `!${link}` : link;
}

/** Lays out the markdown flavour of an export from an already built manifest. */
export function planMarkdownExport(
  manifest: ExportManifestV1,
): MarkdownExportPlan {
  const entries: MarkdownExportEntry[] = [];
  const warnings = [...manifest.warnings];
  const noteNames = new FilenameAllocator();
  const attachmentNames = new FilenameAllocator();

  for (const note of manifest.notes) {
    if (note.state === 'trashed') continue;

    const dir = noteFolder(note);
    const stem = noteNames.allocate(dir, sanitizeFilenameStem(note.title));

    const ops = parseDeltaOps(note.content);
    if (note.content && !ops) {
      warnings.push(
        `Note ${note.id} has unreadable content and was exported empty`,
      );
    }

    let body = ops ? deltaToMarkdown(ops) : '';
    const attachments: MarkdownExportAttachment[] = [];
    const references: string[] = [];

    const attachmentDir = `${dir}attachments/${stem}`;
    for (const attachment of note.attachments) {
      const ext = path.extname(attachment.originalFilename);
      const base = sanitizeFilenameStem(
        attachment.originalFilename.slice(
          0,
          attachment.originalFilename.length - ext.length,
        ),
      );
      const filename = `${attachmentNames.allocate(attachmentDir, base)}${ext.toLowerCase()}`;
      attachments.push({
        attachmentId: attachment.id,
        archivePath: `${attachmentDir}/${filename}`,
      });
      references.push(
        attachmentReference(
          attachment.type,
          filename,
          `attachments/${stem}/${filename}`,
        ),
      );
    }

    if (references.length) {
      body = body
        ? `${body}\n${references.join('\n')}\n`
        : `${references.join('\n')}\n`;
    }

    entries.push({
      path: `${dir}${stem}.md`,
      markdown: body,
      updatedAt: note.updatedAt,
      attachments,
    });
  }

  return { entries, warnings };
}
