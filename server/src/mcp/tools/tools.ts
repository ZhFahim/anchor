import { NotesService } from '../../notes/services/notes.service';
import { NoteHistoryService } from '../../notes/services/note-history.service';
import { NoteAttachmentsService } from '../../notes/services/note-attachments.service';
import { TagsService } from '../../tags/tags.service';
import { SyncReminderRecurrence } from '../../sync/dto/sync-request.dto';
import { applyTargetedEdit, validateDelta } from './targeted-delta';
import type { McpUserContext } from '../mcp-auth.context';

export type { McpUserContext };

/** A single tool binding: schema-free, handler reads services + current user. */
export interface ToolBinding {
  name: string;
  title: string;
  description: string;
  inputShape: Record<string, string>;
  readOnlyHint: boolean;
  /** Visibility of the tool (plan P7/P10): default tools are shown to every
   * client; 'app' tools only feed the embedded MCP-apps rendering bundle so
   * note content never enters the LLM context unless it asks. */
  visibility?: 'default' | 'app';
  /** Unrecoverable ops require an explicit `confirm: true` (P4). */
  confirmRequired?: boolean;
  /**
   * For multi-mode tools (e.g. an `action` param), the subset of action values
   * that are read-only. When present and the incoming action is in this set,
   * the call is treated as read-only and allowed even for a read-only token;
   * other actions are gated as writes.
   */
  readOnlyActions?: string[];
  run: (
    user: McpUserContext,
    params: Record<string, unknown>,
    services: McpServices,
  ) => Promise<ToolResult>;
}

export interface McpServices {
  notes: NotesService;
  history: NoteHistoryService;
  attachments: NoteAttachmentsService;
  tags: TagsService;
  /** Public base URL of the Anchor server (for building download/upload URLs). */
  baseUrl: string;
}
export interface ToolResult {
  content: Array<{ type: 'text'; text: string }>;
  // JSON-serializable structured payload for MCP clients.
  structuredContent?: Record<string, unknown>;
  isError?: boolean;
}

const ok = (
  text: string,
  structured?: Record<string, unknown>,
): ToolResult => ({
  content: [{ type: 'text', text }],
  ...(structured !== undefined ? { structuredContent: structured } : {}),
});

const err = (message: string): ToolResult => ({
  content: [{ type: 'text', text: message }],
  isError: true,
});

function tryJson(raw: string): Record<string, unknown> | null {
  try {
    const parsed: unknown = JSON.parse(raw);
    return parsed && typeof parsed === 'object'
      ? (parsed as Record<string, unknown>)
      : null;
  } catch {
    return null;
  }
}

const requireIds = (
  params: Record<string, unknown>,
  keys: string[],
): string[] =>
  keys.map((k) => {
    const v = params[k];
    if (typeof v !== 'string' || !v) {
      throw new Error(`Missing required string parameter: ${k}`);
    }
    return v;
  });

export const noteSearch: ToolBinding = {
  name: 'note_search',
  title: 'Search Notes',
  description: `Search the user's notes by title or content. Accepts a query string and optional filters.

Returns a list of matching notes with id, title, and a short state summary. Note content is not included; call note_get for detail.`,
  inputShape: {
    query:
      'string (required). Search text to match against title and content. Empty means list all active notes.',
    tagId: 'string (optional). Only notes carrying this tag id.',
    limit: 'number (optional, max 200). Maximum results.',
  },
  readOnlyHint: true,
  async run(user, params, { notes }) {
    const [query] = [params.query];
    const search =
      typeof query === 'string' && query.trim() ? query.trim() : undefined;
    const tagId = typeof params.tagId === 'string' ? params.tagId : undefined;
    const rawLimit = params.limit;
    const limit = typeof rawLimit === 'number' ? rawLimit : undefined;

    const rows = await notes.findAll(user.userId, search, tagId, limit);
    if (rows.length === 0) {
      return ok('No notes found' + (search ? ` for "${search}"` : '') + '.');
    }
    const lines = rows.map(
      (n) =>
        `- ${n.title || '(untitled)'}  (id: ${n.id}${n.isArchived ? ', archived' : ''})`,
    );
    return ok(`Found ${rows.length} note(s):\n${lines.join('\n')}`, {
      notes: rows.map((n) => ({
        id: n.id,
        title: n.title,
        isArchived: n.isArchived,
        state: n.state,
        updatedAt: n.updatedAt,
      })),
    });
  },
};

