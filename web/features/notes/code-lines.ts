/** Matches `tab-size` in the code block styles. */
export const CODE_TAB_SIZE = 4;

export function codeIndentColumns(line: string): number {
  let columns = 0;
  for (const char of line) {
    if (char === " ") columns += 1;
    else if (char === "\t")
      columns += CODE_TAB_SIZE - (columns % CODE_TAB_SIZE);
    else break;
  }
  return columns;
}

export function splitCodeLines<T extends { text: string }>(parts: T[]): T[][] {
  const lines: T[][] = [[]];
  for (const part of parts) {
    part.text.split("\n").forEach((text, i) => {
      if (i > 0) lines.push([]);
      if (text) lines[lines.length - 1].push({ ...part, text });
    });
  }
  return lines;
}
