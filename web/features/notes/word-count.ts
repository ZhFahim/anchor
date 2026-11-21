const EAST_ASIAN = /[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}]/gu;
const WORD = /\S*[\p{L}\p{N}]\S*/gu;

/** Spaced runs that hold a letter or number, and each Chinese or Japanese character on its own. */
export function countWords(text: string): number {
  const eastAsian = text.match(EAST_ASIAN)?.length ?? 0;
  return eastAsian + (text.replace(EAST_ASIAN, " ").match(WORD)?.length ?? 0);
}
