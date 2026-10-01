import { describe, expect, it } from 'vitest';
import {
  deltaToMarkdown,
  escapeInlineText,
  escapeLineStart,
  renderInline,
} from './delta-to-markdown';
import { roundTripCases } from './__fixtures__/roundtrip';

describe('escapeInlineText', () => {
  it('escapes formatting characters', () => {
    expect(escapeInlineText('a * b ` c \\ d')).toBe('a \\* b \\` c \\\\ d');
    expect(escapeInlineText('a ~~b~~')).toBe('a \\~\\~b\\~\\~');
  });

  it('escapes the equals signs that could form a highlight', () => {
    expect(escapeInlineText('a == b')).toBe('a \\=\\= b');
    expect(escapeInlineText('x===y')).toBe('x\\=\\=\\=y');
    expect(escapeInlineText('=a=')).toBe('\\=a\\=');
    expect(escapeInlineText('a = b')).toBe('a = b');
  });

  it('escapes what could start an HTML tag', () => {
    expect(escapeInlineText('<mark>x</mark>')).toBe('\\<mark>x\\</mark>');
    expect(escapeInlineText('a < b <3')).toBe('a < b <3');
  });

  it('leaves intraword underscores alone', () => {
    expect(escapeInlineText('snake_case_name')).toBe('snake_case_name');
    expect(escapeInlineText('_leading')).toBe('\\_leading');
  });
});

describe('escapeLineStart', () => {
  it.each([
    ['# heading', '\\# heading'],
    ['- bullet', '\\- bullet'],
    ['+ plus', '\\+ plus'],
    ['1. item', '\\1. item'],
    ['2) item', '\\2) item'],
    ['> quote', '\\> quote'],
    ['---', '\\---'],
    ['===', '\\==='],
  ])('escapes %s', (input, expected) => {
    expect(escapeLineStart(input)).toBe(expected);
  });

  it('leaves ordinary text alone', () => {
    expect(escapeLineStart('hello - world')).toBe('hello - world');
    expect(escapeLineStart('2023 was fine')).toBe('2023 was fine');
  });
});

describe('renderInline', () => {
  it('merges adjacent ops that share formatting', () => {
    expect(
      renderInline([
        { insert: 'bo', attributes: { bold: true } },
        { insert: 'ld', attributes: { bold: true } },
      ]),
    ).toBe('**bold**');
  });

  it('moves edge whitespace outside the delimiters', () => {
    expect(
      renderInline([{ insert: 'bold ', attributes: { bold: true } }]),
    ).toBe('**bold** ');
  });

  it('nests marks with the link outermost', () => {
    expect(
      renderInline([
        {
          insert: 'x',
          attributes: {
            bold: true,
            italic: true,
            underline: true,
            strike: true,
            link: 'https://example.com',
          },
        },
      ]),
    ).toBe('[~~<u>***x***</u>~~](https://example.com)');
  });

  it('writes a yellow highlight as ==text== and other colors as <mark>', () => {
    expect(
      renderInline([
        { insert: 'a', attributes: { highlight: 'yellow' } },
        { insert: ' ' },
        { insert: 'b', attributes: { highlight: 'green' } },
      ]),
    ).toBe('==a== <mark data-color="green">b</mark>');
  });

  it('writes an unknown highlight color as yellow', () => {
    expect(
      renderInline([{ insert: 'a', attributes: { highlight: 'orange' } }]),
    ).toBe('==a==');
  });

  it('wraps a highlight around the other marks and links', () => {
    expect(
      renderInline([
        {
          insert: 'x',
          attributes: {
            bold: true,
            italic: true,
            strike: true,
            highlight: 'pink',
            link: 'https://example.com',
          },
        },
      ]),
    ).toBe('<mark data-color="pink">[~~***x***~~](https://example.com)</mark>');
  });

  it('keeps one highlighted phrase in one piece', () => {
    expect(
      renderInline([
        { insert: ' buy ', attributes: { highlight: 'yellow' } },
        { insert: 'milk', attributes: { highlight: 'yellow', bold: true } },
        { insert: ' today ', attributes: { highlight: 'yellow' } },
        { insert: 'please' },
      ]),
    ).toBe(' ==buy **milk** today== please');
  });

  it('escapes an equals sign next to a highlight', () => {
    expect(
      renderInline([
        { insert: 'x=' },
        { insert: 'y', attributes: { highlight: 'yellow' } },
      ]),
    ).toBe('x\\===y==');
  });

  it('wraps link targets containing spaces in angle brackets', () => {
    expect(
      renderInline([
        { insert: 'x', attributes: { link: 'https://example.com/a b' } },
      ]),
    ).toBe('[x](<https://example.com/a b>)');
  });

  it('skips embeds', () => {
    expect(renderInline([{ insert: { image: 'x' } }, { insert: 'ok' }])).toBe(
      'ok',
    );
  });
});

