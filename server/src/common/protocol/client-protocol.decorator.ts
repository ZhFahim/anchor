import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';
import { ANCHOR_PROTOCOL_HEADER } from './protocol.guard';

// The protocol the caller asked for, or undefined when it sent no header.
export const ClientProtocol = createParamDecorator(
  (_data: unknown, context: ExecutionContext): number | undefined => {
    const request = context.switchToHttp().getRequest<Request>();
    const header = request.headers[ANCHOR_PROTOCOL_HEADER];
    if (header === undefined) return undefined;

    const protocol = Number(Array.isArray(header) ? header[0] : header);
    return Number.isInteger(protocol) ? protocol : undefined;
  },
);