export const noteGet: ToolBinding = {
  name: 'note_get',
  title: 'Get a Note',
  description: `Return a single note. The mode parameter controls how much is returned: summary (id, title, state, updatedAt) is the default and cheapest; full returns the raw content too.

Prefer summary or range over full to keep the response small.`,
  inputShape: {
    noteId: 'string (required).',
    mode: "string (optional): 'summary' | 'full'. Default 'summary'.",
  },
  readOnlyHint: true,
  async run(user, params, { notes }) {
    const [noteId] = requireIds(params, ['noteId']);
    const mode = params.mode === 'full' ? 'full' : 'summary';
    const note = await notes.findOne(user.userId, noteId);
    if (mode === 'summary') {
      return ok(
        `${note.title || '(untitled)'}\nState: ${note.state}${note.isArchived ? ', archived' : ''}\nUpdated: ${note.updatedAt}\nid: ${note.id}`,
        {
          id: note.id,
          title: note.title,
          state: note.state,
          isArchived: note.isArchived,
          updatedAt: note.updatedAt,
        },
      );
    }
    return ok(`${note.title || '(untitled)'}\n\n${note.content ?? ''}`, {
      id: note.id,
      title: note.title,
      content: note.content ?? '',
    });
  },
};

export const noteHistory: ToolBinding = {
  name: 'note_history',
  title: 'Note History',
  description: `Work with a note's past revisions (the undo history), newest first. The action parameter selects the operation:
- 'list' (default): recent revisions with timestamps and titles.
- 'view': the full content of one revision by id.
- 'restore': revert the note to a past revision (an undo). Use list to find the revision, then restore with its revisionId.`,
  inputShape: {
    noteId: 'string (required).',
    action: "string (optional): 'list' | 'view' | 'restore'. Default 'list'.",
    revisionId: 'string (required for view/restore).',
    limit: 'number (optional, default 20, max 100).',
    confirm:
      "boolean (optional). 'restore' rewrites the note; pass true to confirm.",
  },
  readOnlyHint: false,
  readOnlyActions: ['list', 'view'],
  async run(user, params, { history }) {
    const [noteId] = requireIds(params, ['noteId']);
    const action =
      params.action === 'view' || params.action === 'restore'
        ? params.action
        : 'list';

    if (action === 'view') {
      const revisionId = params.revisionId;
      if (typeof revisionId !== 'string' || !revisionId) {
        return err('revisionId is required for view.');
      }
      const revision = await history.findOne(user.userId, noteId, revisionId);
      return ok(revision.content ?? '', { revision });
    }

    if (action === 'restore') {
      if (params.confirm !== true) {
        return err(
          'restore rewrites the note. Retry with "confirm": true to proceed.',
        );
      }
      const revisionId = params.revisionId;
      if (typeof revisionId !== 'string' || !revisionId) {
        return err('revisionId is required for restore.');
      }
      const restored = await history.restore(user.userId, noteId, revisionId);
      return ok(`Restored note to revision ${revisionId}.`, {
        revisionId,
        note: restored,
      });
    }

    // list (default)
    const limit =
      typeof params.limit === 'number' &&
      Number.isInteger(params.limit) &&
      params.limit > 0 &&
      params.limit <= 100
        ? params.limit
        : 20;
    const page = await history.list(user.userId, noteId, { limit });
    if (page.revisions.length === 0) {
      return ok('No revisions found for this note.');
    }
    return ok(
      page.revisions
        .map(
          (r, i) =>
            `${i + 1}. ${new Date(r.createdAt).toISOString()} — ${r.title || '(untitled)'}`,
        )
        .join('\n'),
      { revisions: page.revisions },
    );
  },
};

/**
 * App-only tool (P10): feeds the embedded MCP-apps rendering bundle the raw
 * note data it needs to render Quill Delta faithfully. Not exposed to normal
 * LLM clients — keeps note content out of the LLM context unless it asks.
 */
