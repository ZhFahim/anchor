import type { KeepNote } from "../keep-mapping";

/**
 * Minimal Google Keep Takeout note fixtures, shaped like the .json files
 * found under Takeout/Keep/. Tests assemble these into an in-memory zip.
 */

export const keepTextNote: KeepNote = {
  title: "Shopping thoughts",
  textContent: "Buy milk\nAnd maybe bread",
  isTrashed: false,
  isPinned: true,
  isArchived: false,
  color: "TEAL",
  createdTimestampUsec: 1700000000000000,
  userEditedTimestampUsec: 1700000400123456,
};

export const keepChecklistNote: KeepNote = {
  title: "Packing list",
  listContent: [
    { text: "Passport", isChecked: true },
    { text: "Charger", isChecked: false },
  ],
  isTrashed: false,
  isPinned: false,
  isArchived: true,
  color: "DEFAULT",
  createdTimestampUsec: 1690000000000000,
  userEditedTimestampUsec: 1690000300000000,
};

export const keepLabeledNote: KeepNote = {
  title: "Project ideas",
  textContent: "Build a birdhouse",
  isTrashed: false,
  isPinned: false,
  isArchived: false,
  labels: [{ name: "Projects" }, { name: "Weekend" }],
  color: "CERULEAN",
  createdTimestampUsec: 1680000000000000,
  userEditedTimestampUsec: 1680000200000000,
  annotations: [{ url: "https://example.com/plans" }],
};

export const keepTrashedNote: KeepNote = {
  title: "Old junk",
  textContent: "Delete me",
  isTrashed: true,
  isPinned: false,
  isArchived: false,
  userEditedTimestampUsec: 1670000000000000,
};

export const keepNoteWithMedia: KeepNote = {
  title: "Receipt",
  textContent: "Keep this for taxes",
  isTrashed: false,
  isPinned: false,
  isArchived: false,
  userEditedTimestampUsec: 1660000000000000,
  attachments: [
    // Referenced as .jpeg but stored as .jpg — a real Takeout quirk
    { filePath: "receipt.jpeg", mimetype: "image/jpeg" },
    { filePath: "voice-memo.3gp", mimetype: "audio/3gpp" },
  ],
};
