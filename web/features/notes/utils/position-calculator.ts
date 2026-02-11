const POSITION_GAP = 1000;

export function calculateNewPositions(
  items: Array<{ id: string }>,
  fromIndex: number,
  toIndex: number,
): Array<{ id: string; position: number }> {
  // Create a new array with the item moved
  const reordered = [...items];
  const [moved] = reordered.splice(fromIndex, 1);
  reordered.splice(toIndex, 0, moved);

  // Assign positions with gap intervals
  return reordered.map((item, index) => ({
    id: item.id,
    position: (index + 1) * POSITION_GAP,
  }));
}
