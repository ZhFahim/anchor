const ACCEPTED_IMAGE_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
] as const;

const ACCEPTED_AUDIO_TYPES = [
  "audio/mpeg",
  "audio/wav",
  "audio/mp4",
  "audio/x-m4a",
  "audio/ogg",
  "audio/aac",
  "audio/webm",
] as const;

const ACCEPTED_ATTACHMENT_TYPES = [
  ...ACCEPTED_IMAGE_TYPES,
  ...ACCEPTED_AUDIO_TYPES,
] as const;

export const MAX_ATTACHMENT_SIZE = 50 * 1024 * 1024;

export const ACCEPTED_TYPES_STRING = ACCEPTED_ATTACHMENT_TYPES.join(",");

const ACCEPTED_MIME_SET = new Set<string>(ACCEPTED_ATTACHMENT_TYPES);

export function isAcceptedAttachmentType(file: File): boolean {
  return ACCEPTED_MIME_SET.has(file.type);
}