describe('deltaToMarkdown', () => {
  it('returns an empty string for blank content', () => {
    expect(deltaToMarkdown([{ insert: '\n' }])).toBe('');
    expect(deltaToMarkdown([])).toBe('');
  });

  it('clamps headings deeper than three', () => {
    expect(
      deltaToMarkdown([
        { insert: 'deep' },
        { insert: '\n', attributes: { header: 5 } },
      ]),
    ).toBe('### deep\n');
  });

  it('renumbers ordered runs per nesting level', () => {
    const markdown = deltaToMarkdown([
      { insert: 'a' },
      { insert: '\n', attributes: { list: 'ordered' } },
      { insert: 'a1' },
      { insert: '\n', attributes: { list: 'ordered', indent: 1 } },
      { insert: 'a2' },
      { insert: '\n', attributes: { list: 'ordered', indent: 1 } },
      { insert: 'b' },
      { insert: '\n', attributes: { list: 'ordered' } },
      { insert: 'b1' },
      { insert: '\n', attributes: { list: 'ordered', indent: 1 } },
    ]);
    expect(markdown).toBe(
      ['1. a', '    1. a1', '    2. a2', '2. b', '    1. b1', ''].join('\n'),
    );
  });

  it('restarts numbering after a plain line', () => {
    const markdown = deltaToMarkdown([
      { insert: 'a' },
      { insert: '\n', attributes: { list: 'ordered' } },
      { insert: 'text' },
      { insert: '\n' },
      { insert: 'b' },
      { insert: '\n', attributes: { list: 'ordered' } },
    ]);
    expect(markdown).toBe(['1. a', 'text', '1. b', ''].join('\n'));
  });

  it('joins consecutive code lines into one fence', () => {
    const markdown = deltaToMarkdown([
      { insert: 'a' },
      { insert: '\n', attributes: { 'code-block': 'javascript' } },
      { insert: 'b' },
      { insert: '\n', attributes: { 'code-block': 'javascript' } },
    ]);
    expect(markdown).toBe(['```', 'a', 'b', '```', ''].join('\n'));
  });

  it('lengthens the fence when the code contains backticks', () => {
    const markdown = deltaToMarkdown([
      { insert: 'run ```cmd```' },
      { insert: '\n', attributes: { 'code-block': true } },
    ]);
    expect(markdown).toBe(['````', 'run ```cmd```', '````', ''].join('\n'));
  });

  it('does not escape inside code blocks', () => {
    const markdown = deltaToMarkdown([
      { insert: 'const a = b * c;' },
      { insert: '\n', attributes: { 'code-block': true } },
    ]);
    expect(markdown).toContain('const a = b * c;');
  });

  it('drops trailing blank lines', () => {
    expect(
      deltaToMarkdown([
        { insert: 'text' },
        { insert: '\n' },
        { insert: '\n' },
        { insert: '\n' },
      ]),
    ).toBe('text\n');
  });

  it.each(roundTripCases)('renders the $name fixture', ({ ops, markdown }) => {
    expect(deltaToMarkdown(ops)).toBe(markdown);
  });
});
