import { bodyOf, HttpClient } from '../http';
import type { ImportResultOnWire, NoteOnWire } from '../wire';

export class NotesApi {
  constructor(private readonly http: HttpClient) {}

  async create(body: Record<string, unknown> = {}): Promise<NoteOnWire> {
    const res = await this.http
      .post('/api/notes')
      .send({ title: 'note', ...body })
      .expect(201);
    return bodyOf<NoteOnWire>(res);
  }

  async read(id: string): Promise<NoteOnWire> {
    return bodyOf<NoteOnWire>(
      await this.http.get(`/api/notes/${id}`).expect(200),
    );
  }

  async list(query = ''): Promise<NoteOnWire[]> {
    const res = await this.http.get(`/api/notes${query}`).expect(200);
    return bodyOf<NoteOnWire[]>(res);
  }

  async update(id: string, body: Record<string, unknown>): Promise<NoteOnWire> {
    const res = await this.http
      .patch(`/api/notes/${id}`)
      .send(body)
      .expect(200);
    return bodyOf<NoteOnWire>(res);
  }

  async trash(id: string): Promise<void> {
    await this.http.delete(`/api/notes/${id}`).expect(200);
  }

  async restore(id: string): Promise<NoteOnWire> {
    const res = await this.http.patch(`/api/notes/${id}/restore`).expect(200);
    return bodyOf<NoteOnWire>(res);
  }

  async purge(id: string): Promise<void> {
    await this.http.delete(`/api/notes/${id}/permanent`).expect(200);
  }

  async listTrashed(): Promise<NoteOnWire[]> {
    const res = await this.http.get('/api/notes/trash').expect(200);
    return bodyOf<NoteOnWire[]>(res);
  }

  async listArchived(): Promise<NoteOnWire[]> {
    const res = await this.http.get('/api/notes/archive').expect(200);
    return bodyOf<NoteOnWire[]>(res);
  }

  async bulkTrash(noteIds: string[]): Promise<{ count: number }> {
    const res = await this.http
      .post('/api/notes/bulk/delete')
      .send({ noteIds })
      .expect(201);
    return bodyOf<{ count: number }>(res);
  }

  async bulkArchive(noteIds: string[]): Promise<{ count: number }> {
    const res = await this.http
      .post('/api/notes/bulk/archive')
      .send({ noteIds })
      .expect(201);
    return bodyOf<{ count: number }>(res);
  }

  async bulkPin(
    noteIds: string[],
    isPinned: boolean,
  ): Promise<{ count: number }> {
    const res = await this.http
      .post('/api/notes/bulk/pin')
      .send({ noteIds, isPinned })
      .expect(201);
    return bodyOf<{ count: number }>(res);
  }

  async import(
    body: Record<string, unknown>,
  ): Promise<{ results: ImportResultOnWire[] }> {
    const res = await this.http
      .post('/api/import/notes')
      .send(body)
      .expect(201);
    return bodyOf<{ results: ImportResultOnWire[] }>(res);
  }

  async setPositions(
    positions: { noteId: string; position: string | null }[],
  ): Promise<{ updated: string[] }> {
    const res = await this.http
      .put('/api/notes/positions')
      .send({ positions })
      .expect(200);
    return bodyOf<{ updated: string[] }>(res);
  }
}
