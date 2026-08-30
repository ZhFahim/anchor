import { Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import type { ConfigType } from '@nestjs/config';
import type { Response } from 'express';
import { ZipArchive, type ZipEntryData } from 'archiver';
import * as fs from 'fs';
import * as path from 'path';
import { PrismaService } from '../prisma/prisma.service';
import { NoteState } from 'src/generated/prisma/enums';
import { StorageConfig } from '../config/configuration';
import {
  buildManifest,
  ExportManifestV1,
  ExportNoteRow,
} from './export-manifest.util';
import { ExportFormat } from './dto/export-query.dto';
import { planMarkdownExport } from './markdown/markdown-export.util';

const NOTES_PAGE_SIZE = 500;

const NOTE_EXPORT_INCLUDE = {
  tags: {
    where: { isDeleted: false },
    select: { id: true, userId: true },
  },
  attachments: {
    orderBy: { position: 'asc' as const },
    select: {
      id: true,
      type: true,
      originalFilename: true,
      storedFilename: true,
      mimeType: true,
      fileSize: true,
      position: true,
    },
  },
  sharedWith: {
    where: { isDeleted: false },
    select: {
      sharedWithUserId: true,
      sharedByUser: { select: { name: true, email: true } },
    },
  },
} as const;

@Injectable()
export class ExportService {
  private readonly logger = new Logger(ExportService.name);

  constructor(
    private prisma: PrismaService,
    @Inject(StorageConfig.KEY)
    private storageConfig: ConfigType<typeof StorageConfig>,
  ) {}

  async streamExport(
    userId: string,
    res: Response,
    format: ExportFormat = 'anchor',
  ): Promise<void> {
    const { manifest, diskPathByAttachmentId } =
      await this.buildExportManifest(userId);

    const date = new Date().toISOString().slice(0, 10);
    const filename =
      format === 'markdown'
        ? `anchor-markdown-${date}.zip`
        : `anchor-export-${date}.zip`;
    const archive = this.openArchive(res, filename);

    if (format === 'markdown') {
      this.appendMarkdownEntries(archive, manifest, diskPathByAttachmentId);
    } else {
      this.appendAnchorEntries(archive, manifest, diskPathByAttachmentId);
    }

    await archive.finalize();
  }

  private openArchive(res: Response, filename: string): ZipArchive {
    res.setHeader('Content-Type', 'application/zip');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

    const archive = new ZipArchive({ zlib: { level: 6 } });
    archive.on('error', (error) => {
      this.logger.error(`Export archive failed: ${error.message}`);
      res.destroy(error);
    });
    archive.on('warning', (warning) => {
      this.logger.warn(`Export archive warning: ${warning.message}`);
    });
    archive.pipe(res);
    return archive;
  }

  private appendAnchorEntries(
    archive: ZipArchive,
    manifest: ExportManifestV1,
    diskPathByAttachmentId: Map<string, string>,
  ): void {
    archive.append(JSON.stringify(manifest, null, 2), {
      name: 'manifest.json',
    });

    for (const note of manifest.notes) {
      for (const attachment of note.attachments) {
        const filePath = diskPathByAttachmentId.get(attachment.id);
        if (filePath) {
          // Media is already compressed; store without deflate
          const entry: ZipEntryData = {
            name: attachment.archivePath,
            store: true,
          };
          archive.file(filePath, entry);
        }
      }
    }
  }

  private appendMarkdownEntries(
    archive: ZipArchive,
    manifest: ExportManifestV1,
    diskPathByAttachmentId: Map<string, string>,
  ): void {
    const { entries, warnings } = planMarkdownExport(manifest);

    for (const warning of warnings) {
      this.logger.warn(`Markdown export: ${warning}`);
    }

    for (const entry of entries) {
      archive.append(entry.markdown, {
        name: entry.path,
        date: new Date(entry.updatedAt),
      });
      for (const attachment of entry.attachments) {
        const filePath = diskPathByAttachmentId.get(attachment.attachmentId);
        if (filePath) {
          const file: ZipEntryData = {
            name: attachment.archivePath,
            store: true,
          };
          archive.file(filePath, file);
        }
      }
    }
  }

  private async buildExportManifest(userId: string): Promise<{
    manifest: ExportManifestV1;
    diskPathByAttachmentId: Map<string, string>;
  }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const tags = await this.prisma.tag.findMany({
      where: { userId, isDeleted: false },
      select: { id: true, name: true, color: true },
      orderBy: { name: 'asc' },
    });

    const ownedNotes = await this.fetchNotesPaged(userId, {
      userId,
      state: { in: [NoteState.active, NoteState.trashed] },
    });

    const sharedNotes = await this.fetchNotesPaged(userId, {
      userId: { not: userId },
      state: NoteState.active,
      sharedWith: {
        some: { sharedWithUserId: userId, isDeleted: false },
      },
    });

    const manifest = buildManifest({
      user,
      serverVersion: this.readServerVersion(),
      tags,
      ownedNotes,
      sharedNotes,
      warnings: [],
    });

    const diskPathByAttachmentId = this.verifyAttachmentFiles(
      manifest,
      ownedNotes.concat(sharedNotes),
    );

    return { manifest, diskPathByAttachmentId };
  }

  private async fetchNotesPaged(
    userId: string,
    where: Record<string, unknown>,
  ): Promise<ExportNoteRow[]> {
    const notes: ExportNoteRow[] = [];
    let cursor: string | undefined;

    for (;;) {
      const page = await this.prisma.note.findMany({
        where,
        include: {
          ...NOTE_EXPORT_INCLUDE,
          pins: { where: { userId }, select: { userId: true } },
        },
        orderBy: { id: 'asc' },
        take: NOTES_PAGE_SIZE,
        ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      });
      notes.push(...(page as unknown as ExportNoteRow[]));
      if (page.length < NOTES_PAGE_SIZE) {
        return notes;
      }
      cursor = page[page.length - 1].id;
    }
  }

  /**
   * Drops manifest entries for attachment files missing on disk (recording
   * a warning for each) so archiver doesn't abort mid-stream, and returns
   * the attachmentId -> absolute disk path map for the surviving entries.
   */
  private verifyAttachmentFiles(
    manifest: ExportManifestV1,
    rows: ExportNoteRow[],
  ): Map<string, string> {
    const storedFilenames = new Map(
      rows.flatMap((row) =>
        row.attachments.map(
          (a) => [a.id, a.storedFilename] as [string, string],
        ),
      ),
    );
    const diskPaths = new Map<string, string>();

    for (const note of manifest.notes) {
      const present: typeof note.attachments = [];
      for (const attachment of note.attachments) {
        const storedFilename = storedFilenames.get(attachment.id);
        const filePath = storedFilename
          ? path.join(
              this.storageConfig.attachmentsDir,
              note.id,
              storedFilename,
            )
          : null;
        if (filePath && fs.existsSync(filePath)) {
          diskPaths.set(attachment.id, filePath);
          present.push(attachment);
        } else {
          manifest.warnings.push(
            `Attachment file missing on disk: ${attachment.originalFilename} (note ${note.id})`,
          );
        }
      }
      note.attachments = present;
    }

    manifest.counts.attachments = manifest.notes.reduce(
      (sum, n) => sum + n.attachments.length,
      0,
    );

    return diskPaths;
  }

  private readServerVersion(): string | null {
    try {
      const packageJson = JSON.parse(
        fs.readFileSync(path.join(process.cwd(), 'package.json'), 'utf8'),
      ) as { version?: string };
      return packageJson.version ?? null;
    } catch {
      return process.env.npm_package_version ?? null;
    }
  }
}
