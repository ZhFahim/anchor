import {
  FilenameAllocator,
  encodeRelativePath,
  sanitizeFilenameStem,
} from './note-filename';

describe('sanitizeFilenameStem', () => {
  it.each([
    ['a/b: c?', 'a b c'],
    ['  spaced   out  ', 'spaced out'],
    ['.hidden', 'hidden'],
    ['trailing...', 'trailing'],
    ['', 'Untitled'],
    ['   ', 'Untitled'],
    ['///', 'Untitled'],
  ])('turns %j into %j', (input, expected) => {
    expect(sanitizeFilenameStem(input)).toBe(expected);
  });

  it('sidesteps Windows reserved names', () => {
    expect(sanitizeFilenameStem('CON')).toBe('CON note');
    expect(sanitizeFilenameStem('lpt1')).toBe('lpt1 note');
    expect(sanitizeFilenameStem('console')).toBe('console');
  });

  it('caps the length without splitting surrogate pairs', () => {
    expect(sanitizeFilenameStem('a'.repeat(200))).toHaveLength(100);
    const emoji = sanitizeFilenameStem('\u{1F600}'.repeat(120));
    expect(Array.from(emoji)).toHaveLength(100);
  });
});

describe('FilenameAllocator', () => {
  it('adds a counter for repeated names in the same folder', () => {
    const allocator = new FilenameAllocator();
    expect(allocator.allocate('', 'Groceries')).toBe('Groceries');
    expect(allocator.allocate('', 'Groceries')).toBe('Groceries (2)');
    expect(allocator.allocate('', 'Groceries')).toBe('Groceries (3)');
  });

  it('treats names that differ only by case as taken', () => {
    const allocator = new FilenameAllocator();
    allocator.allocate('', 'Note');
    expect(allocator.allocate('', 'note')).toBe('note (2)');
  });

  it('tracks folders independently', () => {
    const allocator = new FilenameAllocator();
    allocator.allocate('', 'Note');
    expect(allocator.allocate('Archived/', 'Note')).toBe('Note');
  });
});

describe('encodeRelativePath', () => {
  it('encodes characters that would break a link target', () => {
    expect(encodeRelativePath('attachments/My note/a b(1).png')).toBe(
      'attachments/My%20note/a%20b%281%29.png',
    );
  });

  it('keeps ordinary paths readable', () => {
    expect(encodeRelativePath('attachments/note/img.png')).toBe(
      'attachments/note/img.png',
    );
  });
});
