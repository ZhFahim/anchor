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
  "audio/ogg",
  "audio/x-m4a",
] as const;

export const ACCEPTED_ATTACHMENT_TYPES = [
  ...ACCEPTED_IMAGE_TYPES,
  ...ACCEPTED_AUDIO_TYPES,
] as const;

/** Comma-separated string for the HTML input accept attribute */
export const ACCEPTED_TYPES_STRING = ACCEPTED_ATTACHMENT_TYPES.join(",");

/** Check if a file is an accepted attachment type */
export function isAcceptedAttachmentType(file: File): boolean {
  const type = file.type;
  return (
    type.startsWith("image/") ||
    type.startsWith("audio/") ||
    type === "audio/x-m4a"
  );
}
