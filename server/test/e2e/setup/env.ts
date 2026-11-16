import { inject } from 'vitest';

// ConfigModule.forRoot validates process.env when AppModule is imported, so
// the environment must be complete before any spec file's imports run.
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET ??= 'anchor-e2e-jwt-secret-0123456789';
// Fixed, so specs can exercise the two-factor paths.
process.env.TOTP_ENCRYPTION_KEY ??=
  'MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=';
process.env.DATABASE_URL = inject('databaseUrl');
process.env.DATA_DIR = inject('dataDir');
process.env.CORS_ORIGINS = 'https://web.e2e.test';
