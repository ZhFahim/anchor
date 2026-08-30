/** Line view over Quill Delta ops. Mirrors web/features/notes/quill-lines.ts. */

export type QuillOp = {
  insert?: unknown;
  attributes?: Record<string, unknown>;
};

export type DeltaLine = {
  /** Text ops before the newline */
  contentOps: QuillOp[];
  /** The newline op, carrying block attributes like list or header */
  newlineOp: QuillOp;
};

/** Ops of a stored note, or null when the content isn't canonical Delta JSON. */
export function parseDeltaOps(content: string | null): QuillOp[] | null {
  if (!content) return null;
  try {
    const parsed: unknown = JSON.parse(content);
    if (
      parsed &&
      typeof parsed === 'object' &&
      'ops' in parsed &&
      Array.isArray(parsed.ops)
    ) {
      return (parsed as { ops: QuillOp[] }).ops;
    }
  } catch {
    return null;
  }
  return null;
}

export function deltaToLines(ops: QuillOp[]): DeltaLine[] {
  const lines: DeltaLine[] = [];
  let contentOps: QuillOp[] = [];

  for (const op of ops) {
    if (typeof op.insert === 'string' && op.insert.includes('\n')) {
      const parts = op.insert.split('\n');
      for (let i = 0; i < parts.length; i++) {
        if (parts[i]) {
          contentOps.push({
            insert: parts[i],
            ...(op.attributes ? { attributes: op.attributes } : {}),
          });
        }
        if (i < parts.length - 1) {
          lines.push({
            contentOps,
            newlineOp: {
              insert: '\n',
              ...(op.attributes ? { attributes: op.attributes } : {}),
            },
          });
          contentOps = [];
        }
      }
    } else {
      contentOps.push(op);
    }
  }

  // Trailing content without a closing newline
  if (contentOps.length > 0) {
    lines.push({ contentOps, newlineOp: { insert: '\n' } });
  }

  return lines;
}

export function getLineText(line: DeltaLine): string {
  return line.contentOps
    .map((op) => (typeof op.insert === 'string' ? op.insert : ''))
    .join('');
}

export function indentOf(line: DeltaLine): number {
  const value = line.newlineOp.attributes?.indent;
  return typeof value === 'number' ? value : 0;
}
