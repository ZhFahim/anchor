export interface SlashSearchItem {
  label: string;
  keywords: string;
  isPopular?: boolean;
}

export function findSlashItems<T extends SlashSearchItem>(
  items: T[],
  query: string,
): T[] {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (!words.length) return items.filter((item) => item.isPopular);
  const joined = words.join("");
  const ranked = items.flatMap((item, order) => {
    const label = item.label.toLowerCase();
    const labelWords = label.split(" ");
    const allWords = [...labelWords, ...item.keywords.toLowerCase().split(" ")];
    const startsSome = (list: string[]) =>
      words.every((word) => list.some((other) => other.startsWith(word)));
    const rank = label.replaceAll(" ", "").startsWith(joined)
      ? 0
      : startsSome(labelWords)
        ? 1
        : startsSome(allWords)
          ? 2
          : -1;
    return rank < 0 ? [] : [{ item, rank, order }];
  });
  return ranked
    .sort((a, b) => a.rank - b.rank || a.order - b.order)
    .map(({ item }) => item);
}
