import { bodyOf, HttpClient } from '../http';
import type { TagOnWire } from '../wire';

export class TagsApi {
  constructor(private readonly http: HttpClient) {}

  async create(body: Record<string, unknown> = {}): Promise<TagOnWire> {
    const res = await this.http
      .post('/api/tags')
      .send({ name: 'tag', ...body })
      .expect(201);
    return bodyOf<TagOnWire>(res);
  }

  async update(id: string, body: Record<string, unknown>): Promise<TagOnWire> {
    const res = await this.http.patch(`/api/tags/${id}`).send(body).expect(200);
    return bodyOf<TagOnWire>(res);
  }

  async remove(id: string): Promise<void> {
    await this.http.delete(`/api/tags/${id}`).expect(200);
  }

  async list(): Promise<TagOnWire[]> {
    const res = await this.http.get('/api/tags').expect(200);
    return bodyOf<TagOnWire[]>(res);
  }

  async setPositions(
    positions: { id: string; position: string | null }[],
  ): Promise<{ updated: string[] }> {
    const res = await this.http
      .put('/api/tags/positions')
      .send({ positions })
      .expect(200);
    return bodyOf<{ updated: string[] }>(res);
  }
}
