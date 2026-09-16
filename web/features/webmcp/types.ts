/**
 * Minimal TypeScript declarations for the WebMCP `document.modelContext` API.
 *
 * Per the W3C WebMCP spec (and Chrome 150 deprecation of `navigator.modelContext`):
 *   - `navigator.modelContext` is deprecated -> use `document.modelContext`.
 *   - Tools are document-scoped: `registerTool({ name, description, inputSchema,
 *     execute, annotations }, { signal })`.
 *   - `inputSchema` is JSON Schema 2020-12; `execute(inputObject, { signal })`
 *     returns a Promise whose resolved value is JSON-stringified to the caller.
 *
 * These are minimal structural types for the subset we use; if you need full
 * types, add the `webmcp-types` package to tsconfig `types`.
 */

export interface ModelContextToolAnnotations {
  readOnlyHint?: boolean;
  untrustedContentHint?: boolean;
  consequentialHint?: boolean;
}

export interface ModelContextTool {
  name: string;
  title?: string;
  description: string;
  inputSchema: Record<string, unknown>;
  annotations?: ModelContextToolAnnotations;
  execute(
    inputObject: Record<string, unknown>,
    options: { signal: AbortSignal },
  ): Promise<unknown>;
}

export interface ModelContextRegisterToolOptions {
  signal?: AbortSignal;
}

export interface ModelContext {
  registerTool(
    tool: ModelContextTool,
    options?: ModelContextRegisterToolOptions,
  ): Promise<void>;
}

// document-scoped (current); navigator-scoped alias is deprecated in Chrome 150.
declare global {
  interface Document {
    modelContext?: ModelContext;
  }
  interface Navigator {
    modelContext?: ModelContext;
  }
}