export const noteRender: ToolBinding = {
  name: 'note_render',
  title: 'Render a Note (app-only)',
  description: `App-only: return the full note rendering payload (id, title, and Quill Delta content) for the embedded review UI. Not intended for direct LLM use.`,
  inputShape: {
    noteId: 'string (required).',
  },
  readOnlyHint: true,
  visibility: 'app',
  async run(user, params, { notes }) {
    const [noteId] = requireIds(params, ['noteId']);
    const note = await notes.findOne(user.userId, noteId);
    return ok('', {
      id: note.id,
      title: note.title,
      content: note.content ?? '',
      state: note.state,
      isArchived: note.isArchived,
      updatedAt: note.updatedAt,
      version: note.version,
      tagIds: note.tagIds ?? [],
    });
  },
};

export const noteEdit: ToolBinding = {
  name: 'note_edit',
  title: 'Edit a Note',
  description: `Update a note's title, make a targeted line edit, set a reminder, or (rarely) replace the whole body.

Prefer the targeted 'edit_op' for content changes: the server applies a deterministic line-level transform so you never rewrite the whole note. Full-body 'content' is only for cases the line ops can't express and must be valid Quill Delta JSON.

Edits are recoverable: the prior content is saved as a revision and the server's optimistic-concurrency check returns a 409 if the note changed since baseVersion. Pass baseVersion to avoid clobbering concurrent edits.`,
  inputShape: {
    noteId: 'string (required).',
    title: 'string (optional). New title.',
    edit_op:
      "object (optional). A targeted content edit: {op:'append_line'|'insert_after_line'|'replace_line'|'delete_line'|'check_item', line?:number, text?:string, checked?:boolean}. line is 1-based.",
    content:
      'string (optional). Full Quill Delta JSON replacement — use only when edit_op cannot express the change.',
    reminder:
      'string (optional). JSON object {"remindAt":"YYYY-MM-DDTHH:mm","recurrence":"none|daily|weekly|monthly|yearly"}.',
    reminderRecurrence:
      'string (optional). One of none|daily|weekly|monthly|yearly.',
    baseVersion:
      'number (optional). The version the edit is based on, to detect concurrent edits.',
  },
  readOnlyHint: false,
  async run(user, params, { notes }) {
    const noteId = params.noteId;
    if (typeof noteId !== 'string' || !noteId) {
      return err('Missing required string parameter: noteId');
    }
    const titleParam = params.title;
    const contentParam = params.content;
    if (titleParam !== undefined && typeof titleParam !== 'string') {
      return err('title must be a string when provided');
    }
    if (contentParam !== undefined && typeof contentParam !== 'string') {
      return err('content must be a string when provided');
    }
    const data: Record<string, unknown> = {};
    if (titleParam !== undefined) data.title = titleParam;
    if (contentParam !== undefined) {
      // Never persist a malformed body: the web editor silently empties on open.
      try {
        validateDelta(contentParam);
      } catch {
        return err(
          'Invalid content: it must be Quill Delta JSON like {"ops":[...]}. Prefer edit_op for line edits.',
        );
      }
      data.content = contentParam;
    }
    if (params.edit_op !== undefined) {
      // P2: the LLM names the intent; the server performs the Delta transform.
      const note = await notes.findOne(user.userId, noteId);
      const op = params.edit_op;
      try {
        data.content = applyTargetedEdit(
          note.content ?? '{"ops":[]}',
          op as never,
        );
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        return err(`edit_op failed: ${msg}`);
      }
    }
    if (typeof params.baseVersion === 'number')
      data.baseVersion = params.baseVersion;
    if (params.reminder) {
      let remindAt: unknown;
      let recurrence: unknown;
      if (typeof params.reminder === 'object' && params.reminder !== null) {
        const r = params.reminder as Record<string, unknown>;
        remindAt = r.remindAt;
        recurrence = r.recurrence;
      } else if (typeof params.reminder === 'string') {
        const parsed = tryJson(params.reminder);
        if (!parsed) {
          return err(
            'Invalid reminder: expected JSON like {"remindAt":"2026-09-01T09:00","recurrence":"daily"}.',
          );
        }
        remindAt = parsed.remindAt;
        recurrence = parsed.recurrence;
      }
      if (typeof remindAt !== 'string' || !remindAt) {
        return err('Invalid reminder: remindAt must be a non-empty string.');
      }
      data.reminder = {
        remindAt,
        recurrence: typeof recurrence === 'string' ? recurrence : 'none',
      };
    }
    if (Object.keys(data).length === 0) {
      return err(
        'Nothing to edit: provide at least title, content, or reminder.',
      );
    }
    const updated = await notes.update(user.userId, noteId, data);
    return ok(
      `Updated note ${updated.title || '(untitled)'} (id: ${updated.id}).`,
      {
        id: updated.id,
        title: updated.title,
      },
    );
  },
};

