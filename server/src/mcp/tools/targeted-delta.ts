import { BadRequestException } from '@nestjs/common';
import {
  deltaToLines,
  type DeltaLine,
  type QuillOp,
} from '../../import-export/markdown/delta-lines';

/**
 * Targeted Quill-Delta line mutations for MCP `note_edit` (plan P2: the LLM
 * owns intent, the server owns the mutation). The client names a line and an
 * operation; the server performs the transform deterministically and only the
 * targeted line changes — every other op is preserved byte-for-byte.
 *
 * Line numbers are 1-based, matching the human-facing line view.
 */

export type TargetedEdit =
  | { op: 'append_line'; text: string }
  | { op: 'insert_after_line'; line: number; text: string }
  | { op: 'replace_line'; line: number; text: string }
  | { op: 'delete_line'; line: number }
  | { op: 'check_item'; line: number; checked: boolean };

/** Throws when `content` is not canonical Quill Delta (`{"ops":[...]}`). */
export function validateDelta(content: string): void {
  let parsed: unknown;
  try {
    parsed = JSON.parse(content);
  } catch {
    throw new BadRequestException(
      'content must be a Quill Delta JSON string like {"ops":[...]}',
    );
  }
  if (
    !parsed ||
    typeof parsed !== 'object' ||
    !Array.isArray((parsed as { ops?: unknown }).ops)
  ) {
    throw new BadRequestException(
      'content must be a Quill Delta JSON string like {"ops":[...]}',
    );
  }
}

function opsOf(content: string): QuillOp[] {
  validateDelta(content);
  return (JSON.parse(content) as { ops: QuillOp[] }).ops;
}

/** Serialize lines back to a Delta `{ops:[...]}` JSON string. */
function linesToDelta(lines: DeltaLine[]): string {
  const ops: QuillOp[] = [];
  for (const line of lines) {
    ops.push(...line.contentOps);
    ops.push(line.newlineOp);
  }
  return JSON.stringify({ ops });
}

const assertLine = (line: number, count: number): void => {
  if (!Number.isInteger(line) || line < 1 || line > count) {
    throw new BadRequestException(
      `line must be between 1 and ${count} (got ${line})`,
    );
  }
};

/** Apply a targeted edit to Delta JSON, returning new Delta JSON. */
export function applyTargetedEdit(content: string, edit: TargetedEdit): string {
  const lines = deltaToLines(opsOf(content));

  switch (edit.op) {
    case 'append_line':
      lines.push({
        contentOps: edit.text ? [{ insert: edit.text }] : [],
        newlineOp: { insert: '\n' },
      });
      return linesToDelta(lines);

    case 'insert_after_line': {
      assertLine(edit.line, lines.length);
      lines.splice(edit.line, 0, {
        contentOps: edit.text ? [{ insert: edit.text }] : [],
        newlineOp: { insert: '\n' },
      });
      return linesToDelta(lines);
    }

    case 'replace_line': {
      assertLine(edit.line, lines.length);
      const target = lines[edit.line - 1];
      lines[edit.line - 1] = {
        contentOps: edit.text ? [{ insert: edit.text }] : [],
        // Preserve the block attributes (list/header) of the replaced line.
        newlineOp: target.newlineOp,
      };
      return linesToDelta(lines);
    }

    case 'delete_line': {
      assertLine(edit.line, lines.length);
      lines.splice(edit.line - 1, 1);
      return linesToDelta(lines);
    }

    case 'check_item': {
      assertLine(edit.line, lines.length);
      const target = lines[edit.line - 1];
      const attrs = target.newlineOp.attributes ?? {};
      if (attrs.list !== 'checked' && attrs.list !== 'unchecked') {
        throw new BadRequestException(
          `line ${edit.line} is not a checkbox item`,
        );
      }
      lines[edit.line - 1] = {
        ...target,
        newlineOp: {
          ...target.newlineOp,
          attributes: {
            ...attrs,
            list: edit.checked ? 'checked' : 'unchecked',
          },
        },
      };
      return linesToDelta(lines);
    }
  }
}
