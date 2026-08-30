export const MAX_FILENAME_STEM_LENGTH = 100;

// eslint-disable-next-line no-control-regex
const ILLEGAL = /[\\/:*?"<>|\x00-\x1f\x7f]/g;
const WINDOWS_RESERVED = /^(con|prn|aux|nul|com[1-9]|lpt[1-9])$/i;

/** Turns a note title into a filename stem that survives every filesystem. */
export function sanitizeFilenameStem(title: string): string {
  let stem = title.normalize('NFC').replace(ILLEGAL, ' ');
  stem = stem.replace(/\s+/g, ' ').trim();
  stem = stem.replace(/^\.+/, '').replace(/[. ]+$/, '');

  // Cap by code point so surrogate pairs don't get cut in half
  const chars = Array.from(stem);
  if (chars.length > MAX_FILENAME_STEM_LENGTH) {
    stem = chars.slice(0, MAX_FILENAME_STEM_LENGTH).join('').trimEnd();
    stem = stem.replace(/[. ]+$/, '');
  }

  if (!stem) return 'Untitled';
  if (WINDOWS_RESERVED.test(stem)) return `${stem} note`;
  return stem;
}

/** Hands out unique names per directory, compared case-insensitively. */
export class FilenameAllocator {
  private readonly used = new Map<string, Set<string>>();

  allocate(dir: string, stem: string): string {
    let taken = this.used.get(dir);
    if (!taken) {
      taken = new Set<string>();
      this.used.set(dir, taken);
    }

    let candidate = stem;
    let counter = 2;
    while (taken.has(candidate.toLowerCase())) {
      candidate = `${stem} (${counter++})`;
    }
    taken.add(candidate.toLowerCase());
    return candidate;
  }
}

/** Percent-encodes the characters that would break a markdown link target. */
export function encodeRelativePath(path: string): string {
  return path
    .split('/')
    .map((segment) =>
      segment.replace(
        /[ ()<>#?%[\]]/g,
        (char) =>
          `%${char.charCodeAt(0).toString(16).toUpperCase().padStart(2, '0')}`,
      ),
    )
    .join('/');
}