export const listNotes: ToolBinding = {
  name: 'list_notes',
  title: 'List Notes',
  description: `List the user's notes by collection. Use this to enumerate pinned or archived notes, or to inspect the trash before a restore. Prefer note_search with a query when you already know the topic.`,
  inputShape: {
    scope:
      "string (optional): 'active' (default, non-archived active), 'archived', 'trashed'. Which collection to list.",
    limit: 'number (optional). Maximum results.',
  },
  readOnlyHint: true,
  async run(user, params, { notes }) {
    const scope =
      params.scope === 'archived'
        ? 'archived'
        : params.scope === 'trashed'
          ? 'trashed'
          : 'active';

    let rows: Array<{ id: string; title: string }>;
    if (scope === 'archived') {
      rows = await notes.findArchived(user.userId);
    } else if (scope === 'trashed') {
      rows = await notes.findTrashed(user.userId);
    } else {
      const rawLimit = params.limit;
      rows = await notes.findAll(
        user.userId,
        undefined,
        undefined,
        typeof rawLimit === 'number' ? rawLimit : undefined,
      );
    }

    if (rows.length === 0) {
      return ok(`No ${scope} notes.`);
    }
    return ok(
      rows.map((n) => `- ${n.title || '(untitled)'} (id: ${n.id})`).join('\n'),
      {
        scope,
        notes: rows.map((n) => ({ id: n.id, title: n.title })),
      },
    );
  },
};

export const noteReminders: ToolBinding = {
  name: 'note_reminders',
  title: 'Manage Reminders',
  description: `Work with note reminders. Reminders are per-person (not per-note). The action parameter picks the operation:
- 'list' (default): the current user's reminders, soonest first.
- 'set': set a reminder on a note (remindAt in "YYYY-MM-DDTHH:mm", local wall clock; recurrence none|daily|weekly|monthly|yearly).
- 'clear': remove the reminder from a note.`,
  inputShape: {
    action: "string (optional): 'list' | 'set' | 'clear'. Default 'list'.",
    state:
      "string (optional, for list): 'active' (default) or 'all'. Filter to non-trashed notes only.",
    noteId: 'string (required for set/clear).',
    remindAt: 'string (required for set). Local wall clock "YYYY-MM-DDTHH:mm".',
    recurrence:
      'string (optional, for set): none|daily|weekly|monthly|yearly. Default none.',
  },
  readOnlyHint: false,
  readOnlyActions: ['list'],
  async run(user, params, { notes }) {
    const action =
      params.action === 'set' || params.action === 'clear'
        ? params.action
        : 'list';

    if (action === 'set') {
      const noteId = params.noteId;
      if (typeof noteId !== 'string' || !noteId) {
        return err('noteId is required to set a reminder.');
      }
      const remindAt = params.remindAt;
      if (
        typeof remindAt !== 'string' ||
        !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(remindAt)
      ) {
        return err(
          'remindAt must be in "YYYY-MM-DDTHH:mm" (local wall clock).',
        );
      }
      const recur =
        params.recurrence === 'daily' ||
        params.recurrence === 'weekly' ||
        params.recurrence === 'monthly' ||
        params.recurrence === 'yearly'
          ? params.recurrence
          : 'none';
      await notes.update(user.userId, noteId, {
        reminder: { remindAt, recurrence: recur as SyncReminderRecurrence },
      });
      return ok(`Set reminder on note ${noteId} for ${remindAt}.`, {
        noteId,
        remindAt,
        recurrence: recur,
      });
    }

    if (action === 'clear') {
      const noteId = params.noteId;
      if (typeof noteId !== 'string' || !noteId) {
        return err('noteId is required to clear a reminder.');
      }
      await notes.update(user.userId, noteId, { reminder: null });
      return ok(`Cleared reminder on note ${noteId}.`, { noteId });
    }

    // list (default)
    const rows = await notes.listReminders(user.userId);
    const onlyActive = params.state !== 'all';
    const visible = onlyActive
      ? rows.filter((r) => r.noteState === 'active')
      : rows;

    if (visible.length === 0) {
      return ok('No upcoming reminders.');
    }
    const lines = visible.map(
      (r) =>
        `- ${r.remindAt}: ${r.title} (note ${r.noteId})${r.recurrence !== 'none' ? `, ${r.recurrence}` : ''}`,
    );
    return ok(lines.join('\n'), {
      reminders: visible.map((r) => ({ ...r })),
    });
  },
};

