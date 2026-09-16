import {
  noteSearch,
  noteGet,
  noteEdit,
  listNotes,
  noteReminders,
  noteAttachments,
  tools,
} from './tools';
import type { McpUserContext, McpServices } from './tools';

const user: McpUserContext = {
  userId: 'u1',
  authMethod: 'apiToken',
  scope: 'readWrite',
};

const searchNotes = jest.fn().mockResolvedValue([
  {
    id: 'n1',
    title: 'Groceries',
    isArchived: false,
    state: 'active',
    updatedAt: '2026-01-01',
  },
]);
const getNote = jest.fn().mockResolvedValue({
  id: 'n1',
  title: 'Groceries',
  content: 'milk',
  state: 'active',
  isArchived: false,
  version: 3,
  updatedAt: '2026-01-01',
});
const updateNote = jest
  .fn()
  .mockResolvedValue({ id: 'n1', title: 'Groceries v2' });
const listHistory = jest.fn().mockResolvedValue({ revisions: [] });
const findRevision = jest.fn().mockResolvedValue({ id: 'r1', content: 'milk' });
const restoreRevision = jest
  .fn()
  .mockResolvedValue({ id: 'n1', title: 'Groceries' });
const listReminders = jest.fn().mockResolvedValue([]);
const listAttachments = jest.fn().mockResolvedValue([]);
const findArchived = jest.fn().mockResolvedValue([]);
const findTrashed = jest.fn().mockResolvedValue([]);

const services = {
  notes: {
    findAll: searchNotes,
    findOne: getNote,
    update: updateNote,
    findArchived,
    findTrashed,
    listReminders,
  },
  history: {
    list: listHistory,
    findOne: findRevision,
    restore: restoreRevision,
  },
  attachments: { findAll: listAttachments },
  tags: {},
  baseUrl: 'https://notes.example.com',
} as unknown as McpServices;

