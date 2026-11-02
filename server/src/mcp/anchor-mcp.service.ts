import {
  ConflictException,
  HttpException,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import type { CallToolResult } from '@modelcontextprotocol/sdk/types.js';
import { z } from 'zod';
import { NotesService } from '../notes/services/notes.service';
import { NoteAttachmentsService } from '../notes/services/note-attachments.service';
import type { AttachmentResponseDto } from '../notes/dto/attachment-response.dto';
import { TagsService } from '../tags/tags.service';
import type { AttachmentKind } from '../notes/utils/attachment-storage.util';
import type { TransformedNote } from '../notes/utils/note-transformer.util';
import {
  appendMarkdownToContent,
  markdownCanCarry,
  markdownToNoteContent,
  noteContentToMarkdown,
} from './note-markdown.util';
import {
  ATTACHMENT_MAX_SENT_BYTES,
  attachmentContent,
} from './attachment-content.util';

const SNIPPET_LENGTH = 200;
const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 200;

type Tag = { id: string; name: string };
type Content = CallToolResult['content'][number];

const INSTRUCTIONS =
  "Anchor is the user's note taking app. Notes have a title and a body, " +
  'which these tools read and write as markdown: headings, lists, ' +
  'checklists ("- [ ] item", "- [x] done"), bold, italic, ~~strike~~, ' +
  '<u>underline</u>, ==highlight==, links, quotes and code blocks. ' +
  'Read a note with get_note before changing it. Pictures, recordings and ' +
  'files attached to a note are listed by get_note; get_attachment fetches ' +
  'one, so you can look at a picture. Locked notes keep their text and ' +
  'attachments to themselves, and frozen notes cannot be changed.';

/** Builds the MCP server Claude talks to, acting as one Anchor user. */
@Injectable()
export class AnchorMcpService {
  constructor(
    private readonly notesService: NotesService,
    private readonly attachmentsService: NoteAttachmentsService,
    private readonly tagsService: TagsService,
  ) {}

  createServer(userId: string): McpServer {
    const server = new McpServer(
      { name: 'anchor', version: '1.0.0' },
      { instructions: INSTRUCTIONS },
    );

    server.registerTool(
      'list_notes',
      {
        title: 'List notes',
        description:
          'Lists notes, newest first, with a snippet of each. Searches ' +
          'titles, text and the text in pictures when a query is given; ' +
          'invisible notes only show up in a search.',
        inputSchema: {
          query: z.string().optional().describe('Text to search for'),
          tag: z.string().optional().describe('Only notes with this tag'),
          scope: z
            .enum(['notes', 'archive', 'trash'])
            .default('notes')
            .describe('Which notes to list'),
          limit: z.number().int().min(1).max(MAX_LIMIT).default(DEFAULT_LIMIT),
        },
        annotations: { readOnlyHint: true },
      },
      ({ query, tag, scope, limit }) =>
        this.run(async () => {
          const tags = await this.tags(userId);
          let tagId: string | undefined;
          if (tag) {
            tagId = findTag(tags, tag)?.id;
            if (!tagId) return `No tag is called "${tag}".`;
          }

          let notes: TransformedNote[];
          if (scope === 'notes') {
            notes = await this.notesService.findAll(
              userId,
              query,
              tagId,
              query ? limit : undefined,
            );
            // The server's search reads every note's text; a locked one is
            // found by its title alone, as in the apps.
            notes = query
              ? notes.filter((n) => matches(n, query))
              : notes.filter((note) => !note.isInvisible);
          } else {
            notes =
              scope === 'archive'
                ? await this.notesService.findArchived(userId)
                : await this.notesService.findTrashed(userId);
            if (tagId) notes = notes.filter((n) => n.tagIds.includes(tagId));
            if (query) notes = notes.filter((n) => matches(n, query));
            // Invisible notes stay out of the archive unless searched for;
            // the trash lists them, so they can be put back.
            else if (scope === 'archive') {
              notes = notes.filter((n) => !n.isInvisible);
            }
          }

          const page = notes.slice(0, limit);
          return {
            notes: page.map((note) => summarize(note, tags)),
            ...(notes.length > page.length
              ? { more: notes.length - page.length }
              : {}),
          };
        }),
    );

    server.registerTool(
      'get_note',
      {
        title: 'Read a note',
        description:
          'Reads a note: its title, its text as markdown, its tags, its ' +
          'attachments (pictures, recordings, files; newest first) and its ' +
          'version, which update_note takes to avoid overwriting edits.',
        inputSchema: { id: z.string().describe('The note id') },
        annotations: { readOnlyHint: true },
      },
      ({ id }) =>
        this.run(async () => {
          const note = await this.notesService.findOne(userId, id);
          const attachments =
            note.attachmentCount && !note.lock
              ? await this.attachmentsService.findAll(userId, id)
              : undefined;
          return describe(note, await this.tags(userId), attachments);
        }),
    );

    server.registerTool(
      'get_attachment',
      {
        title: 'Fetch an attachment',
        description:
          "Fetches one of a note's attachments, by the ids get_note lists: " +
          'a picture comes back as an image to look at (scaled down if ' +
          'large), a recording as audio, and a file as its contents.',
        inputSchema: {
          noteId: z.string().describe('The note id'),
          id: z.string().describe('The attachment id, from get_note'),
        },
        annotations: { readOnlyHint: true },
      },
      ({ noteId, id }) =>
        this.runContent(async () => {
          const note = await this.notesService.findOne(userId, noteId);
          if (note.lock) {
            throw new HttpException(
              'This note is locked; unlock it in Anchor to see its ' +
                'attachments.',
              HttpStatus.FORBIDDEN,
            );
          }
          const listed = await this.attachmentsService.findAll(userId, noteId);
          const attachment = listed.find((a) => a.id === id);
          if (!attachment) {
            throw new HttpException(
              'This note has no attachment with that id.',
              HttpStatus.NOT_FOUND,
            );
          }
          if (
            attachment.type !== 'image' &&
            attachment.fileSize > ATTACHMENT_MAX_SENT_BYTES
          ) {
            throw new HttpException(
              `${attachment.originalFilename} is too big to send ` +
                `(${megabytes(attachment.fileSize)}); open it in Anchor.`,
              HttpStatus.PAYLOAD_TOO_LARGE,
            );
          }
          const { data } = await this.attachmentsService.readFile(
            userId,
            noteId,
            id,
          );
          return [
            {
              type: 'text',
              text: JSON.stringify(attachmentSummary(attachment), null, 2),
            },
            await attachmentContent(
              attachment.type as AttachmentKind,
              attachment.mimeType,
              data,
              `anchor://notes/${noteId}/attachments/${id}`,
            ),
          ];
        }),
    );

    server.registerTool(
      'list_tags',
      {
        title: 'List tags',
        description: 'Lists the tags, with how many notes have each.',
        annotations: { readOnlyHint: true },
      },
      () =>
        this.run(async () => {
          const tags = await this.tagsService.findAll(userId);
          return tags.map((tag) => ({
            id: tag.id,
            name: tag.name,
            notes: tag._count.notes,
          }));
        }),
    );

    server.registerTool(
      'create_note',
      {
        title: 'Create a note',
        description: 'Creates a note. Tags that do not exist yet are created.',
        inputSchema: {
          title: z.string().default(''),
          content: z.string().default('').describe('The text, as markdown'),
          tags: z.array(z.string()).optional().describe('Tag names'),
          pinned: z.boolean().optional(),
        },
      },
      ({ title, content, tags, pinned }) =>
        this.run(async () => {
          const note = await this.notesService.create(userId, {
            title,
            content: markdownToNoteContent(content),
            isPinned: pinned,
            tagIds: tags ? await this.tagIds(userId, tags) : undefined,
          });
          return describe(note, await this.tags(userId));
        }),
    );

    server.registerTool(
      'update_note',
      {
        title: 'Change a note',
        description:
          'Changes a note. Leave out what stays as it is. content replaces ' +
          'the whole text, so pass the full markdown; to add lines at the ' +
          'end, use append_to_note. tags replaces the tag list.',
        inputSchema: {
          id: z.string(),
          version: z
            .number()
            .int()
            .optional()
            .describe('The version get_note returned; refused if it changed'),
          title: z.string().optional(),
          content: z.string().optional().describe('The new text, as markdown'),
          tags: z.array(z.string()).optional().describe('Tag names'),
          pinned: z.boolean().optional(),
          archived: z.boolean().optional(),
        },
      },
      ({ id, version, title, content, tags, pinned, archived }) =>
        this.run(async () => {
          const current = await this.notesService.findOne(userId, id);
          if (content !== undefined) {
            if (current.lock) throw locked();
            if (!markdownCanCarry(current.content)) {
              throw new HttpException(
                'This note has pictures in its text, colours, fonts or ' +
                  'highlights that markdown cannot carry, so its text ' +
                  'cannot be replaced. Use append_to_note, or change it in ' +
                  'Anchor.',
                HttpStatus.UNPROCESSABLE_ENTITY,
              );
            }
          }
          const note = await this.notesService.update(userId, id, {
            title,
            content:
              content === undefined
                ? undefined
                : markdownToNoteContent(content),
            isPinned: pinned,
            isArchived: archived,
            tagIds: tags ? await this.tagIds(userId, tags) : undefined,
            baseVersion: version ?? current.version,
          });
          return describe(note, await this.tags(userId));
        }),
    );

    server.registerTool(
      'append_to_note',
      {
        title: 'Add to a note',
        description:
          'Adds markdown lines to the end of a note, keeping everything ' +
          'already in it, such as items for a checklist ("- [ ] eggs").',
        inputSchema: {
          id: z.string(),
          content: z.string().describe('The lines to add, as markdown'),
        },
      },
      ({ id, content }) =>
        this.run(async () => {
          const current = await this.notesService.findOne(userId, id);
          if (current.lock) throw locked();
          const note = await this.notesService.update(userId, id, {
            content: appendMarkdownToContent(current.content, content),
            baseVersion: current.version,
          });
          return describe(note, await this.tags(userId));
        }),
    );

    server.registerTool(
      'trash_note',
      {
        title: 'Move a note to the trash',
        description:
          'Moves a note to the trash, where it can be restored from in ' +
          'Anchor until the trash is emptied.',
        inputSchema: { id: z.string() },
        annotations: { destructiveHint: true },
      },
      ({ id }) =>
        this.run(async () => {
          // For a note shared with this person, remove() leaves the share
          // instead: they would lose it, not trash it.
          const note = await this.notesService.findOne(userId, id);
          if (note.userId !== userId) {
            throw new HttpException(
              'This note was shared with you; only its owner can move it ' +
                'to the trash.',
              HttpStatus.FORBIDDEN,
            );
          }
          await this.notesService.remove(userId, id);
          return `Moved note ${id} to the trash.`;
        }),
    );

    return server;
  }

  private async tags(userId: string): Promise<Tag[]> {
    return this.tagsService.findAll(userId);
  }

  /** Ids for tag names, creating the ones that don't exist. */
  private async tagIds(userId: string, names: string[]): Promise<string[]> {
    const tags = await this.tags(userId);
    const ids: string[] = [];
    for (const raw of names) {
      const name = raw.trim();
      if (!name) continue;
      const tag =
        findTag(tags, name) ??
        (await this.tagsService.create(userId, { name }));
      tags.push(tag);
      if (!ids.includes(tag.id)) ids.push(tag.id);
    }
    return ids;
  }

  /** Runs a tool, turning what it returns or throws into its result. */
  private run(tool: () => Promise<string | object>): Promise<CallToolResult> {
    return this.runContent(async () => {
      const result = await tool();
      return [
        {
          type: 'text',
          text:
            typeof result === 'string'
              ? result
              : JSON.stringify(result, null, 2),
        },
      ];
    });
  }

  /** Runs a tool that builds its own content, such as a picture. */
  private async runContent(
    tool: () => Promise<Content[]>,
  ): Promise<CallToolResult> {
    try {
      return { content: await tool() };
    } catch (error) {
      return {
        isError: true,
        content: [{ type: 'text', text: errorMessage(error) }],
      };
    }
  }
}

function findTag(tags: Tag[], name: string): Tag | undefined {
  const wanted = name.trim().toLowerCase();
  return tags.find((tag) => tag.name.toLowerCase() === wanted);
}

function tagNames(note: TransformedNote, tags: Tag[]): string[] {
  return note.tagIds.flatMap((id) => {
    const tag = tags.find((t) => t.id === id);
    return tag ? [tag.name] : [];
  });
}

function matches(note: TransformedNote, query: string): boolean {
  const wanted = query.toLowerCase();
  // A locked note is found by its title alone: nothing of its text or its
  // pictures' text is given away.
  const texts = note.lock
    ? [note.title]
    : [note.title, note.content, note.pictureText];
  return texts.some((text) => text?.toLowerCase().includes(wanted));
}

function flags(note: TransformedNote) {
  return {
    ...(note.isPinned ? { pinned: true } : {}),
    ...(note.isArchived ? { archived: true } : {}),
    ...(note.state === 'trashed' ? { trashed: true } : {}),
    ...(note.isFrozen ? { frozen: true } : {}),
    ...(note.lock ? { locked: true } : {}),
    ...(note.isInvisible ? { invisible: true } : {}),
    ...(note.permission !== 'owner' ? { sharedWithYou: note.permission } : {}),
  };
}

function summarize(note: TransformedNote, tags: Tag[]) {
  const text = note.lock ? '' : noteContentToMarkdown(note.content);
  return {
    id: note.id,
    title: note.title,
    snippet:
      text.length > SNIPPET_LENGTH
        ? `${text.slice(0, SNIPPET_LENGTH).trimEnd()}…`
        : text.trimEnd(),
    tags: tagNames(note, tags),
    updatedAt: note.updatedAt,
    ...flags(note),
    ...(note.attachmentCount ? { attachments: note.attachmentCount } : {}),
  };
}

function describe(
  note: TransformedNote,
  tags: Tag[],
  attachments?: AttachmentResponseDto[],
) {
  return {
    id: note.id,
    title: note.title,
    version: note.version,
    tags: tagNames(note, tags),
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
    ...flags(note),
    ...(attachments
      ? { attachments: attachments.map(attachmentSummary) }
      : note.attachmentCount
        ? { attachments: note.attachmentCount }
        : {}),
    content: note.lock ? null : noteContentToMarkdown(note.content),
    ...(note.lock
      ? { note: 'This note is locked; unlock it in Anchor to read it.' }
      : {}),
  };
}

function attachmentSummary(attachment: AttachmentResponseDto) {
  return {
    id: attachment.id,
    type: attachment.type,
    filename: attachment.originalFilename,
    mimeType: attachment.mimeType,
    size: megabytes(attachment.fileSize),
    createdAt: attachment.createdAt,
    ...(attachment.text ? { text: attachment.text } : {}),
  };
}

function megabytes(bytes: number): string {
  return bytes < 1024 * 1024
    ? `${Math.max(1, Math.round(bytes / 1024))} KB`
    : `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

function locked(): HttpException {
  return new HttpException(
    'This note is locked; unlock it in Anchor to change its text.',
    HttpStatus.FORBIDDEN,
  );
}

function errorMessage(error: unknown): string {
  if (error instanceof ConflictException) {
    return `${error.message}. Read it again and retry.`;
  }
  return error instanceof Error ? error.message : String(error);
}
