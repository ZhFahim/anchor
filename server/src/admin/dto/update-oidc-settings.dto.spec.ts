import { describe, expect, it } from 'vitest';
import { type ArgumentMetadata } from '@nestjs/common';
import { AppValidationPipe } from '../../common/pipes/app-validation.pipe';
import { UpdateOidcSettingsDto } from './update-oidc-settings.dto';

const pipe = new AppValidationPipe();
const body = {
  type: 'body',
  metatype: UpdateOidcSettingsDto,
} as ArgumentMetadata;

const accepts = (issuerUrl: string) =>
  pipe.transform({ issuerUrl }, body).then(
    () => true,
    () => false,
  );

describe('UpdateOidcSettingsDto', () => {
  it.each([
    'https://auth.example.com',
    'http://auth.example.com',
    'http://localhost:1411',
    'http://192.168.1.20:9091',
    'https://example.com/realms/home',
  ])('accepts the issuer URL %s', async (issuerUrl) => {
    expect(await accepts(issuerUrl)).toBe(true);
  });

  it.each(['auth.example.com', 'ftp://auth.example.com', 'not a url'])(
    'refuses the issuer URL %s',
    async (issuerUrl) => {
      expect(await accepts(issuerUrl)).toBe(false);
    },
  );
});
