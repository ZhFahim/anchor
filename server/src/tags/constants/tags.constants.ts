import { NoteState } from 'src/generated/prisma/enums';

export const TAG_INCLUDE_NOTE_COUNT = {
  _count: { select: { notes: { where: { state: NoteState.active } } } },
} as const;

export const ERROR_MESSAGES = {
  TAG_NOT_FOUND: 'Tag not found',
  TAG_NAME_EXISTS: 'A tag with this name already exists',
  TAG_CHANGED: 'Tag was changed by someone else',
} as const;
