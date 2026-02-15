import { HttpException } from '@nestjs/common';

/**
 * Extract user-facing error message from OIDC related errors.
 */
export function getErrorMessage(error: unknown, fallback = 'An unexpected error occurred'): string {
  if (error instanceof HttpException) {
    const response = error.getResponse();
    const msg =
      typeof response === 'string'
        ? response
        : (response as { message?: string | string[] })?.message;
    return Array.isArray(msg) ? msg.join(', ') : (msg ?? error.message) ?? fallback;
  }

  // OAuth/OIDC provider errors
  const oauth = error as {
    error?: string;
    error_description?: string;
    cause?: { error?: string; error_description?: string };
  };
  const oauthMsg =
    oauth?.error_description ||
    oauth?.error ||
    oauth?.cause?.error_description ||
    oauth?.cause?.error;
  if (typeof oauthMsg === 'string' && oauthMsg.trim()) {
    return oauthMsg.trim();
  }

  return error instanceof Error ? error.message : fallback;
}
