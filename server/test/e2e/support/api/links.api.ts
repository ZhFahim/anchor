import { bodyOf, HttpClient } from '../http';
import type { NoteLinkOnWire } from '../wire';

export class LinksApi {
  constructor(private readonly http: HttpClient) {}

  async get(noteId: string): Promise<NoteLinkOnWire | null> {
    const res = await this.http.get(`/api/notes/${noteId}/link`).expect(200);
    return bodyOf<{ link: NoteLinkOnWire | null }>(res).link;
  }

  async create(noteId: string): Promise<NoteLinkOnWire> {
    const res = await this.http.post(`/api/notes/${noteId}/link`).expect(201);
    return bodyOf<NoteLinkOnWire>(res);
  }

  async remove(noteId: string): Promise<void> {
    await this.http.delete(`/api/notes/${noteId}/link`).expect(200);
  }
}
