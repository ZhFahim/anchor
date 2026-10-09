import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { setupApp } from './app.setup';
import { AppConfig, StorageConfig } from './config/configuration';

describe('setupApp', () => {
  let app: NestExpressApplication;
  let root: string;

  beforeAll(async () => {
    root = fs.mkdtempSync(path.join(os.tmpdir(), 'anchor-setup-'));
    const profilesDir = path.join(root, 'profiles');
    fs.mkdirSync(profilesDir);
    fs.writeFileSync(path.join(profilesDir, 'u1-1700000000000.png'), 'png');

    const moduleRef = await Test.createTestingModule({
      providers: [
        { provide: AppConfig.KEY, useValue: { corsOrigins: [] } },
        {
          provide: StorageConfig.KEY,
          useValue: {
            profilesDir,
            attachmentsDir: path.join(root, 'attachments'),
          },
        },
      ],
    }).compile();
    app = moduleRef.createNestApplication<NestExpressApplication>({
      logger: false,
    });
    setupApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
    fs.rmSync(root, { recursive: true, force: true });
  });

  it('lets browsers keep profile images but not shared caches', async () => {
    const res = await request(app.getHttpServer())
      .get('/uploads/profiles/u1-1700000000000.png')
      .expect(200);

    expect(res.headers['cache-control']).toBe(
      'private, max-age=31536000, immutable',
    );
  });
});
