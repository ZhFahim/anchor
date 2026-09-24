import { AsyncLocalStorage } from 'async_hooks';
import type { AuthMethod } from '../auth/token-resolver.service';

export interface McpUserContext {
  userId: string;
  authMethod: AuthMethod;
  scope: 'readOnly' | 'readWrite';
}

export const mcpAuthStorage = new AsyncLocalStorage<McpUserContext>();

/** Reads the authenticated user for the current tool invocation. */
export const getMcpUser = (): McpUserContext | undefined =>
  mcpAuthStorage.getStore();
