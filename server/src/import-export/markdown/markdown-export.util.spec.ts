import { ExportManifestNote, ExportManifestV1 } from '../export-manifest.util';
import { noteFolder, planMarkdownExport } from './markdown-export.util';

const makeNote = (
  overrides: Partial<ExportManifestNote> = {},
): ExportManifestNote => ({
  id: 'note-1',
  origin: 'owned',
  title: 'My note',
  content: '{"ops":[{"insert":"hello\\n"}]}',
  state: 'active',
  isArchived: false,
  isPinned: false,
  background: null,
  tagIds: [],
  createdAt: '2025-01-01T10:00:00.000Z',
  updatedAt: '2025-02-01T10:00:00.000Z',
  attachments: [],
  ...overrides,
});

const makeManifest = (notes: ExportManifestNote[]): ExportManifestV1 => ({
  format: 'anchor-export',
  version: 1,
  exportedAt: '2025-03-01T00:00:00.000Z',
  server: { version: '0.16.0' },
  user: { id: 'user-1', email: 'a@b.c' },
  counts: { notes: notes.length, tags: 0, attachments: 0 },
  tags: [],
  notes,
  warnings: [],
});

describe('noteFolder', () => {
  it('separates archived and shared notes', () => {
    expect(noteFolder(makeNote())).toBe('');
    expect(noteFolder(makeNote({ isArchived: true }))).toBe('Archived/');
    expect(noteFolder(makeNote({ origin: 'shared' }))).toBe('Shared/');
    expect(noteFolder(makeNote({ origin: 'shared', isArchived: true }))).toBe(
      'Shared/',
    );
  });
});

describe('planMarkdownExport', () => {
  it('writes one markdown file per note', () => {
    const { entries } = planMarkdownExport(makeManifest([makeNote()]));

    expect(entries).toEqual([
      {
        path: 'My note.md',
        markdown: 'hello\n',
        updatedAt: '2025-02-01T10:00:00.000Z',
        attachments: [],
      },
    ]);
  });

  it('leaves trashed notes out', () => {
    const { entries } = planMarkdownExport(
      makeManifest([
        makeNote({ id: 'a' }),
        makeNote({ id: 'b', title: 'Gone', state: 'trashed' }),
      ]),
    );
    expect(entries.map((entry) => entry.path)).toEqual(['My note.md']);
  });

  it('places archived and shared notes in their own folders', () => {
    const { entries } = planMarkdownExport(
      makeManifest([
        makeNote({ id: 'a', title: 'Plan', isArchived: true }),
        makeNote({ id: 'b', title: 'Team', origin: 'shared' }),
      ]),
    );
    expect(entries.map((entry) => entry.path)).toEqual([
      'Archived/Plan.md',
      'Shared/Team.md',
    ]);
  });

  it('deduplicates names within a folder only', () => {
    const { entries } = planMarkdownExport(
      makeManifest([
        makeNote({ id: 'a', title: 'Groceries' }),
        makeNote({ id: 'b', title: 'Groceries' }),
        makeNote({ id: 'c', title: 'Groceries', isArchived: true }),
      ]),
    );
    expect(entries.map((entry) => entry.path)).toEqual([
      'Groceries.md',
      'Groceries (2).md',
      'Archived/Groceries.md',
    ]);
  });

  it('sanitizes titles and falls back to Untitled', () => {
    const { entries } = planMarkdownExport(
      makeManifest([
        makeNote({ id: 'a', title: 'a/b: c?' }),
        makeNote({ id: 'b', title: '' }),
      ]),
    );
    expect(entries.map((entry) => entry.path)).toEqual([
      'a b c.md',
      'Untitled.md',
    ]);
  });

  it('appends attachment references and maps their archive paths', () => {
    const { entries } = planMarkdownExport(
      makeManifest([
        makeNote({
          title: 'Trip',
          attachments: [
            {
              id: 'att-1',
              type: 'image',
              originalFilename: 'my photo.JPG',
              mimeType: 'image/jpeg',
              fileSize: 10,
              position: 0,
              archivePath: 'attachments/note-1/att-1.jpg',
            },
            {
              id: 'att-2',
              type: 'audio',
              originalFilename: 'memo.m4a',
              mimeType: 'audio/x-m4a',
              fileSize: 20,
              position: 1,
              archivePath: 'attachments/note-1/att-2.m4a',
            },
          ],
        }),
      ]),
    );

    expect(entries[0].markdown).toBe(
      [
        'hello',
        '',
        '![my photo.jpg](attachments/Trip/my%20photo.jpg)',
        '[memo.m4a](attachments/Trip/memo.m4a)',
        '',
      ].join('\n'),
    );
    expect(entries[0].attachments).toEqual([
      { attachmentId: 'att-1', archivePath: 'attachments/Trip/my photo.jpg' },
      { attachmentId: 'att-2', archivePath: 'attachments/Trip/memo.m4a' },
    ]);
  });

  it('keeps attachment references when the body is empty', () => {
    const { entries } = planMarkdownExport(
      makeManifest([
        makeNote({
          title: 'Photo',
          content: '{"ops":[{"insert":"\\n"}]}',
          attachments: [
            {
              id: 'att-1',
              type: 'image',
              originalFilename: 'shot.png',
              mimeType: 'image/png',
              fileSize: 10,
              position: 0,
              archivePath: 'attachments/note-1/att-1.png',
            },
          ],
        }),
      ]),
    );
    expect(entries[0].markdown).toBe(
      '![shot.png](attachments/Photo/shot.png)\n',
    );
  });

  it('exports an empty body and warns when the content is unreadable', () => {
    const { entries, warnings } = planMarkdownExport(
      makeManifest([makeNote({ content: 'not delta' })]),
    );
    expect(entries[0].markdown).toBe('');
    expect(warnings).toEqual([
      'Note note-1 has unreadable content and was exported empty',
    ]);
  });

  it('carries manifest warnings through', () => {
    const manifest = makeManifest([makeNote()]);
    manifest.warnings.push('Attachment file missing on disk: a.png');
    expect(planMarkdownExport(manifest).warnings).toEqual([
      'Attachment file missing on disk: a.png',
    ]);
  });
});
