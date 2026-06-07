import type { Request } from 'express';
import type { AuthUser } from './token-resolver.service';

/**
 * Express request with the authenticated user attached by AuthGuard.
 */
export interface AuthenticatedRequest extends Request {
  user?: AuthUser;
}
