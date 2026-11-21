import type { HttpException } from '@nestjs/common';
import type { ErrorCode } from './error-code';

export type ErrorParams = Record<string, string | number>;

/** Adds a stable code, and the values in the message, to an exception's body. */
export function coded<T extends HttpException>(
  exception: T,
  code: ErrorCode,
  params?: ErrorParams,
): T {
  const body = exception.getResponse();
  if (typeof body === 'object' && body !== null) {
    Object.assign(body, { code, ...(params ? { params } : {}) });
  }
  return exception;
}
