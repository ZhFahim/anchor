import { NotesService } from './notes.service';
import { NoteAccessService } from './note-access.service';
import { NoteAttachmentsService } from './note-attachments.service';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * Regression tests for the "tags disappearing from shared notes" bug.
 *
 * Tags are a note-global relation, but the API only ever exposes/accepts a
 * user's own tags. Writes used to `set` (replace) the whole relation, which
 * wiped tags another user had attached to a shared note. These tests exercise
 * the two-user shared-note flow against a small in-memory tag relation and
 * assert the other user's tag survives.
 */
describe('NotesService tag reconciliation (shared notes)', () => {
  const NOTE_ID = 'note-1';
  const OWNER = 'user-owner';
  const EDITOR = 'user-editor';

  interface Tag {
    id: string;
    userId: string;
    isDeleted: boolean;
  }

  interface TagWhere {
    id?: { in: string[] };
    userId: string;
    isDeleted?: boolean;
    notes?: { some: { id: string } };
  }

  interface TagRef {
    id: string;
  }

  interface NoteWrite {
    where: { id: string };
    data?: {
      tags?: { set?: TagRef[]; connect?: TagRef[]; disconnect?: TagRef[] };
    };
  }

  let tags: Tag[];
  let noteTags: Set<string>; // `${noteId}:${tagId}`
  let service: NotesService;

  const pair = (noteId: string, tagId: string) => `${noteId}:${tagId}`;

  const tagFindMany = ({ where }: { where: TagWhere }): Promise<TagRef[]> => {
    // Shape 1: ownable tags for the caller — { id: { in }, userId, isDeleted }
    if (where.id?.in) {
      return Promise.resolve(
        tags
          .filter(
            (t) =>
              where.id!.in.includes(t.id) &&
              t.userId === where.userId &&
              t.isDeleted === where.isDeleted,
          )
          .map((t) => ({ id: t.id })),
      );
    }
    // Shape 2: caller's tags attached to a note — { userId, notes: { some } }
    const noteId = where.notes!.some.id;
    return Promise.resolve(
      tags
        .filter(
          (t) => t.userId === where.userId && noteTags.has(pair(noteId, t.id)),
        )
        .map((t) => ({ id: t.id })),
    );
  };

  const noteUpdate = ({ where, data }: NoteWrite) => {
    if (data?.tags) {
      // Honor `set` (full replace) too, so a regression to the old behavior is
      // actually reproduced and caught by these tests.
      if (data.tags.set) {
        for (const t of tags) noteTags.delete(pair(where.id, t.id));
        for (const { id } of data.tags.set) noteTags.add(pair(where.id, id));
      }
      for (const { id } of data.tags.connect ?? []) {
        noteTags.add(pair(where.id, id));
      }
      for (const { id } of data.tags.disconnect ?? []) {
        noteTags.delete(pair(where.id, id));
      }
    }
    return Promise.resolve({ id: where.id });
  };

  const attachedTagsFor = (noteId: string) =>
    tags
      .filter((t) => noteTags.has(pair(noteId, t.id)))
      .map((t) => ({ id: t.id, userId: t.userId }));

  const noteUpdateMock = jest.fn(noteUpdate);

  const prisma = {
    $transaction: (cb: (tx: PrismaService) => unknown) => cb(prisma),
    note: {
      update: noteUpdateMock,
      findUniqueOrThrow: jest.fn(({ where }: { where: { id: string } }) =>
        Promise.resolve({
          id: where.id,
          title: 'Groceries',
          content: null,
          isArchived: false,
          background: null,
          state: 'active',
          createdAt: new Date(),
          updatedAt: new Date(),
          userId: OWNER,
          tags: attachedTagsFor(where.id),
          pins: [],
        }),
      ),
    },
    tag: { findMany: jest.fn(tagFindMany) },
    notePin: { upsert: jest.fn(), deleteMany: jest.fn() },
  } as unknown as PrismaService;

  const noteAccess = {
    ensureNoteAccess: jest.fn().mockResolvedValue(undefined),
  } as unknown as NoteAccessService;

  beforeEach(() => {
    tags = [
      { id: 'tag-owner', userId: OWNER, isDeleted: false },
      { id: 'tag-family', userId: EDITOR, isDeleted: false },
    ];
    noteTags = new Set([
      pair(NOTE_ID, 'tag-owner'),
      pair(NOTE_ID, 'tag-family'),
    ]);
    service = new NotesService(
      prisma,
      noteAccess,
      {} as unknown as NoteAttachmentsService,
    );
    jest.clearAllMocks();
  });

  it("owner's update does not drop the editor's tag on a shared note", async () => {
    // Owner saves the note; their client only knows about their own tag.
    await service.update(OWNER, NOTE_ID, { tagIds: ['tag-owner'] });

    expect(noteTags.has(pair(NOTE_ID, 'tag-family'))).toBe(true);
    expect(noteTags.has(pair(NOTE_ID, 'tag-owner'))).toBe(true);
  });

  it("editor's update does not drop the owner's tag on a shared note", async () => {
    await service.update(EDITOR, NOTE_ID, { tagIds: ['tag-family'] });

    expect(noteTags.has(pair(NOTE_ID, 'tag-owner'))).toBe(true);
    expect(noteTags.has(pair(NOTE_ID, 'tag-family'))).toBe(true);
  });

  it("removing the caller's own tag leaves the other user's tag intact", async () => {
    await service.update(EDITOR, NOTE_ID, { tagIds: [] });

    expect(noteTags.has(pair(NOTE_ID, 'tag-family'))).toBe(false);
    expect(noteTags.has(pair(NOTE_ID, 'tag-owner'))).toBe(true);
  });

  it('cannot attach a tag owned by another user', async () => {
    // A foreign tag that is not yet on the note must stay unattached.
    tags.push({ id: 'tag-owner-2', userId: OWNER, isDeleted: false });

    await service.update(EDITOR, NOTE_ID, {
      tagIds: ['tag-owner-2', 'tag-family'],
    });

    expect(noteTags.has(pair(NOTE_ID, 'tag-owner-2'))).toBe(false);
    // The editor's own tag and the owner's existing tag are untouched.
    expect(noteTags.has(pair(NOTE_ID, 'tag-family'))).toBe(true);
    expect(noteTags.has(pair(NOTE_ID, 'tag-owner'))).toBe(true);
  });

  it("adds the caller's new tag without a full-relation replace", async () => {
    noteTags = new Set([pair(NOTE_ID, 'tag-owner')]);
    await service.update(EDITOR, NOTE_ID, { tagIds: ['tag-family'] });

    const tagWrite = noteUpdateMock.mock.calls
      .map(([arg]) => arg)
      .find((arg) => arg.data?.tags);
    // The write must be a targeted connect/disconnect, never a `set`.
    expect(tagWrite?.data?.tags?.set).toBeUndefined();
    expect(tagWrite?.data?.tags?.connect).toEqual([{ id: 'tag-family' }]);
    expect(noteTags.has(pair(NOTE_ID, 'tag-owner'))).toBe(true);
  });
});
