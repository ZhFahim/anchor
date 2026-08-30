import {
  deltaToLines,
  getLineText,
  indentOf,
  parseDeltaOps,
} from './delta-lines';

describe('parseDeltaOps', () => {
  it('returns the ops of canonical delta content', () => {
    expect(parseDeltaOps('{"ops":[{"insert":"hi\\n"}]}')).toEqual([
      { insert: 'hi\n' },
    ]);
  });

  it('returns null for empty, invalid or non-delta content', () => {
    expect(parseDeltaOps(null)).toBeNull();
    expect(parseDeltaOps('')).toBeNull();
    expect(parseDeltaOps('not json')).toBeNull();
    expect(parseDeltaOps('{"text":"hi"}')).toBeNull();
  });
});

describe('deltaToLines', () => {
  it('splits multi-line inserts and keeps block attributes on the newline', () => {
    const lines = deltaToLines([
      { insert: 'one\ntwo' },
      { insert: '\n', attributes: { list: 'bullet' } },
    ]);

    expect(lines).toHaveLength(2);
    expect(getLineText(lines[0])).toBe('one');
    expect(lines[0].newlineOp.attributes).toBeUndefined();
    expect(getLineText(lines[1])).toBe('two');
    expect(lines[1].newlineOp.attributes).toEqual({ list: 'bullet' });
  });

  it('keeps inline attributes on content ops', () => {
    const lines = deltaToLines([
      { insert: 'bold', attributes: { bold: true } },
      { insert: '\n' },
    ]);
    expect(lines[0].contentOps[0].attributes).toEqual({ bold: true });
  });

  it('closes trailing content that has no newline', () => {
    const lines = deltaToLines([{ insert: 'dangling' }]);
    expect(lines).toHaveLength(1);
    expect(getLineText(lines[0])).toBe('dangling');
  });

  it('reads the indent level, defaulting to zero', () => {
    const [nested, flat] = deltaToLines([
      { insert: 'a' },
      { insert: '\n', attributes: { list: 'bullet', indent: 2 } },
      { insert: 'b' },
      { insert: '\n', attributes: { list: 'bullet' } },
    ]);
    expect(indentOf(nested)).toBe(2);
    expect(indentOf(flat)).toBe(0);
  });
});
