/** MIME types accepted for note attachments */
export const ACCEPTED_IMAGE_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
] as const;

export const ACCEPTED_AUDIO_TYPES = [
  "audio/mpeg",
  "audio/wav",
  "audio/mp4",
  "audio/x-m4a",
  "audio/ogg",
  "audio/aac",
  "audio/webm",
] as const;

export const ACCEPTED_ATTACHMENT_TYPES = [
  ...ACCEPTED_IMAGE_TYPES,
  ...ACCEPTED_AUDIO_TYPES,
] as const;

/** Comma-separated string for the HTML input accept attribute */
export const ACCEPTED_TYPES_STRING = ACCEPTED_ATTACHMENT_TYPES.join(",");

const ACCEPTED_MIME_SET = new Set<string>(ACCEPTED_ATTACHMENT_TYPES);

/** Check if a file's MIME type is in the server's allowlist */
export function isAcceptedAttachmentType(file: File): boolean {
  return ACCEPTED_MIME_SET.has(file.type);
}
