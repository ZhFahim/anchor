import { QuillOp } from '../delta-lines';

/**
 * Notes in both representations, in the shape the exporter writes. Mirrors
 * web/features/import-export/adapters/fixtures/markdown-roundtrip.ts.
 */
export type RoundTripCase = {
  name: string;
  ops: QuillOp[];
  markdown: string;
};

const md = (...lines: string[]) => `${lines.join('\n')}\n`;

export const roundTripCases: RoundTripCase[] = [
  {
    name: 'headings and paragraphs',
    ops: [
      { insert: 'Title' },
      { insert: '\n', attributes: { header: 1 } },
      { insert: 'Intro line' },
      { insert: '\n' },
      { insert: '\n' },
      { insert: 'Section' },
      { insert: '\n', attributes: { header: 2 } },
      { insert: 'Body' },
      { insert: '\n' },
    ],
    markdown: md('# Title', 'Intro line', '', '## Section', 'Body'),
  },
  {
    name: 'inline marks',
    ops: [
      { insert: 'plain ' },
      { insert: 'bold', attributes: { bold: true } },
      { insert: ' ' },
      { insert: 'italic', attributes: { italic: true } },
      { insert: ' ' },
      { insert: 'both', attributes: { bold: true, italic: true } },
      { insert: ' ' },
      { insert: 'struck', attributes: { strike: true } },
      { insert: ' ' },
      { insert: 'under', attributes: { underline: true } },
      { insert: ' ' },
      { insert: 'site', attributes: { link: 'https://example.com' } },
      { insert: '\n' },
    ],
    markdown: md(
      'plain **bold** *italic* ***both*** ~~struck~~ <u>under</u> [site](https://example.com)',
    ),
  },
  {
    name: 'nested lists and checklists',
    ops: [
      { insert: 'one' },
      { insert: '\n', attributes: { list: 'bullet' } },
      { insert: 'nested' },
      { insert: '\n', attributes: { list: 'bullet', indent: 1 } },
      { insert: 'deep' },
      { insert: '\n', attributes: { list: 'bullet', indent: 2 } },
      { insert: 'first' },
      { insert: '\n', attributes: { list: 'ordered' } },
      { insert: 'second' },
      { insert: '\n', attributes: { list: 'ordered' } },
      { insert: 'todo' },
      { insert: '\n', attributes: { list: 'unchecked' } },
      { insert: 'done' },
      { insert: '\n', attributes: { list: 'checked' } },
    ],
    markdown: md(
      '- one',
      '    - nested',
      '        - deep',
      '1. first',
      '2. second',
      '- [ ] todo',
      '- [x] done',
    ),
  },
  {
    name: 'blockquote and code block',
    ops: [
      { insert: 'Note this' },
      { insert: '\n', attributes: { blockquote: true } },
      { insert: 'const x = 1;' },
      { insert: '\n', attributes: { 'code-block': true } },
      { insert: 'return x;' },
      { insert: '\n', attributes: { 'code-block': true } },
      { insert: 'after' },
      { insert: '\n' },
    ],
    markdown: md(
      '> Note this',
      '```',
      'const x = 1;',
      'return x;',
      '```',
      'after',
    ),
  },
  {
    name: 'escaped markdown characters',
    ops: [
      { insert: '2 * 3 = 6' },
      { insert: '\n' },
      { insert: '# not a heading' },
      { insert: '\n' },
      { insert: '- not a bullet' },
      { insert: '\n' },
      { insert: 'snake_case_name stays' },
      { insert: '\n' },
    ],
    markdown: md(
      '2 \\* 3 = 6',
      '\\# not a heading',
      '\\- not a bullet',
      'snake_case_name stays',
    ),
  },
];
