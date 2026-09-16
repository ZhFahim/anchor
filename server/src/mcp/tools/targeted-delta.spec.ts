import { applyTargetedEdit, validateDelta } from './targeted-delta';
import {
  deltaToLines,
  getLineText,
  parseDeltaOps,
} from '../../import-export/markdown/delta-lines';

const delta = (lines: string[]) =>
  JSON.stringify({ ops: lines.map((l) => ({ insert: `${l}\n` })) });

/** Read the line texts back via the production line reader. */
const linesOf = (content: string) =>
  deltaToLines(parseDeltaOps(content) ?? []).map((l) => getLineText(l));

describe('validateDelta', () => {
  it('accepts canonical Quill Delta JSON', () => {
    expect(() => validateDelta('{"ops":[{"insert":"hi\\n"}]}')).not.toThrow();
  });
  it('rejects non-JSON, objects without ops, and non-array ops', () => {
    expect(() => validateDelta('not json')).toThrow();
    expect(() => validateDelta('{"text":"hi"}')).toThrow();
    expect(() => validateDelta('{"ops":"nope"}')).toThrow();
  });
});

describe('applyTargetedEdit (P2: server owns the mutation)', () => {
  it('append_line adds a line at the end', () => {
    const out = applyTargetedEdit(delta(['one', 'two']), {
      op: 'append_line',
      text: 'three',
    });
    expect(linesOf(out)).toEqual(['one', 'two', 'three']);
  });

  it('insert_after_line inserts at a 1-based position', () => {
    const out = applyTargetedEdit(delta(['one', 'two']), {
      op: 'insert_after_line',
      line: 1,
      text: 'middle',
    });
    expect(linesOf(out)).toEqual(['one', 'middle', 'two']);
  });

  it('replace_line swaps a line by number', () => {
    const out = applyTargetedEdit(delta(['one', 'two']), {
      op: 'replace_line',
      line: 2,
      text: 'TWO',
    });
    expect(linesOf(out)).toEqual(['one', 'TWO']);
  });

  it('delete_line removes a line by number', () => {
    const out = applyTargetedEdit(delta(['one', 'two', 'three']), {
      op: 'delete_line',
      line: 2,
    });
    expect(linesOf(out)).toEqual(['one', 'three']);
  });

  it('rejects an out-of-range line number', () => {
    expect(() =>
      applyTargetedEdit(delta(['one']), { op: 'delete_line', line: 9 }),
    ).toThrow();
  });

  it('check_item flips the checkbox list attribute on the newline op', () => {
    const content = JSON.stringify({
      ops: [{ insert: 'todo\n', attributes: { list: 'unchecked' } }],
    });
    const out = applyTargetedEdit(content, {
      op: 'check_item',
      line: 1,
      checked: true,
    });
    const ops = (JSON.parse(out) as { ops: unknown[] }).ops as Array<{
      insert: string;
      attributes?: { list?: string };
    }>;
    const newline = ops.find((o) => o.insert === '\n');
    expect(newline?.attributes?.list).toBe('checked');
  });

  it('rejects check_item on a non-checkbox line', () => {
    expect(() =>
      applyTargetedEdit(delta(['plain']), {
        op: 'check_item',
        line: 1,
        checked: true,
      }),
    ).toThrow();
  });

  it('leaves non-targeted lines byte-for-byte intact', () => {
    const out = applyTargetedEdit(delta(['keep', 'change']), {
      op: 'replace_line',
      line: 2,
      text: 'new',
    });
    expect(linesOf(out)).toEqual(['keep', 'new']);
    // The untouched line's content op is unchanged.
    expect((JSON.parse(out) as { ops: unknown[] }).ops[0]).toEqual({
      insert: 'keep',
    });
  });
});
