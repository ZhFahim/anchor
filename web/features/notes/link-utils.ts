import {
  insertedBeforeCaret,
  type QuillDelta,
  type QuillInstance,
} from "./quill";

const SCHEMES = [
  "http://",
  "https://",
  "mailto:",
  "tel:",
  "sms:",
  "ftp://",
  "ftps://",
  "file://",
  "geo:",
];

export const LINK_PROTOCOLS = SCHEMES.map((scheme) =>
  scheme.replace(/:\/*$/, ""),
);

const HOST_LIKE = /^(?:[\w-]+(?:\.[\w-]+)+|localhost)(?::\d+)?(?:[/?#].*)?$/i;
const IPV4_HOST = /^(?:\d{1,3}\.){3}\d{1,3}$/;

// Dotted-but-all-numeric strings like "3.14" or "192.168" are prose, not
// hosts; only a full dotted quad counts as a numeric host.
function isHostLike(trimmed: string): boolean {
  if (!HOST_LIKE.test(trimmed)) return false;
  const host = trimmed.split(/[/?#:]/, 1)[0];
  return /[a-z]/i.test(host) || IPV4_HOST.test(host);
}

export function normalizeUrl(raw: string): string {
  const trimmed = raw.trim();
  if (!trimmed) return trimmed;
  const lower = trimmed.toLowerCase();
  for (const scheme of SCHEMES) {
    if (lower.startsWith(scheme)) return trimmed;
  }
  if (isHostLike(trimmed)) return `https://${trimmed}`;
  return trimmed;
}

/** "visitlisboa.com/en/sights" from "https://www.visitlisboa.com/en/sights/?q=1". */
export function siteAndPath(url: string): string {
  const address = normalizeUrl(url);
  try {
    const { host, pathname } = new URL(address);
    let path = pathname.replace(/\/+$/, "");
    try {
      path = decodeURI(path);
    } catch {}
    return host.replace(/^www\./, "") + path || address;
  } catch {
    return address;
  }
}

export function isLikelyUrl(raw: string): boolean {
  const trimmed = raw.trim();
  if (!trimmed || /\s/.test(trimmed)) return false;
  const lower = trimmed.toLowerCase();
  for (const scheme of SCHEMES) {
    if (lower.startsWith(scheme)) return true;
  }
  return isHostLike(trimmed);
}

/** A URL written with its scheme, or starting with "www.". */
export function isFullUrl(raw: string): boolean {
  const trimmed = raw.trim();
  if (!trimmed || /\s/.test(trimmed)) return false;
  const lower = trimmed.toLowerCase();
  if (SCHEMES.some((scheme) => lower.startsWith(scheme))) return true;
  return lower.startsWith("www.") && isHostLike(trimmed);
}

const EMAIL = /^[\w.+-]+@[\w-]+(?:\.[\w-]+)*\.[a-z]{2,}$/i;

export function typedAddressLink(word: string): string | null {
  if (/^[a-z]+:\/*$/i.test(word)) return null;
  if (isFullUrl(word)) return normalizeUrl(word);
  return EMAIL.test(word) ? `mailto:${word}` : null;
}

function lastWord(text: string): { start: number; word: string } | null {
  const match = /\S+$/.exec(text);
  if (!match) return null;
  let word = match[0];
  let start = match.index;
  const lead = /^[("'<[{]*/.exec(word)?.[0].length ?? 0;
  word = word.slice(lead);
  start += lead;
  word = word.replace(/[.,;:!?'">\]}]+$/, "");
  while (word.endsWith(")") && word.split(")").length > word.split("(").length)
    word = word.slice(0, -1);
  return word ? { start, word } : null;
}

export function linkTypedAddress(quill: QuillInstance, change: QuillDelta) {
  const inserted = insertedBeforeCaret(quill, change);
  if (!inserted || !/^[  \n]$/.test(inserted.text)) return;
  const end = inserted.from;
  const [line, offset] = quill.getLine(end);
  if (!line || line.formats()["code-block"]) return;
  const lineStart = end - offset;
  const found = lastWord(quill.getText(lineStart, offset));
  if (!found) return;
  const url = typedAddressLink(found.word);
  if (!url) return;
  const start = lineStart + found.start;
  const isLinked = quill
    .getContents(start, found.word.length)
    .ops.some((op) => op.attributes?.link);
  if (isLinked) return;
  quill.history.cutoff();
  quill.formatText(start, found.word.length, "link", url, "user");
  quill.history.cutoff();
}

export type LinkRange = {
  url: string;
  text: string;
  start: number;
  length: number;
};

export function linkAtIndex(
  quill: QuillInstance,
  index: number,
): LinkRange | null {
  if (index < 0) return null;
  const ops = quill.getContents().ops ?? [];
  let pos = 0;
  let hitIndex = -1;
  let hitUrl: string | null = null;
  let hitText = "";

  for (let i = 0; i < ops.length; i++) {
    const data = ops[i].insert;
    if (typeof data !== "string") {
      pos += 1;
      continue;
    }
    if (index >= pos && index <= pos + data.length) {
      const url =
        typeof ops[i].attributes?.link === "string"
          ? (ops[i].attributes?.link as string)
          : null;
      if (url) {
        hitIndex = i;
        hitUrl = url;
        hitText = data;
        break;
      }
      if (index < pos + data.length) return null;
    }
    pos += data.length;
  }

  if (hitIndex < 0 || !hitUrl) return null;

  let start = pos;
  let text = hitText;
  for (let i = hitIndex - 1; i >= 0; i--) {
    const data = ops[i].insert;
    if (typeof data !== "string") break;
    if (ops[i].attributes?.link !== hitUrl) break;
    text = data + text;
    start -= data.length;
  }
  for (let i = hitIndex + 1; i < ops.length; i++) {
    const data = ops[i].insert;
    if (typeof data !== "string") break;
    if (ops[i].attributes?.link !== hitUrl) break;
    text += data;
  }

  return { url: hitUrl, text, start, length: text.length };
}
