import { describe, expect, it, vi } from 'vitest';
import type { Response } from 'express';
import { HealthController } from './health.controller';
import type { HealthService } from './health.service';
import {
  ANCHOR_PROTOCOL,
  SUPPORTED_PROTOCOLS,
} from '../common/protocol/protocol.constants';

function controller(databaseUp = true) {
  const health = {
    isDatabaseUp: vi.fn().mockResolvedValue(databaseUp),
  } as unknown as HealthService;
  return new HealthController(health);
}

describe('HealthController', () => {
  it('reports the app identity, version and servable protocols', () => {
    const body = controller().check();

    expect(body).toMatchObject({ status: 'ok', app: 'anchor' });
    expect(body.version).toEqual(expect.any(String));
    expect(Date.parse(body.timestamp)).not.toBeNaN();
  });

  it('advertises the protocols clients are gated on', () => {
    expect(controller().check().protocols).toEqual(SUPPORTED_PROTOCOLS);
    expect(SUPPORTED_PROTOCOLS).toContain(ANCHOR_PROTOCOL);
  });

  it('names the image it runs from, when the image says', () => {
    const before = process.env.ANCHOR_IMAGE;
    try {
      delete process.env.ANCHOR_IMAGE;
      expect(controller().check().image).toBeUndefined();
      process.env.ANCHOR_IMAGE = 'ghcr.io/o/anchor:fork-preview';
      expect(controller().check().image).toBe('ghcr.io/o/anchor:fork-preview');
    } finally {
      if (before === undefined) delete process.env.ANCHOR_IMAGE;
      else process.env.ANCHOR_IMAGE = before;
    }
  });

  describe('ready', () => {
    it('is ok while the database answers', async () => {
      const status = vi.fn();
      const res = { status } as unknown as Response;
      await expect(controller(true).ready(res)).resolves.toEqual({
        status: 'ok',
        database: 'ok',
      });
      expect(status).not.toHaveBeenCalled();
    });

    it('answers 503 when the database is down', async () => {
      const status = vi.fn();
      const res = { status } as unknown as Response;
      await expect(controller(false).ready(res)).resolves.toEqual({
        status: 'error',
        database: 'down',
      });
      expect(status).toHaveBeenCalledWith(503);
    });
  });
});