export const tagCreate: ToolBinding = {
  name: 'tag_manage',
  title: 'Manage Tags',
  description: `Create, rename, recolor, or remove a tag. The action parameter picks the operation:
- 'create': make a new tag (name, optional color).
- 'rename': change a tag's name.
- 'recolor': change a tag's color.
- 'remove': delete a tag and unassign it from all notes. Unrecoverable, so requires confirm:true.`,
  inputShape: {
    action: "string (required): 'create' | 'rename' | 'recolor' | 'remove'.",
    name: 'string (required for create/rename). Tag name.',
    color: 'string (optional). Hex color, e.g. "#3366cc".',
    tagId: 'string (optional, required for rename/recolor/remove).',
    confirm:
      'boolean (optional, required for remove). Confirm unrecoverable deletion.',
  },
  readOnlyHint: false,
  async run(user, params, { tags }) {
    const action = params.action;
    if (
      action !== 'create' &&
      action !== 'rename' &&
      action !== 'recolor' &&
      action !== 'remove'
    ) {
      return err('Invalid tag action. Use create, rename, recolor, or remove.');
    }

    if (action === 'remove') {
      if (params.confirm !== true) {
        return err(
          'remove is unrecoverable and requires explicit confirmation. Retry with "confirm": true to proceed.',
        );
      }
      const tagId = params.tagId;
      if (typeof tagId !== 'string' || !tagId) {
        return err('tagId is required to remove a tag.');
      }
      await tags.remove(user.userId, tagId);
      return ok(`Removed tag (id: ${tagId}).`, { id: tagId });
    }

    if (action === 'create') {
      const name = params.name;
      if (typeof name !== 'string' || !name.trim()) {
        return err('Tag name is required to create a tag.');
      }
      const color = typeof params.color === 'string' ? params.color : undefined;
      const tag = await tags.create(user.userId, { name, color });
      return ok(`Created tag "${name}" (id: ${tag.id}).`, {
        id: tag.id,
        name,
      });
    }

    const tagId = params.tagId;
    if (typeof tagId !== 'string' || !tagId) {
      return err('tagId is required for rename/recolor.');
    }
    if (action === 'rename') {
      const name = params.name;
      if (typeof name !== 'string' || !name.trim()) {
        return err('A new name is required to rename a tag.');
      }
      await tags.update(user.userId, tagId, { name });
      return ok(`Renamed tag to "${name}".`, { id: tagId, name });
    }
    // recolor
    const color = params.color;
    if (typeof color !== 'string' || !color) {
      return err('A color is required to recolor a tag.');
    }
    await tags.update(user.userId, tagId, { color });
    return ok(`Recolored tag (id: ${tagId}).`, { id: tagId, color });
  },
};

