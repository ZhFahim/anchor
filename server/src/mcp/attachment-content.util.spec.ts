import { describe, expect, it } from 'vitest';
import sharp from 'sharp';
import { AttachmentType } from 'src/generated/prisma/enums';
import { attachmentContent } from './attachment-content.util';

const URI = 'anchor://notes/n/attachments/a';

describe('attachmentContent', () => {
  it('scales a large picture down to fit', async () => {
    const photo = await sharp({
      create: { width: 4000, height: 3000, channels: 3, background: 'red' },
    })
      .png()
      .toBuffer();

    const content = await attachmentContent(
      AttachmentType.image,
      'image/png',
      photo,
      URI,
    );

    expect(content).toMatchObject({ type: 'image', mimeType: 'image/jpeg' });
    const data = Buffer.from((content as { data: string }).data, 'base64');
    const { width, height } = await sharp(data).metadata();
    expect([width, height]).toEqual([1568, 1176]);
  });

  it('keeps see-through parts of a picture it scales', async () => {
    const logo = await sharp({
      create: {
        width: 2000,
        height: 2000,
        channels: 4,
        background: { r: 0, g: 0, b: 0, alpha: 0 },
      },
    })
      .png()
      .toBuffer();

    const content = await attachmentContent(
      AttachmentType.image,
      'image/png',
      logo,
      URI,
    );

    expect(content).toMatchObject({ type: 'image', mimeType: 'image/png' });
  });

  it('sends a file that is not text as bytes', async () => {
    const content = await attachmentContent(
      'file',
      'application/pdf',
      Buffer.from([0xff, 0xfe, 0x00]),
      URI,
    );

    expect(content).toEqual({
      type: 'resource',
      resource: { uri: URI, mimeType: 'application/pdf', blob: '//4A' },
    });
  });
});