describe('mcp tools', () => {
  beforeEach(() => jest.clearAllMocks());

  it('exposes only the registered tools', () => {
    expect(Object.keys(tools).sort()).toEqual([
      'list_notes',
      'note_attachments',
      'note_edit',
      'note_get',
      'note_history',
      'note_reminders',
      'note_render',
      'note_search',
      'tag_manage',
    ]);
  });

  it('marks the raw-content tool as app-only (hidden from LLM clients)', () => {
    expect(tools.note_render.visibility).toBe('app');
    // The generic read tool must stay default so LLMs can still get summary.
    expect(tools.note_get.visibility).toBeUndefined();
  });

  it('note_render returns the full rendering payload (Quill Delta)', async () => {
    const out = await tools.note_render.run(user, { noteId: 'n1' }, services);
    expect(getNote).toHaveBeenCalledWith('u1', 'n1');
    const sc = out.structuredContent as {
      title: string;
      content: string;
      version?: number;
      tagIds: string[];
    };
    expect(sc.title).toBe('Groceries');
    expect(sc.content).toBe('milk');
    // version lets the embedded viewer detect stale data for live updates.
    expect(sc.version).toBe(3);
  });

  it("note_attachments lists a note's attachments (action=list)", async () => {
    listAttachments.mockResolvedValue([
      {
        id: 'a1',
        noteId: 'n1',
        originalFilename: 'pic.png',
        type: 'image',
        fileSize: 123,
        createdAt: '2026-01-01',
      },
    ]);
    const out = await noteAttachments.run(
      user,
      { noteId: 'n1', action: 'list' },
      services,
    );
    expect(listAttachments).toHaveBeenCalledWith('u1', 'n1');
    const sc = out.structuredContent as {
      attachments: Array<{ filename: string }>;
    };
    expect(sc.attachments[0].filename).toBe('pic.png');
  });

  it('note_attachments action=download returns a URL + curl command (Atlassian style)', async () => {
    const out = await noteAttachments.run(
      user,
      { noteId: 'n1', action: 'download', attachmentId: 'a1' },
      services,
    );
    const sc = out.structuredContent as { url: string; command: string };
    expect(sc.url).toBe(
      'https://notes.example.com/api/notes/n1/attachments/a1',
    );
    expect(sc.command).toContain('curl');
  });

  it('note_attachments action=upload returns a curl command to POST the file out-of-band', async () => {
    const out = await noteAttachments.run(
      user,
      { noteId: 'n1', action: 'upload', filename: '/tmp/x.png' },
      services,
    );
    const sc = out.structuredContent as { url: string; command: string };
    expect(sc.url).toBe('https://notes.example.com/api/notes/n1/attachments');
    expect(sc.command).toContain('-F "file=@/tmp/x.png"');
  });

  it('note_attachments action=remove requires confirm and calls the removal service', async () => {
    const remove = jest.fn().mockResolvedValue(undefined);
    const svc = {
      ...services,
      attachments: { findAll: listAttachments, remove },
    } as never;

    const refused = await noteAttachments.run(
      user,
      { noteId: 'n1', action: 'remove', attachmentId: 'a1' },
      svc,
    );
    expect(refused.isError).toBe(true);
    expect(remove).not.toHaveBeenCalled();

    const okRes = await noteAttachments.run(
      user,
      { noteId: 'n1', action: 'remove', attachmentId: 'a1', confirm: true },
      svc,
    );
    expect(remove).toHaveBeenCalledWith('u1', 'n1', 'a1');
    expect(okRes.isError).toBeUndefined();
  });

  it("note_reminders lists the user's reminders, filtering trash by default", async () => {
    listReminders.mockResolvedValue([
      {
        noteId: 'n1',
        title: 'Groceries',
        remindAt: '2026-10-01T09:00',
        recurrence: 'daily',
        noteState: 'active',
      },
      {
        noteId: 'n2',
        title: 'Old',
        remindAt: '2026-10-02T09:00',
        recurrence: 'none',
        noteState: 'trashed',
      },
    ]);
    const out = await noteReminders.run(user, {}, services);
    expect(listReminders).toHaveBeenCalledWith('u1');
    const sc = out.structuredContent as {
      reminders: Array<{ noteId: string }>;
    };
    expect(sc.reminders.map((r) => r.noteId)).toEqual(['n1']);

    const all = await noteReminders.run(user, { state: 'all' }, services);
    const scAll = all.structuredContent as {
      reminders: Array<{ noteId: string }>;
    };
    expect(scAll.reminders).toHaveLength(2);
  });

  it('note_reminders action=set writes a reminder via the notes service', async () => {
    const out = await noteReminders.run(
      user,
      {
        action: 'set',
        noteId: 'n1',
        remindAt: '2026-10-05T09:00',
        recurrence: 'daily',
      },
      services,
    );
    expect(updateNote).toHaveBeenCalledWith('u1', 'n1', {
      reminder: { remindAt: '2026-10-05T09:00', recurrence: 'daily' },
    });
    expect(out.isError).toBeUndefined();
  });

  it('note_reminders action=clear removes the reminder', async () => {
    const out = await noteReminders.run(
      user,
      { action: 'clear', noteId: 'n1' },
      services,
    );
    expect(updateNote).toHaveBeenCalledWith('u1', 'n1', { reminder: null });
    expect(out.isError).toBeUndefined();
  });

  it('note_reminders rejects a malformed remindAt', async () => {
    const out = await noteReminders.run(
      user,
      { action: 'set', noteId: 'n1', remindAt: 'soon' },
      services,
    );
    expect(out.isError).toBe(true);
    expect(updateNote).not.toHaveBeenCalled();
  });

  it('note_history view returns a revision content by id', async () => {
    const out = await tools.note_history.run(
      user,
      { noteId: 'n1', action: 'view', revisionId: 'r1' },
      services,
    );
    expect(findRevision).toHaveBeenCalledWith('u1', 'n1', 'r1');
    const sc = out.structuredContent as { revision: { content?: string } };
    expect(sc.revision.content).toBe('milk');
  });

  it('note_history restore requires confirm and restores the note', async () => {
    const refused = await tools.note_history.run(
      user,
      { noteId: 'n1', action: 'restore', revisionId: 'r1' },
      services,
    );
    expect(refused.isError).toBe(true);
    expect(restoreRevision).not.toHaveBeenCalled();

    const ok = await tools.note_history.run(
      user,
      { noteId: 'n1', action: 'restore', revisionId: 'r1', confirm: true },
      services,
    );
    expect(restoreRevision).toHaveBeenCalledWith('u1', 'n1', 'r1');
    expect(ok.isError).toBeUndefined();
  });

  it('list_notes routes to the archived/trashed/active collections', async () => {
    findArchived.mockResolvedValue([{ id: 'a1', title: 'Arc' }]);
    const archived = await listNotes.run(user, { scope: 'archived' }, services);
    expect(findArchived).toHaveBeenCalledWith('u1');
    const archivedSc = archived.structuredContent as {
      notes: Array<{ id: string }>;
    };
    expect(archivedSc.notes[0].id).toBe('a1');

    await listNotes.run(user, { scope: 'trashed' }, services);
    expect(findTrashed).toHaveBeenCalledWith('u1');

    await listNotes.run(user, { scope: 'active' }, services);
    expect(searchNotes).toHaveBeenCalledWith(
      'u1',
      undefined,
      undefined,
      undefined,
    );
  });

  it('list_notes trashed scope returns the trash collection', async () => {
    findTrashed.mockResolvedValue([{ id: 't1', title: 'Old' }]);
    const trashed = await listNotes.run(user, { scope: 'trashed' }, services);
    const trashedSc = trashed.structuredContent as { scope: string };
    expect(trashedSc.scope).toBe('trashed');
    expect(listNotes.inputShape.scope).toContain('trashed');
  });

  it('note_search forwards query and returns structured results', async () => {
    const out = await noteSearch.run(
      user,
      { query: 'groc', limit: 5 },
      services,
    );
    expect(searchNotes).toHaveBeenCalledWith('u1', 'groc', undefined, 5);
    const outAny = out.structuredContent as {
      notes: Array<{ id: string }>;
    };
    expect(outAny.notes[0].id).toBe('n1');
    expect(out.isError).toBeUndefined();
  });

  it('note_get in summary mode omits content', async () => {
    const out = await noteGet.run(user, { noteId: 'n1' }, services);
    expect(getNote).toHaveBeenCalledWith('u1', 'n1');
    expect(out.structuredContent).not.toHaveProperty('content');
  });

  it('note_get in full mode includes content', async () => {
    const out = await noteGet.run(
      user,
      { noteId: 'n1', mode: 'full' },
      services,
    );
    expect((out.structuredContent as { content: string }).content).toBe('milk');
  });

  it('note_edit returns an error for missing noteId', async () => {
    const out = await noteEdit.run(user, { title: 'x' }, services);
    expect(out.isError).toBe(true);
    expect(updateNote).not.toHaveBeenCalled();
  });

  it('note_edit forwards updates to the notes service', async () => {
    const out = await noteEdit.run(
      user,
      { noteId: 'n1', title: 'Groceries v2', baseVersion: 3 },
      services,
    );
    expect(updateNote).toHaveBeenCalledWith('u1', 'n1', {
      title: 'Groceries v2',
      baseVersion: 3,
    });
    expect(out.structuredContent?.title).toBe('Groceries v2');
  });
});