export const noteAttachments: ToolBinding = {
  name: 'note_attachments',
  title: 'Manage Note Attachments',
  description: `Work with the attachments (images, audio, files) on a note. The action parameter selects the operation:
- 'list' (default): attachment metadata (id, file name, type, size) for the note.
- 'download': a URL plus a curl command to save an attachment's bytes. The binary is fetched out-of-band by the client (never inline); the URL needs the same bearer token the MCP server uses.
- 'upload': a URL plus a curl command to POST a local file to the note. The file is sent out-of-band (never inline).
- 'remove': permanently delete an attachment. Unrecoverable, so requires confirm:true.`,
  inputShape: {
    noteId: 'string (required).',
    action:
      "string (optional): 'list' | 'download' | 'upload' | 'remove'. Default 'list'.",
    attachmentId: 'string (required for download/remove).',
    filename: 'string (required for upload). Local path to the file to upload.',
    confirm:
      'boolean (optional, required for remove). Confirm unrecoverable deletion.',
  },
  readOnlyHint: false,
  confirmRequired: false,
  readOnlyActions: ['list', 'download'],
  async run(user, params, { attachments, baseUrl }) {
    const noteId = params.noteId;
    if (typeof noteId !== 'string' || !noteId) {
      return err('noteId is required.');
    }
    const action =
      params.action === 'download' ||
      params.action === 'upload' ||
      params.action === 'remove'
        ? params.action
        : 'list';

    const isWrite = action === 'remove';
    if (isWrite && params.confirm !== true) {
      return err(
        'remove is unrecoverable and requires explicit confirmation. Retry with "confirm": true to proceed.',
      );
    }

    if (action === 'list') {
      const rows = await attachments.findAll(user.userId, noteId);
      if (rows.length === 0) {
        return ok('No attachments on this note.');
      }
      const lines = rows.map(
        (a) =>
          `- ${a.originalFilename} (${a.type}, ${a.fileSize} bytes, id: ${a.id})`,
      );
      return ok(lines.join('\n'), {
        attachments: rows.map((a) => ({
          id: a.id,
          filename: a.originalFilename,
          type: a.type,
          size: a.fileSize,
          createdAt: a.createdAt,
        })),
      });
    }

    if (action === 'download') {
      const attachmentId = params.attachmentId;
      if (typeof attachmentId !== 'string' || !attachmentId) {
        return err('attachmentId is required for download.');
      }
      const base = (baseUrl || '').replace(/\/+$/, '');
      const url = `${base}/api/notes/${encodeURIComponent(noteId)}/attachments/${encodeURIComponent(attachmentId)}`;
      const cmd = `curl -L -H "Authorization: Bearer $ANCHOR_TOKEN" -o "attachment-${attachmentId}" "${url}"`;
      return ok(`Download URL: ${url}\n\n${cmd}`, { url, command: cmd });
    }

    if (action === 'upload') {
      const filename = params.filename;
      if (typeof filename !== 'string' || !filename) {
        return err('filename is required for upload (local path to the file).');
      }
      const base = (baseUrl || '').replace(/\/+$/, '');
      const url = `${base}/api/notes/${encodeURIComponent(noteId)}/attachments`;
      const cmd = `curl -X POST -H "Authorization: Bearer $ANCHOR_TOKEN" -F "file=@${filename}" "${url}"`;
      return ok(`Upload URL: ${url}\n\n${cmd}`, { url, command: cmd });
    }

    // remove
    const attachmentId = params.attachmentId;
    if (typeof attachmentId !== 'string' || !attachmentId) {
      return err('attachmentId is required for remove.');
    }
    await attachments.remove(user.userId, noteId, attachmentId);
    return ok(`Removed attachment (id: ${attachmentId}).`, {
      id: attachmentId,
    });
  },
};

/** Recoverable read ops apply immediately; only remove (delete) is unrecoverable and gated. */
export const tools: Record<string, ToolBinding> = {
  [noteSearch.name]: noteSearch,
  [noteGet.name]: noteGet,
  [noteHistory.name]: noteHistory,
  [noteEdit.name]: noteEdit,
  [listNotes.name]: listNotes,
  [noteReminders.name]: noteReminders,
  tag_manage: tagCreate,
  note_attachments: noteAttachments,
  note_render: noteRender,
};
