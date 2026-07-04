import type { QuillDelta, QuillOp } from "@/features/notes/quill";

/**
 * Shape of a Google Keep note in a Takeout export (one .json per note).
 * Only the fields the importer reads are listed.
 */
export type KeepNote = {
  title?: string;
  textContent?: string;
  listContent?: { text: string; isChecked: boolean }[];
  isTrashed?: boolean;
  isPinned?: boolean;
  isArchived?: boolean;
  labels?: { name: string }[];
  color?: string;
  createdTimestampUsec?: number;
  userEditedTimestampUsec?: number;
  attachments?: { filePath: string; mimetype: string }[];
  annotations?: { url?: string; title?: string }[];
};

// Keep color names -> Anchor background ids. DEFAULT and GRAY have no
// Anchor equivalent and fall back to no background.
export const KEEP_COLOR_TO_BACKGROUND: Record<string, string | null> = {
  DEFAULT: null,
  RED: "color_red",
  ORANGE: "color_orange",
  YELLOW: "color_yellow",
  GREEN: "color_green",
  TEAL: "color_teal",
  BLUE: "color_blue",
  CERULEAN: "color_dark_blue",
  PURPLE: "color_purple",
  PINK: "color_pink",
  BROWN: "color_brown",
  GRAY: null,
};

export function keepColorToBackground(
  color: string | undefined,
): string | null {
  if (!color) return null;
  return KEEP_COLOR_TO_BACKGROUND[color] ?? null;
}

export function keepTimestampToIso(
  usec: number | undefined,
): string | undefined {
  if (!usec || usec <= 0) return undefined;
  return new Date(Math.floor(usec / 1000)).toISOString();
}

/**
 * Build a Quill Delta from a Keep note's content. Text notes become plain
 * lines; checklists become Quill checked/unchecked list lines; annotation
 * URLs are appended as linked lines.
 */
export function keepContentToDelta(note: KeepNote): QuillDelta {
  const ops: QuillOp[] = [];

  if (note.listContent?.length) {
    for (const item of note.listContent) {
      if (item.text) {
        ops.push({ insert: item.text });
      }
      ops.push({
        insert: "\n",
        attributes: { list: item.isChecked ? "checked" : "unchecked" },
      });
    }
  } else if (note.textContent) {
    ops.push({
      insert: note.textContent.endsWith("\n")
        ? note.textContent
        : `${note.textContent}\n`,
    });
  }

  const urls = (note.annotations ?? [])
    .map((annotation) => annotation.url)
    .filter((url): url is string => Boolean(url));
  if (urls.length) {
    if (ops.length) {
      ops.push({ insert: "\n" });
    }
    for (const url of urls) {
      ops.push({ insert: url, attributes: { link: url } });
      ops.push({ insert: "\n" });
    }
  }

  if (!ops.length) {
    ops.push({ insert: "\n" });
  }

  return { ops };
}

/** Strips directories and returns the lowercase basename. */
const basename = (path: string) => {
  const name = path.split("/").pop() ?? path;
  return name.toLowerCase();
};

/** Basename without its extension. */
const stem = (path: string) => basename(path).replace(/\.[^.]+$/, "");

/**
 * Resolve a Keep attachment reference against the actual zip entries.
 * Keep manifests sometimes reference ".jpeg" while the stored file is
 * ".jpg" (or vice versa), so fall back from exact basename to same-stem
 * matching.
 */
export function resolveKeepMediaPath(
  filePath: string,
  mediaPaths: string[],
): string | undefined {
  const wanted = basename(filePath);
  const exact = mediaPaths.find((path) => basename(path) === wanted);
  if (exact) return exact;

  const wantedStem = stem(filePath);
  return mediaPaths.find((path) => stem(path) === wantedStem);
}
