import {
  CanActivate,
  ExecutionContext,
  HttpException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import { ANCHOR_PROTOCOL, SUPPORTED_PROTOCOLS } from './protocol.constants';
import { SKIP_PROTOCOL_GATE } from './skip-protocol-gate.decorator';

export const ANCHOR_PROTOCOL_HEADER = 'x-anchor-protocol';

// Nest's HttpStatus enum has no 426.
const UPGRADE_REQUIRED = 426;

type ProtocolErrorCode = 'APP_OUTDATED' | 'SERVER_OUTDATED';

@Injectable()
export class ProtocolGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    if (context.getType() !== 'http') return true;

    const skipped = this.reflector.getAllAndOverride<boolean>(
      SKIP_PROTOCOL_GATE,
      [context.getHandler(), context.getClass()],
    );
    if (skipped) return true;

    const request = context.switchToHttp().getRequest<Request>();
    const header = request.headers[ANCHOR_PROTOCOL_HEADER];

    // The bundled web client and third-party clients send none.
    if (header === undefined) return true;

    const protocol = Number(Array.isArray(header) ? header[0] : header);
    if (Number.isInteger(protocol) && SUPPORTED_PROTOCOLS.includes(protocol)) {
      return true;
    }

    throw protocol > ANCHOR_PROTOCOL
      ? refuse(
          'SERVER_OUTDATED',
          'Your Anchor server is too old to sync with this app. ' +
            'Update the server to continue.',
        )
      : refuse(
          'APP_OUTDATED',
          'This app is too old to sync with your Anchor server. ' +
            'Update the app to continue.',
        );
  }
}

function refuse(code: ProtocolErrorCode, message: string): HttpException {
  return new HttpException(
    { code, message, protocols: SUPPORTED_PROTOCOLS },
    UPGRADE_REQUIRED,
  );
}
