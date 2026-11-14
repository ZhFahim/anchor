import * as http from 'node:http';
import type { AddressInfo } from 'node:net';

const DEFAULT_WAIT_MS = 5000;

/** An open SSE connection, read as the raw text the server has sent so far. */
export class SyncEventStream {
  constructor(
    private readonly request: http.ClientRequest,
    readonly status: number,
    readonly headers: http.IncomingHttpHeaders,
    private readonly buffer: () => string,
    private readonly hasEnded: () => boolean,
  ) {}

  read(): string {
    return this.buffer();
  }

  async waitFor(needle: string, timeoutMs = DEFAULT_WAIT_MS): Promise<void> {
    const deadline = Date.now() + timeoutMs;
    while (!this.read().includes(needle)) {
      if (Date.now() > deadline) {
        throw new Error(
          `timed out waiting for ${JSON.stringify(needle)}; received: ${this.read()}`,
        );
      }
      await new Promise((resolve) => setTimeout(resolve, 20));
    }
  }

  async waitForEnd(timeoutMs = DEFAULT_WAIT_MS): Promise<void> {
    const deadline = Date.now() + timeoutMs;
    while (!this.hasEnded()) {
      if (Date.now() > deadline) {
        throw new Error('timed out waiting for the stream to end');
      }
      await new Promise((resolve) => setTimeout(resolve, 20));
    }
  }

  close(): void {
    this.request.destroy();
  }
}

export function openSyncEventStream(
  address: AddressInfo,
  token: string,
): Promise<SyncEventStream> {
  return new Promise((resolve, reject) => {
    const req = http.get(
      {
        host: address.address,
        port: address.port,
        path: '/api/sync/events',
        headers: { Authorization: `Bearer ${token}` },
      },
      (res) => {
        let buffer = '';
        let hasEnded = false;
        res.on('close', () => {
          hasEnded = true;
        });
        res.setEncoding('utf8');
        res.on('data', (chunk: string) => {
          buffer += chunk;
        });
        resolve(
          new SyncEventStream(
            req,
            res.statusCode ?? 0,
            res.headers,
            () => buffer,
            () => hasEnded,
          ),
        );
      },
    );
    // Closing the stream surfaces as a socket error.
    req.on('error', () => {});
    req.on('close', reject);
  });
}
