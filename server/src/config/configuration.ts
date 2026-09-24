import { registerAs } from '@nestjs/config';
import * as path from 'path';

export const DEFAULT_DATA_DIR = '/data';
const DEFAULT_APP_URL = 'http://localhost:3000';
const DEFAULT_PORT = 3001;

export const AppConfig = registerAs('app', () => ({
  nodeEnv: process.env.NODE_ENV ?? 'development',
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

export const McpConfig = registerAs('mcp', () => ({
  enabled: process.env.MCP_ENABLED === 'true',
  publicUrl: process.env.MCP_PUBLIC_URL?.trim() || undefined,
}));

export const configurations = [
  AppConfig,
  DatabaseConfig,
  AuthConfig,
  StorageConfig,
  McpConfig,
];
