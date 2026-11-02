import { registerAs } from '@nestjs/config';
import * as path from 'path';

const DEFAULT_DATA_DIR = '/data';
const DEFAULT_APP_URL = 'http://localhost:3000';
const DEFAULT_PORT = 3001;

export const AppConfig = registerAs('app', () => ({
  port: parseInt(process.env.PORT ?? String(DEFAULT_PORT), 10),
  appUrl: (process.env.APP_URL?.trim() || DEFAULT_APP_URL).replace(/\/+$/, ''),
  corsOrigins:
    process.env.CORS_ORIGINS?.split(',')
      .map((origin) => origin.trim())
      .filter(Boolean) ?? [],
}));

export const DatabaseConfig = registerAs('database', () => ({
  url: process.env.DATABASE_URL,
}));

export const AuthConfig = registerAs('auth', () => ({
  jwtSecret: process.env.JWT_SECRET as string,
}));

export const StorageConfig = registerAs('storage', () => {
  const root = process.env.DATA_DIR?.trim() || DEFAULT_DATA_DIR;
  const uploadsDir = path.join(root, 'uploads');
  return {
    root,
    uploadsDir,
    profilesDir: path.join(uploadsDir, 'profiles'),
    attachmentsDir: path.join(uploadsDir, 'attachments'),
  };
});

/**
 * Finding pictures by what they show, for users who turn it on; the model
 * (~380 MB) is downloaded then. PICTURE_SEARCH=off doesn't offer it.
 */
export const PictureSearchConfig = registerAs('pictureSearch', () => ({
  enabled: process.env.PICTURE_SEARCH?.trim().toLowerCase() !== 'off',
  /** Where to download the model from, e.g. a mirror; defaults to Hugging Face. */
  modelUrl: process.env.PICTURE_SEARCH_MODEL_URL?.trim() || undefined,
}));

/** Reading the text in note pictures, for search; PICTURE_TEXT=off stops it. */
export const PictureTextConfig = registerAs('pictureText', () => ({
  enabled: process.env.PICTURE_TEXT?.trim().toLowerCase() !== 'off',
}));

/** A push heartbeat for uptime monitors, e.g. an Uptime Kuma push URL. */
export const MonitoringConfig = registerAs('monitoring', () => ({
  heartbeatUrl: process.env.HEARTBEAT_URL?.trim() || undefined,
  /** Seconds between heartbeats. */
  heartbeatInterval: parseInt(process.env.HEARTBEAT_INTERVAL ?? '60', 10),
}));

export const configurations = [
  AppConfig,
  DatabaseConfig,
  AuthConfig,
  StorageConfig,
  PictureTextConfig,
  PictureSearchConfig,
  MonitoringConfig,
];
