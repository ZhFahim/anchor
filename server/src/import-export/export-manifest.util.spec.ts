import {
  attachmentArchivePath,
  buildManifest,
  buildManifestNote,
  ExportNoteRow,
} from './export-manifest.util';

const USER_ID = 'user-1';
const OTHER_USER_ID = 'user-2';

const makeNote = (overrides: Partial<ExportNoteRow> = {}): ExportNoteRow => ({
  id: 'note-1',
  title: 'My note',
  content: '{"ops":[{"insert":"hello\\n"}]}',
  state: 'active',
  isArchived: false,
  background: null,
  createdAt: new Date('2025-01-01T10:00:00.000Z'),
  updatedAt: new Date('2025-02-01T10:00:00.500Z'),
  tags: [],
  pins: [],
  attachments: [],
  sharedWith: [],
  ...overrides,
});

describe('attachmentArchivePath', () => {
  it('builds path from note id, attachment id, and stored extension', () => {
    expect(attachmentArchivePath('n1', 'a1', 'xyz-123.PNG')).toBe(
      'attachments/n1/a1.png',
    );
  });

  it('handles filenames without extension', () => {
    expect(attachmentArchivePath('n1', 'a1', 'noext')).toBe(
      'attachments/n1/a1',
    );
  });
});

describe('buildManifestNote', () => {
  it('maps owned note fields and preserves content verbatim', () => {
    const note = makeNote({
      background: 'color_teal',
      isArchived: true,
      pins: [{ userId: USER_ID }],
    });
    const entry = buildManifestNote(note, 'owned', USER_ID);

    expect(entry).toMatchObject({
      id: 'note-1',
      origin: 'owned',
      title: 'My note',
      content: '{"ops":[{"insert":"hello\\n"}]}',
      state: 'active',
      isArchived: true,
      isPinned: true,
      background: 'color_teal',
      createdAt: '2025-01-01T10:00:00.000Z',
      updatedAt: '2025-02-01T10:00:00.500Z',
    });
    expect(entry.sharedBy).toBeUndefined();
  });

  it('marks trashed state and ignores other users pins', () => {
    const note = makeNote({
      state: 'trashed',
      pins: [{ userId: OTHER_USER_ID }],
    });
    const entry = buildManifestNote(note, 'owned', USER_ID);
    expect(entry.state).toBe('trashed');
    expect(entry.isPinned).toBe(false);
  });

  it('only includes the exporting users tags', () => {
    const note = makeNote({
      tags: [
        { id: 'tag-mine', userId: USER_ID },
        { id: 'tag-theirs', userId: OTHER_USER_ID },
      ],
    });
    const entry = buildManifestNote(note, 'owned', USER_ID);
    expect(entry.tagIds).toEqual(['tag-mine']);
  });

  it('adds sharedBy metadata for shared notes', () => {
    const note = makeNote({
      sharedWith: [
        {
          sharedWithUserId: USER_ID,
          sharedByUser: { name: 'Alice', email: 'alice@example.com' },
        },
        {
          sharedWithUserId: OTHER_USER_ID,
          sharedByUser: { name: 'Bob', email: 'bob@example.com' },
        },
      ],
    });
    const entry = buildManifestNote(note, 'shared', USER_ID);
    expect(entry.origin).toBe('shared');
    expect(entry.sharedBy).toEqual({
      name: 'Alice',
      email: 'alice@example.com',
    });
  });

  it('maps attachments with archive paths', () => {
    const note = makeNote({
      attachments: [
        {
          id: 'att-1',
          type: 'image',
          originalFilename: 'cat.png',
          storedFilename: 'uuid-1.png',
          mimeType: 'image/png',
          fileSize: 100,
          position: 0,
        },
      ],
    });
    const entry = buildManifestNote(note, 'owned', USER_ID);
    expect(entry.attachments).toEqual([
      {
        id: 'att-1',
        type: 'image',
        originalFilename: 'cat.png',
        mimeType: 'image/png',
        fileSize: 100,
        position: 0,
        archivePath: 'attachments/note-1/att-1.png',
      },
    ]);
  });
});

describe('buildManifest', () => {
  it('combines owned and shared notes with counts', () => {
    const owned = makeNote({
      id: 'note-owned',
      attachments: [
        {
          id: 'att-1',
          type: 'image',
          originalFilename: 'a.png',
          storedFilename: 's.png',
          mimeType: 'image/png',
          fileSize: 1,
          position: 0,
        },
      ],
    });
    const shared = makeNote({ id: 'note-shared' });

    const manifest = buildManifest({
      user: { id: USER_ID, email: 'me@example.com' },
      serverVersion: '0.12.0',
      tags: [{ id: 'tag-1', name: 'Work', color: null }],
      ownedNotes: [owned],
      sharedNotes: [shared],
      warnings: [],
    });

    expect(manifest.format).toBe('anchor-export');
    expect(manifest.version).toBe(1);
    expect(manifest.counts).toEqual({ notes: 2, tags: 1, attachments: 1 });
    expect(manifest.notes.map((n) => [n.id, n.origin])).toEqual([
      ['note-owned', 'owned'],
      ['note-shared', 'shared'],
    ]);
  });
});
