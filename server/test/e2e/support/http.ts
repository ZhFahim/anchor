import request from 'supertest';

export type TestServer = Parameters<typeof request>[0];

/** Every request one user makes, already authenticated. */
export class HttpClient {
  constructor(
    private readonly server: TestServer,
    private readonly token: string,
  ) {}

  get headers(): { Authorization: string } {
    return { Authorization: `Bearer ${this.token}` };
  }

  get(path: string) {
    return request(this.server).get(path).set(this.headers);
  }

  post(path: string) {
    return request(this.server).post(path).set(this.headers);
  }

  patch(path: string) {
    return request(this.server).patch(path).set(this.headers);
  }

  put(path: string) {
    return request(this.server).put(path).set(this.headers);
  }

  delete(path: string) {
    return request(this.server).delete(path).set(this.headers);
  }
}

export const bodyOf = <T>(res: { body: unknown }): T => res.body as T;
