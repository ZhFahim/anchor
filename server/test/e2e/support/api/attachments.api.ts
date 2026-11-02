import { bodyOf, HttpClient } from '../http';
import { PNG_1PX } from '../fixtures';
import type { AttachmentOnWire } from '../wire';

export class AttachmentsApi {
  constructor(private readonly http: HttpClient) {}

  uploadRequest(
    noteId: string,
    filename = 'pixel.png',
    file = PNG_1PX,
    contentType = 'image/png',
  ) {
    return this.http
      .post(`/api/notes/${noteId}/attachments`)
      .attach('file', file, { filename, contentType });
  }

  async upload(
    noteId: string,
    filename?: string,
    file?: typeof PNG_1PX,
    contentType?: string,
  ): Promise<AttachmentOnWire> {
    const res = await this.uploadRequest(
      noteId,
      filename,
      file,
      contentType,
    ).expect(201);
    return bodyOf<AttachmentOnWire>(res);
  }

  async list(noteId: string): Promise<AttachmentOnWire[]> {
    const res = await this.http
      .get(`/api/notes/${noteId}/attachments`)
      .expect(200);
    return bodyOf<AttachmentOnWire[]>(res);
  }
}
