import type { CallToolResult } from '@modelcontextprotocol/sdk/types.js';
import { AttachmentType } from 'src/generated/prisma/enums';
import type { AttachmentKind } from '../notes/utils/attachment-storage.util';

type Content = CallToolResult['content'][number];

// What Claude takes in a picture: past these it would scale it down anyway,
// or refuse it.
const PICTURE_MAX_SIDE = 1568;
const PICTURE_MAX_BYTES = 3.75 * 1024 * 1024;
const PICTURE_SENT_AS_IS = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
]);

/** Recordings and files are sent whole, so only ones this small. */
export const ATTACHMENT_MAX_SENT_BYTES = 10 * 1024 * 1024;

/** The MCP content for an attachment's bytes. */
export async function attachmentContent(
  type: AttachmentKind,
  mimeType: string,
  data: Buffer,
  uri: string,
): Promise<Content> {
  if (type === AttachmentType.image) {
    return { type: 'image', ...(await picture(mimeType, data)) };
  }
  if (type === AttachmentType.audio) {
    return { type: 'audio', mimeType, data: data.toString('base64') };
  }
  if (isText(mimeType) && isUtf8(data)) {
    return {
      type: 'resource',
      resource: { uri, mimeType, text: data.toString('utf8') },
    };
  }
  return {
    type: 'resource',
    resource: { uri, mimeType, blob: data.toString('base64') },
  };
}

/**
 * A picture as Claude can take it: as it is when it already fits, otherwise
 * upright and scaled down to fit, as a PNG when it has see-through parts and
 * a JPEG when it doesn't.
 */
async function picture(
  mimeType: string,
  data: Buffer,
): Promise<{ mimeType: string; data: string }> {
  const sharp = (await import('sharp')).default;
  const image = sharp(data, { animated: false });
  const {
    width = 0,
    height = 0,
    orientation,
    hasAlpha,
  } = await image.metadata();
  const fits =
    PICTURE_SENT_AS_IS.has(mimeType) &&
    data.length <= PICTURE_MAX_BYTES &&
    Math.max(width, height) <= PICTURE_MAX_SIDE &&
    (orientation ?? 1) === 1;
  if (fits) return { mimeType, data: data.toString('base64') };

  const scaled = image.rotate().resize(PICTURE_MAX_SIDE, PICTURE_MAX_SIDE, {
    fit: 'inside',
    withoutEnlargement: true,
  });
  const out = hasAlpha
    ? { mimeType: 'image/png', data: await scaled.png().toBuffer() }
    : { mimeType: 'image/jpeg', data: await scaled.jpeg().toBuffer() };
  return { mimeType: out.mimeType, data: out.data.toString('base64') };
}

function isText(mimeType: string): boolean {
  return (
    mimeType.startsWith('text/') ||
    ['application/json', 'application/xml', 'application/csv'].includes(
      mimeType,
    )
  );
}

function isUtf8(data: Buffer): boolean {
  try {
    new TextDecoder('utf-8', { fatal: true }).decode(data);
    return true;
  } catch {
    return false;
  }
}
