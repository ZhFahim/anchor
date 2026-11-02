import type {
  NoteAttachment,
  NoteFile,
  Prisma,
} from 'src/generated/prisma/client';
import type { AttachmentKind } from './attachment-storage.util';

/**
 * A note's attachment as the apps see it: a picture or recording (a
 * NoteAttachment) or any other file (a NoteFile, of type "file"). Files keep
 * a table of their own so upstream Anchor's server, which knows only
 * pictures and recordings, can run on this database.
 */
export type AttachmentRow = Omit<NoteAttachment, 'type'> & {
  type: AttachmentKind;
};

export type AttachmentRowInput = Omit<
  Prisma.NoteAttachmentUncheckedCreateInput,
  'type'
> & { type: AttachmentKind };

type Db = Prisma.TransactionClient;

export function fileAsAttachment(file: NoteFile): AttachmentRow {
  return { ...file, type: 'file', text: null, textReadAt: null };
}

/** Files and the others share one order, by position. */
export function byPosition(
  a: { position: number; createdAt: Date },
  b: { position: number; createdAt: Date },
): number {
  return (
    a.position - b.position || a.createdAt.getTime() - b.createdAt.getTime()
  );
}

/** The attachments of a note, or of several, files included, in order. */
export async function findAttachmentRows(
  db: Db,
  noteId: string | { in: string[] },
): Promise<AttachmentRow[]> {
  const attachments = await db.noteAttachment.findMany({ where: { noteId } });
  const files = await db.noteFile.findMany({ where: { noteId } });
  return [...attachments, ...files.map(fileAsAttachment)].sort(byPosition);
}

export async function findAttachmentRow(
  db: Db,
  id: string,
  noteId?: string,
): Promise<AttachmentRow | null> {
  const where = noteId ? { id, noteId } : { id };
  const attachment = await db.noteAttachment.findFirst({ where });
  if (attachment) return attachment;
  const file = await db.noteFile.findFirst({ where });
  return file ? fileAsAttachment(file) : null;
}

function fileData({
  type: _type,
  text: _text,
  textReadAt: _textReadAt,
  ...file
}: AttachmentRowInput): Prisma.NoteFileUncheckedCreateInput {
  return file;
}

export async function createAttachmentRow(
  db: Db,
  data: AttachmentRowInput,
): Promise<AttachmentRow> {
  if (data.type === 'file') {
    return fileAsAttachment(await db.noteFile.create({ data: fileData(data) }));
  }
  return db.noteAttachment.create({ data: { ...data, type: data.type } });
}

export async function createAttachmentRows(
  db: Db,
  rows: AttachmentRowInput[],
): Promise<void> {
  const files = rows.filter((row) => row.type === 'file').map(fileData);
  const others = rows.flatMap((row) =>
    row.type === 'file' ? [] : [{ ...row, type: row.type }],
  );
  if (others.length > 0) await db.noteAttachment.createMany({ data: others });
  if (files.length > 0) await db.noteFile.createMany({ data: files });
}

export async function deleteAttachmentRow(
  db: Db,
  row: AttachmentRow,
): Promise<void> {
  if (row.type === 'file') {
    await db.noteFile.delete({ where: { id: row.id } });
  } else {
    await db.noteAttachment.delete({ where: { id: row.id } });
  }
}

export async function setAttachmentPosition(
  db: Db,
  row: AttachmentRow,
  position: number,
): Promise<void> {
  if (row.type === 'file') {
    await db.noteFile.update({ where: { id: row.id }, data: { position } });
  } else {
    await db.noteAttachment.update({
      where: { id: row.id },
      data: { position },
    });
  }
}

/** Moves every attachment of a note one place down, to make room first. */
export async function shiftAttachmentRows(
  db: Db,
  noteId: string,
): Promise<void> {
  const data = { position: { increment: 1 } };
  await db.noteAttachment.updateMany({ where: { noteId }, data });
  await db.noteFile.updateMany({ where: { noteId }, data });
}
