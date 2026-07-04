import type { QuillInstance } from "./quill";

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

export function isLikelyUrl(raw: string): boolean {
  const trimmed = raw.trim();
  if (!trimmed || /\s/.test(trimmed)) return false;
  const lower = trimmed.toLowerCase();
  for (const scheme of SCHEMES) {
    if (lower.startsWith(scheme)) return true;
  }
  return isHostLike(trimmed);
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
